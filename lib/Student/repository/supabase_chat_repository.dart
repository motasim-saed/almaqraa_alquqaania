// استيراد حزمة Supabase للتعامل مع قاعدة البيانات السحابية
import 'package:supabase_flutter/supabase_flutter.dart';
// استيراد حزمة GetX لدعم واجهة الترجمة
// import 'package:get/get.dart';
// استيراد نموذج الرسائل للتواصل
import 'package:al_maqraa/Admin/models/admin_models.dart';
// استيراد واجهة العمليات للمحادثات
import 'chat_repository.dart';

/// فئة تنفذ عمليات المحادثة باستخدام Supabase، متوافقة مع متطلبات [ChatRepository]
class SupabaseChatRepository implements ChatRepository {
  // إنشاء نسخة من عميل Supabase للاتصال بقاعدة البيانات
  final SupabaseClient _supabase = Supabase.instance.client;

  /// دالة لجلب أو إنشاء محادثة (شات) جديد بين مستخدمين
  @override
  Future<String?> getOrCreateChatId(
    String currentUserId,
    String otherUserId, {
    String? chatType,
  }) async {
    try {
      final isGroup = chatType == 'circle_group';

      if (isGroup) {
        // للمجموعات، نبحث أولاً في جدول chats عن السجل المرتبط بـ circle_id
        // معرف المجموعة (circle_id) هنا هو otherUserId
        final groupChat = await _supabase
            .from('chats')
            .select()
            .eq('type', 'circle_group')
            .eq('circle_id', otherUserId)
            .maybeSingle();

        if (groupChat != null) return groupChat['id'].toString();

        // إذا لم توجد محادثة للمجموعة في جدول chats، نقوم بإنشائها
        // ملاحظة: معرف المجموعه (Circle ID) يختلف عن معرف المستخدم (User ID)

        // جلب بيانات الحلقة للحصول على معرف المعلم
        String? actualTeacherId;
        try {
          final circleData = await _supabase
              .from('circles')
              .select('teacher_id')
              .eq('id', otherUserId)
              .maybeSingle();
          actualTeacherId = circleData?['teacher_id']?.toString();
        } catch (_) {}

        final insertData = {
          'type': 'circle_group',
          'circle_id': otherUserId,
          'teacher_id': actualTeacherId,
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          final newChat = await _supabase
              .from('chats')
              .insert(insertData)
              .select()
              .single();
          return newChat['id'].toString();
        } catch (e) {
          // في حال فشل الإدراج (مثلاً بسبب قيود RLS للطلاب)،
          // قد نضطر لاستخدام معرف الحلقة مباشرة كـ chat_id إذا كان النظام يدعم ذلك،
          // ولكن بناءً على الجداول المرسلة، يجب أن يكون هناك سجل في جدول chats.
          // نعود بمعرف المجموعة كحل أخير إذا كان النظام مصمماً على الربط المباشر
          return otherUserId;
        }
      } else {
        // للخاص، نبحث عن سجل حيث المشاركين هما الطالب والمعلم
        final chatResponse = await _supabase
            .from('chats')
            .select()
            .neq('type', 'circle_group')
            .or(
              'and(student_id.eq.$currentUserId,teacher_id.eq.$otherUserId),and(student_id.eq.$otherUserId,teacher_id.eq.$currentUserId)',
            )
            .maybeSingle();

        if (chatResponse != null) return chatResponse['id'].toString();

        final newChat = await _supabase
            .from('chats')
            .insert({
              'student_id': currentUserId,
              'teacher_id': otherUserId,
              'type': 'private',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        return newChat['id'].toString();
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*, sender:sender_id(full_name)')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      return (response as List).map((m) => MessageModel.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<MessageModel>> getMessagesSince(
    String chatId,
    DateTime since,
  ) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*, sender:sender_id(full_name)')
          .eq('chat_id', chatId)
          .gt('created_at', since.toIso8601String())
          .order('created_at', ascending: true);

      return (response as List).map((m) => MessageModel.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<MessageModel> sendMessage(Map<String, dynamic> messageData) async {
    try {
      final dataToInsert = Map<String, dynamic>.from(messageData);

      // تنظيف البيانات من الحقول المحلية التي لا توجد في قاعدة البيانات السحابية
      dataToInsert.remove('id'); // السيرفر يولد المعرف
      dataToInsert.remove('is_pending');
      dataToInsert.remove('local_audio_path');
      dataToInsert.remove('local_image_path');
      dataToInsert.remove('local_video_path');
      dataToInsert.remove('local_file_path');
      dataToInsert.remove('sender_name');
      
      // إزالة audio_duration و status لتجنب خطأ PGRST204 (العمود غير موجود في السحاب)
      dataToInsert.remove('audio_duration'); 
      dataToInsert.remove('status'); 

      final response = await _supabase
          .from('messages')
          .insert(dataToInsert)
          .select('*, sender:sender_id(full_name)')
          .single();

      return MessageModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<void> editMessage(String messageId, String newText) async {
    await _supabase
        .from('messages')
        .update({'text': newText, 'is_edited': true})
        .eq('id', messageId);
  }

  @override
  Future<void> deleteMessage(String messageId, {required bool forAll}) async {
    if (forAll) {
      await _supabase.from('messages').delete().eq('id', messageId);
    }
  }

  @override
  Future<void> deleteMessagesBatch(
    List<String> messageIds, {
    required bool forAll,
  }) async {
    if (messageIds.isEmpty) return;
    await _supabase.from('messages').delete().filter('id', 'in', messageIds);
  }

  @override
  Future<void> updateChatLastMessage(String chatId, String lastMessage) async {
    try {
      await _supabase
          .from('chats')
          .update({
            'last_message': lastMessage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);
    } catch (_) {}
  }

  @override
  Stream<List<MessageModel>> getMessageStream(String chatId) {
    return const Stream.empty();
  }

  @override
  Future<Map<String, dynamic>?> getStudentDetailedInfo(String studentId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select(
            '*, circle_members(circles(name, teacher:profiles!circles_teacher_id_fkey(full_name)))',
          )
          .eq('id', studentId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCircleDetails(String circleId) async {
    try {
      final circleResponse = await _supabase
          .from('circles')
          .select(
            '*, teacher:profiles!circles_teacher_id_fkey(id, full_name, avatar_url)',
          )
          .eq('id', circleId)
          .maybeSingle();

      if (circleResponse == null) return null;

      final membersResponse = await _supabase
          .from('circle_members')
          .select('student:profiles(id, full_name, avatar_url, role)')
          .eq('circle_id', circleId);

      final List students = (membersResponse as List)
          .map((m) => m['student'])
          .where((s) => s != null)
          .toList();

      return {
        'id': circleResponse['id'],
        'name': circleResponse['name'],
        'teacher_id': circleResponse['teacher']?['id'],
        'teacher_name': circleResponse['teacher']?['full_name'],
        'teacher_avatar': circleResponse['teacher']?['avatar_url'],
        'background_url': circleResponse['background_url'],
        'students': students,
        'student_count': students.length,
      };
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getProfileName(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      return response?['full_name']?.toString();
    } catch (e) {
      return null;
    }
  }
}
