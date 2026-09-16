import 'dart:async'; // استيراد مكتبة العمليات المتزامنة للتعامل مع التدفقات الحية والمؤقتات.
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة، التنقل، والترجمة.
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد مكتبة Supabase للتعامل مع قاعدة البيانات السحابية وخدمات Realtime.
import '../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بجهة الإدارة (مثل ChatModel).
import '../repository/admin_repository.dart'; // استيراد الواجهة البرمجية لمستودع بيانات الإدارة.
import '../repository/supabase_admin_repository.dart'; // استيراد التنفيذ الفعلي لمستودع البيانات باستخدام Supabase.
import '../../../../core/services/chat_cache_service.dart'; // استيراد خدمة تخزين المحادثات مؤقتاً لتحسين الأداء وتصفح الأوفلاين.
import '../../../../core/services/notification_service.dart'; // استيراد خدمة الإشعارات لإظهار التنبيهات عند وصول رسائل جديدة.
import '../../../Student/controller/chat_room_controller.dart'; // استيراد متحكم غرفة الدردشة للتحقق من حالة الغرفة المفتوحة حالياً.
import '../../../../core/controllers/global_batch_controller.dart';

class AdminChatController extends GetxController {
  // فئة المتحكم لإدارة دردشات المنسق/الأدمن.

  final AdminRepository _repository =
      SupabaseAdminRepository(); // إنشاء نسخة من مستودع البيانات للقيام بالعمليات البرمجية.
  final ChatCacheService _chatCacheService =
      Get.find<
        ChatCacheService
      >(); // الوصول لخدمة التخزين المؤقت المسجلة مسبقاً.
  final _supabase = Supabase
      .instance
      .client; // الحصول على عميل Supabase لإجراء اتصالات مباشرة (مثل Realtime).

  var chats =
      <ChatModel>[].obs; // قائمة المحادثات المراقبة التي تظهر في الواجهة.
  var allUserProfiles = <ChatUserModel>[]
      .obs; // قائمة الملفات الشخصية لجميع المستخدمين لبدء محادثات جديدة.
  var currentMessages =
      <MessageModel>[].obs; // قائمة الرسائل داخل المحادثة المختارة حالياً.
  var isLoading = false.obs; // متغير لمراقبة حالة التحميل (بدء/انتهاء).
  var isSending = false.obs; // متغير لمراقبة حالة إرسال الرسالة الحالية.
  var searchQuery = "".obs; // متغير لتخزين نص البحث وتصفية قائمة المحادثات.
  var selectedGenderFilter =
      Gender.all.obs; // متغير لتخزين فلتر الجنس المختار (ذكر، أنثى، الكل).
  var hiddenChatIds =
      <String>[].obs; // قائمة معرفات المحادثات التي قام المستخدم بإخفائها.

  StreamSubscription<List<MessageModel>>?
  _messagesSubscription; // اشتراك في تدفق الرسائل لمراقبة التحديثات الحية.
  RealtimeChannel?
  _myMessagesSubscription; // قناة اتصال حية للاستماع للرسائل الموجهة للمستخدم الحالي.
  final Map<String, Timer> _deleteTimers =
      {}; // قاموس لتخزين مؤقتات حذف الرسائل التلقائي (في حال وجود ميزة الحذف المؤقت).

  @override
  void onInit() {
    // دالة التهيئة عند بدء عمل المتحكم.
    super.onInit(); // استدعاء دالة التهيئة في الفئة الأساسية.
    _loadHiddenChats(); // تحميل قائمة المحادثات المخفية من الذاكرة المحلية.
    fetchChats(); // جلب قائمة المحادثات من السيرفر أو التخزين المؤقت.
    fetchAllUserProfiles(); // جلب كافة المستخدمين لتمكين المنسق من بدء محادثة مع أي شخص.
    _listenToMyMessages(); // تفعيل الاستماع الحي للرسائل الجديدة.
  }

