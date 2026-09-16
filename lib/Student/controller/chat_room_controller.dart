import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:al_maqraa/Admin/models/admin_models.dart';
import 'package:al_maqraa/core/services/chat_cache_service.dart';
import 'package:al_maqraa/core/controllers/notification_controller.dart';

/// المتحكم الرئيسي لغرفة المحادثة الخاصة مع المنسق / الإدارة
/// يدعم المراسلة النصية التبادلية الكاملة، وقوالب الطلبات الجاهزة، والتحديث اللحظي عبر Supabase مع دعم Cache-First فائق السرعة
class ChatRoomController extends GetxController {
  final String otherUserId;
  final String? chatType;
  final List<MessageModel>? forwardedMessages;

  ChatRoomController({
    required this.otherUserId,
    this.chatType,
    this.forwardedMessages,
  });

  final SupabaseClient supabase = Supabase.instance.client;
  final GetStorage _storage = GetStorage();

  // حالة الرسائل والتحميل
  final messages = <MessageModel>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;

  // معرف المحادثة
  String? currentChatId;
  final _chatIdCompleter = Completer<String>();
  Future<String> get chatIdFuture => _chatIdCompleter.future;

  // اشتراكات Realtime
  RealtimeChannel? _messagesSubscription;
  StreamSubscription? _otherUserSubscription;

  // وحدات التحكم بالواجهة
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final focusNode = FocusNode();
  final hasText = false.obs;

  // بيانات المستخدمين
  final userRole = ''.obs;
  final otherUserNameRx = ''.obs;
  final otherUserAvatarRx = ''.obs;
  final otherUserRoleRx = ''.obs;
  final otherUserBackgroundRx = ''.obs;