  @override
  void onClose() {
    // دالة التنظيف عند إغلاق المتحكم.
    _messagesSubscription
        ?.cancel(); // إلغاء اشتراك تدفق الرسائل لمنع تسرب الذاكرة.
    _myMessagesSubscription
        ?.unsubscribe(); // إلغاء الاشتراك في قناة الـ Realtime.
    _deleteTimers.forEach(
      (_, timer) => timer.cancel(),
    ); // إلغاء كافة المؤقتات النشطة.
    super.onClose(); // استدعاء دالة الإغلاق الأساسية.
  }

  void _loadHiddenChats() {
    // تحميل المحادثات المخفية إذا لزم الأمر
  }

  void showChat(String chatId) {
    if (hiddenChatIds.contains(chatId)) {
      hiddenChatIds.remove(chatId);
    }
  }

  /// دالة تحديث البيانات يدوياً (Pull to refresh).
  Future<void> refreshData() async {
    await fetchChats(); // إعادة جلب المحادثات.
    await fetchAllUserProfiles(); // إعادة جلب ملفات المستخدمين.
  }

  /// دالة حذف رسالة معينة من الجهاز والسيرفر.
  Future<void> deleteMessage(String messageId) async {
    try {
      if (_deleteTimers.containsKey(messageId)) {
        // إذا كان هناك مؤقت حذف نشط لهذه الرسالة، يتم إلغاؤه.
        _deleteTimers[messageId]?.cancel();
        _deleteTimers.remove(messageId);
      }
      currentMessages.removeWhere(
        (m) => m.id == messageId,
      ); // إزالة الرسالة من القائمة المعروضة فوراً.
      await _chatCacheService.deleteMessageLocal(
        messageId,
      ); // حذفها من التخزين المحلي.
      await _repository.deleteMessageFromServer(
        messageId,
      ); // طلب حذفها من قاعدة البيانات السحابية.
    } catch (e) {
      // debugPrint('Error deleting message: $e');
    }
  }

  // الحصول على عدد محادثات الطلاب التي تحتوي على رسائل غير مقروءة مع احترام الفلتر.
  int get unreadStudentMessages =>
      getFilteredChats('student').where((c) => c.unreadCount > 0).length;

  // الحصول على عدد محادثات المعلمين التي تحتوي على رسائل غير مقروءة مع احترام الفلتر.
  int get unreadTeacherMessages =>
      getFilteredChats('teacher').where((c) => c.unreadCount > 0).length;

  // استخراج قوائم المحادثات المفلترة حسب نوع المستخدم.
  List<ChatModel> get teacherChats =>
      chats.where((c) => c.userRole == 'teacher').toList();
  List<ChatModel> get studentChats =>
      chats.where((c) => c.userRole == 'student').toList();

  /// دالة تصفية المحادثات بناءً على الدور، الجنس، الدفعة، البحث، والحالة (مخفية أم لا).
  List<ChatModel> getFilteredChats(String? roleFilter) {
    if (isLoading.value && chats.isEmpty) return []; // إذا كان النظام يحمل ولا توجد بيانات، نرجع قائمة فارغة.

    int? batchFilter;
    Gender genderFilter = selectedGenderFilter.value;

    if (Get.isRegistered<GlobalBatchController>()) {
      final gb = Get.find<GlobalBatchController>();
      batchFilter = gb.selectedBatch.value;
      if (gb.selectedGender.value != Gender.all) {
        genderFilter = gb.selectedGender.value;
      }
    }

    var filtered = chats.where((c) {
      bool roleMatch =
          roleFilter == null ||
          c.userRole.toLowerCase() == roleFilter.toLowerCase();
      bool genderMatch = genderFilter == Gender.all || c.gender == genderFilter;
      bool batchMatch = batchFilter == null || c.batchNumber == batchFilter;
      bool searchMatch =
          searchQuery.value.isEmpty ||
          c.userName.toLowerCase().contains(searchQuery.value.toLowerCase());
      bool isNotHidden = !hiddenChatIds.contains(c.id) || c.unreadCount > 0;

      return roleMatch &&
          genderMatch &&
          batchMatch &&
          searchMatch &&
          isNotHidden;
    }).toList();

    filtered.sort((a, b) {
      if (a.unreadCount > 0 && b.unreadCount == 0) return -1;
      if (a.unreadCount == 0 && b.unreadCount > 0) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return filtered;
  }

  /// دالة تصفية قائمة المستخدمين لبدء محادثة بناءً على الدفعة والجنس
  List<ChatUserModel> getFilteredUserProfiles(String? roleFilter) {
    int? batchFilter;
    Gender genderFilter = selectedGenderFilter.value;

    if (Get.isRegistered<GlobalBatchController>()) {
      final gb = Get.find<GlobalBatchController>();
      batchFilter = gb.selectedBatch.value;
      if (gb.selectedGender.value != Gender.all) {
        genderFilter = gb.selectedGender.value;
      }
    }

    return allUserProfiles.where((u) {
      bool roleMatch =
          roleFilter == null ||
          u.role.toLowerCase() == roleFilter.toLowerCase();
      bool genderMatch = genderFilter == Gender.all || u.gender == genderFilter;
      bool batchMatch = batchFilter == null || u.batchNumber == batchFilter;
      return roleMatch && genderMatch && batchMatch;
    }).toList();
  }

  /// دالة لتصفير عداد الرسائل غير المقروءة لمحادثة معينة.
  Future<void> markAsRead(String chatId) async {
    int index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      chats[index] = chats[index].copyWith(
        unreadCount: 0,
      );
      chats.refresh();
    }
    try {
      await _repository.markMessagesAsRead(
        chatId,
      );
    } catch (e) {
      // debugPrint('Error marking messages as read: $e');
    }
  }

  /// دالة جلب كافة المحادثات.
  Future<void> fetchChats() async {
    isLoading.value = true;
    try {
      final cached = await _chatCacheService.getCachedChats();
      if (cached.isNotEmpty) chats.assignAll(cached);

      final result = await _repository.getChats();
      await _chatCacheService.saveChats(result);
      chats.assignAll(result);
    } catch (e) {
      // debugPrint('Error fetching chats: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// دالة إرسال رسالة (نص، صوت، صورة، فيديو).
  Future<void> sendMessage(
    String chatId,
    String text, {
    String? audioUrl,
    String? imageUrl,
    String? videoUrl,
  }) async {
    if (text.trim().isEmpty &&
        audioUrl == null &&
        imageUrl == null &&
        videoUrl == null) {
      return;
    }
    isSending.value = true;
    try {
      final success = await _repository.sendMessage(
        chatId,
        'admin',
        text,
        audioUrl: audioUrl,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      );
      if (success) await fetchChats();
    } catch (e) {
      // debugPrint('Error sending message: $e');
    } finally {
      isSending.value = false;
    }
  }

  /// جلب الملفات الشخصية لجميع المستخدمين (لغرض بدء دردشة جديدة).
  Future<void> fetchAllUserProfiles() async {
    try {
      final result = await _repository.getAllUserProfiles();
      allUserProfiles.assignAll(result);
    } catch (e) {
      // debugPrint('Error fetching user profiles: $e');
    }
  }

  /// بدء محادثة جديدة مع مستخدم معين أو فتح المحادثة الموجودة مسبقاً.
  Future<String?> startChatWithUser(ChatUserModel user) async {
    final chatId = await _repository.getOrCreateChat(
      user.id,
      'leave_request',
    );
    if (chatId != null) {
      await fetchChats();
      return chatId;
    }
    return null;
  }

  /// تفعيل الاستماع الحي للرسائل الموجهة للمنسق وتحديث الواجهة أو إظهار إشعارات.
  void _listenToMyMessages() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _myMessagesSubscription = _supabase
        .channel('admin_my_messages_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            final chatId = data['chat_id']?.toString();
            if (chatId != null) {
              showChat(chatId);
              fetchChats();

              bool isRoomOpen = false;
              try {
                if (Get.isRegistered<ChatRoomController>()) {
                  final chatController = Get.find<ChatRoomController>();
                  if (chatController.currentChatId == chatId) {
                    isRoomOpen = true;
                  }
                }
              } catch (_) {}

              if (!isRoomOpen) {
                NotificationService().showNotification(
                  id: chatId.hashCode,
                  title: 'New Message',
                  body: data['text'] ?? 'You have a new message',
                );
              }
            }
          },
        )
        .subscribe();
  }
}