  // وضع التحديد والحذف
  final isSelectionMode = false.obs;
  final selectedMessageIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    messageController.addListener(() {
      hasText.value = messageController.text.trim().isNotEmpty;
    });

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId != null) {
      userRole.value = _storage.read('user_role_$currentUserId') ?? '';
    }
    _loadCachedMessagesFirst(); // عرض فوري للرسائل المخزنة محلياً بدون تأخير 0ms
    _fetchUserRole();
    _initOtherUserListener();
  }

  @override
  void onReady() {
    super.onReady();
    initChat();
  }

  @override
  void onClose() {
    _messagesSubscription?.unsubscribe();
    _otherUserSubscription?.cancel();
    messageController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  /// تحميل فوري للرسائل المخزنة محلياً (Cache-First)
  Future<void> _loadCachedMessagesFirst() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final cachedChatId = _storage.read('last_chat_id_${currentUserId}_$otherUserId');
      if (cachedChatId != null && cachedChatId.toString().isNotEmpty) {
        currentChatId = cachedChatId.toString();
        if (!_chatIdCompleter.isCompleted) {
          _chatIdCompleter.complete(currentChatId!);
        }
      }

      if (Get.isRegistered<ChatCacheService>() && currentChatId != null) {
        final cached = await Get.find<ChatCacheService>().getCachedMessages(currentChatId!);
        if (cached.isNotEmpty) {
          messages.assignAll(cached);
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached messages: $e');
    }
  }

  /// جلب دور المستخدم الحالي
  Future<void> _fetchUserRole() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    try {
      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUserId)
          .maybeSingle();
      if (response != null && response['role'] != null) {
        userRole.value = response['role'];
        _storage.write('user_role_$currentUserId', userRole.value);
      }
    } catch (_) {}
  }

  /// مراقبة بيانات الطرف الآخر (المنسق / الإدارة / المستخدم)
  void _initOtherUserListener() {
    _otherUserSubscription?.cancel();
    _otherUserSubscription = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', otherUserId)
        .listen((data) {
          if (data.isNotEmpty) {
            final profile = data.first;
            otherUserNameRx.value = profile['full_name'] ?? '';
            otherUserRoleRx.value = profile['role'] ?? '';
            otherUserBackgroundRx.value = profile['background_url'] ?? '';
            final avatar = profile['avatar_url'];
            if (avatar != null && avatar.toString().isNotEmpty) {
              otherUserAvatarRx.value = avatar.toString();
            } else {
              otherUserAvatarRx.value = '';
            }
          }
        });
  }

  /// تهيئة المحادثة وجلب الرسائل
  Future<void> initChat() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    if (messages.isEmpty) {
      isLoading.value = true;
    }
    try {
      // 1. البحث عن محادثة سابقة بغض النظر عن ترتيب student/teacher
      final existingChat = await supabase
          .from('chats')
          .select('id')
          .or(
            'and(student_id.eq.$currentUserId,teacher_id.eq.$otherUserId),and(student_id.eq.$otherUserId,teacher_id.eq.$currentUserId)',
          )
          .maybeSingle();

      if (existingChat != null) {
        currentChatId = existingChat['id'].toString();
        _storage.write('last_chat_id_${currentUserId}_$otherUserId', currentChatId);
      } else {
        // إنشاء محادثة جديدة - المعلم/منسق/مدير في teacher_id والطالب في student_id
        final isTeacherRole = ['teacher', 'coordinator', 'admin', 'examiner']
            .contains(userRole.value);
        final newChat = await supabase
            .from('chats')
            .insert({
              'student_id': isTeacherRole ? otherUserId : currentUserId,
              'teacher_id': isTeacherRole ? currentUserId : otherUserId,
              'type': chatType ?? 'private',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();
        currentChatId = newChat['id'].toString();
        _storage.write('last_chat_id_${currentUserId}_$otherUserId', currentChatId);
      }

      if (currentChatId != null && !_chatIdCompleter.isCompleted) {
        _chatIdCompleter.complete(currentChatId!);
      }

      // 2. تحميل الرسائل
      await _loadMessages();

      // 3. تفعيل الاستماع اللحظي للرسائل الجديدة
      _subscribeToRealtime();
    } catch (e) {
      debugPrint('Error in initChat: $e');
      // محاولة إعادة البحث عن الشات في حال فشل الإنشاء (تجنب currentChatId = null)
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        final retryChat = await supabase
            .from('chats')
            .select('id')
            .or(
              'and(student_id.eq.$currentUserId,teacher_id.eq.$otherUserId),and(student_id.eq.$otherUserId,teacher_id.eq.$currentUserId)',
            )
            .maybeSingle();
        if (retryChat != null) {
          currentChatId = retryChat['id'].toString();
          if (!_chatIdCompleter.isCompleted) {
            _chatIdCompleter.complete(currentChatId!);
          }
          await _loadMessages();
          _subscribeToRealtime();
        }
      } catch (_) {}
    } finally {
      isLoading.value = false;
    }
  }

  /// تحميل سجل الرسائل النصية
  Future<void> _loadMessages() async {
    if (currentChatId == null) return;
    try {
      final response = await supabase
          .from('messages')
          .select('*, sender:sender_id(full_name)')
          .eq('chat_id', currentChatId!)
          .order('created_at', ascending: true);

      final loadedList = (response as List)
          .map((m) => MessageModel.fromJson(m))
          .toList();

      messages.assignAll(loadedList);
      _saveToCacheIfAvailable(loadedList);
      _scrollToBottom();
      markMessagesAsRead();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  /// تعيين الرسائل غير المقروءة كمقروءة وتصفير عداد الرسائل
  Future<void> markMessagesAsRead() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null || currentChatId == null) return;

    try {
      // 1. تحديث الرسائل في قاعدة بيانات Supabase
      await supabase
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('chat_id', currentChatId!)
          .neq('sender_id', currentUserId)
          .filter('read_at', 'is', null);

      // 2. تحديث الكاش المحلي
      if (Get.isRegistered<ChatCacheService>()) {
        await Get.find<ChatCacheService>().markMessagesAsRead(currentChatId!);
      }

      // 3. تصفير وتحديث عداد الرسائل في NotificationController
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().updateUnreadCount();
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// الاشتراك في التحديثات اللحظية عبر Supabase Realtime
  void _subscribeToRealtime() {
    if (currentChatId == null) return;
    _messagesSubscription?.unsubscribe();

    _messagesSubscription = supabase
        .channel('chat_room_$currentChatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: currentChatId!,
          ),
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.insert) {
              final newMsgData = payload.newRecord;
              final newMsg = MessageModel.fromJson(newMsgData);
              final exists = messages.any((m) => m.id == newMsg.id);
              if (!exists) {
                messages.add(newMsg);
                _saveToCacheIfAvailable([newMsg]);
                _scrollToBottom();
                if (newMsg.senderId != supabase.auth.currentUser?.id) {
                  markMessagesAsRead();
                }
              }
            } else if (payload.eventType == PostgresChangeEvent.delete) {
              final oldId = payload.oldRecord['id']?.toString();
              if (oldId != null) {
                messages.removeWhere((m) => m.id == oldId);
              }
            }
          },
        )
        .subscribe();
  }

  /// إرسال رسالة نصية جديدة
  Future<void> sendTextMessage([String? customText]) async {
    final textToSend = customText ?? messageController.text.trim();
    if (textToSend.isEmpty) return;

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    if (!isSending.value) {
      messageController.clear();
      hasText.value = false;
    }

    isSending.value = true;
    try {
      final chatId = currentChatId ?? await chatIdFuture;

      final Map<String, dynamic> insertData = {
        'chat_id': chatId,
        'sender_id': currentUserId,
        'receiver_id': otherUserId,
        'text': textToSend,
        'chat_type': chatType ?? 'private',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('messages')
          .insert(insertData)
          .select('*, sender:sender_id(full_name)')
          .single();

      final newMsg = MessageModel.fromJson(response);
      final exists = messages.any((m) => m.id == newMsg.id);
      if (!exists) {
        messages.add(newMsg);
        _saveToCacheIfAvailable([newMsg]);
      }

      await supabase
          .from('chats')
          .update({
            'last_message': textToSend,
            'last_sender_id': currentUserId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      Get.snackbar(
        'error'.tr,
        'فشل إرسال الرسالة، يرجى المحاولة مرة أخرى',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSending.value = false;
    }
  }

  /// تطبيق قالب جاهز في حقل النص
  void applyTemplate(String templateText) {
    messageController.text = templateText;
    messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: messageController.text.length),
    );
    hasText.value = true;
    focusNode.requestFocus();
  }

  /// حذف رسالة من المحادثة
  Future<void> deleteMessage(String messageId) async {
    try {
      await supabase.from('messages').delete().eq('id', messageId);
      messages.removeWhere((m) => m.id == messageId);
      if (Get.isRegistered<ChatCacheService>()) {
        await Get.find<ChatCacheService>().deleteMessageLocal(messageId);
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  /// تفعيل أو تعطيل وضع التحديد المتعدد
  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedMessageIds.clear();
    }
  }

  /// تحديد أو إلغاء تحديد رسالة معينة
  void toggleMessageSelection(String messageId) {
    if (selectedMessageIds.contains(messageId)) {
      selectedMessageIds.remove(messageId);
      if (selectedMessageIds.isEmpty) {
        isSelectionMode.value = false;
      }
    } else {
      selectedMessageIds.add(messageId);
    }
  }

  /// حذف الرسائل المحددة
  Future<void> deleteSelectedMessages() async {
    final idsToDelete = selectedMessageIds.toList();
    for (final id in idsToDelete) {
      await deleteMessage(id);
    }
    selectedMessageIds.clear();
    isSelectionMode.value = false;
  }

  /// منح استئذان رسمي فوري وسريع جداً للطالب وتحديث السجلات محلياً وسحابياً
  Future<bool> grantStudentLeave({
    DateTime? singleDate,
    DateTimeRange? dateRange,
    String? notes,
    bool sendConfirmationMessage = true,
  }) async {
    try {
      final noteText = (notes != null && notes.trim().isNotEmpty) ? notes.trim() : 'استئذان بعذر رسمي';
      final List<DateTime> datesToProcess = [];

      if (dateRange != null) {
        DateTime current = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
        final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);
        while (!current.isAfter(end)) {
          datesToProcess.add(current);
          current = current.add(const Duration(days: 1));
        }
      } else if (singleDate != null) {
        datesToProcess.add(DateTime(singleDate.year, singleDate.month, singleDate.day));
      } else {
        datesToProcess.add(DateTime.now());
      }

      // 1. تجهيز كافة السجلات للإدراج/التحديث بدفعة واحدة
      final records = datesToProcess.map((d) {
        final dateStr = DateFormat('yyyy-MM-dd').format(d);
        return {
          'student_id': otherUserId,
          'date': dateStr,
          'attendance_status': 'excused',
          'teacher_notes': noteText,
          'status': 'excused',
        };
      }).toList();

      // 2. تنفيذ الحفظ السحابي الفوري في طلب واحد مجمّع (Single Batch Upsert)
      await supabase.from('daily_records').upsert(records, onConflict: 'student_id, date');

      // 3. تفريغ الكاش فوراً لتنعكس التحديثات في شاشات الطلاب والمتابعة
      try {
        final storage = GetStorage();
        storage.remove('student_daily_records_$otherUserId');
        storage.remove('student_details_full_$otherUserId');
      } catch (_) {}

      // 4. تنفيذ مزامنة الشهور وإرسال رسالة التوثيق في الخلفية بدون تأخير استجابة الواجهة
      unawaited(() async {
        try {
          final Set<String> affectedMonths = {};
          for (final d in datesToProcess) {
            affectedMonths.add('${d.year}-${d.month}');
          }
          for (final ym in affectedMonths) {
            final parts = ym.split('-');
            await _syncMonthlyAttendance(otherUserId, int.parse(parts[0]), int.parse(parts[1]));
          }

          if (sendConfirmationMessage) {
            if (datesToProcess.length == 1) {
              final formattedDate = DateFormat('yyyy/MM/dd').format(datesToProcess.first);
              await sendTextMessage('📋 تم منحك استئذان رسمي ليوم $formattedDate');
            } else {
              final fromStr = DateFormat('yyyy/MM/dd').format(datesToProcess.first);
              final toStr = DateFormat('yyyy/MM/dd').format(datesToProcess.last);
              await sendTextMessage('📋 تم منحك استئذان رسمي للفترة من $fromStr إلى $toStr (${datesToProcess.length} أيام)');
            }
          }
        } catch (bgErr) {
          debugPrint('Background task warning: $bgErr');
        }
      }());

      return true;
    } catch (e) {
      debugPrint('Error granting student leave: $e');
      return false;
    }
  }

  /// إعادة حساب ومزامنة إحصائيات الشهر للطالب
  Future<void> _syncMonthlyAttendance(String studentId, int year, int month) async {
    try {
      final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
      final lastDay = DateTime(year, month + 1, 0).day;
      final endDate = '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

      final dailyRecordsRes = await supabase
          .from('daily_records')
          .select('attendance_status')
          .eq('student_id', studentId)
          .gte('date', startDate)
          .lte('date', endDate);

      int present = 0, absent = 0, excused = 0;
      for (var rec in (dailyRecordsRes as List)) {
        final status = rec['attendance_status']?.toString() ?? 'present';
        if (status == 'ح' || status == 'present') {
          present++;
        } else if (status == 'غ' || status == 'absent') {
          absent++;
        } else if (status == 'م' || status == 'excused') {
          excused++;
        }
      }

      final existing = await supabase
          .from('monthly_records')
          .select()
          .eq('student_id', studentId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      await supabase.from('monthly_records').upsert({
        'student_id': studentId,
        'year': year,
        'month': month,
        'attendance_days': present,
        'absence_days': absent,
        'excused_days': excused,
        'monthly_grade': existing?['monthly_grade'] ?? 0,
        'hifz_score': existing?['hifz_score'] ?? 0,
        'tajweed_score': existing?['tajweed_score'] ?? 0,
        'tilawah_score': existing?['tilawah_score'] ?? 0,
      }, onConflict: 'student_id, month, year');
    } catch (e) {
      debugPrint('Error syncing monthly totals: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _saveToCacheIfAvailable(List<MessageModel> msgs) {
    try {
      if (Get.isRegistered<ChatCacheService>()) {
        Get.find<ChatCacheService>().saveMessages(msgs);
      }
    } catch (_) {}
  }
}
