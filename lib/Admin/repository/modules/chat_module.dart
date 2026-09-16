import 'dart:io'; // استيراد مكتبة التعامل مع الملفات (الإدخال والإخراج)
import 'dart:async'; // استيراد مكتبة البرمجة المتزامنة للتعامل مع المستقبلات (Futures) والجداول الزمنية
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة سوبابيس للتعامل مع قاعدة البيانات السحابية
import '../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بمدير النظام
import '../../../core/config/supabase_config.dart'; // استيراد إعدادات تكوين سوبابيس الخاصة بالمشروع

mixin ChatModule { // تعريف "ميكسين" (وحدة برمجية) مخصصة لإدارة عمليات الدردشة
  SupabaseClient get supabase => Supabase.instance.client; // خاصية جلب (Getter) للوصول المباشر لعميل سوبابيس

  Future<List<ChatModel>> getChats() async { // دالة لجلب قائمة المحادثات للمستخدم الحالي بشكل غير متزامن
    try { // بدء كتلة المحاولة للتعامل مع الأخطاء المحتملة
      final currentUserId = supabase.auth.currentUser?.id; // الحصول على معرف المستخدم الحالي المسجل دخوله
      if (currentUserId == null) return []; // إذا لم يوجد مستخدم مسجل، يتم إرجاع قائمة فارغة

      final response = await supabase // تنفيذ طلب استعلام من سوبابيس
          .from('chats') // تحديد جدول المحادثات 'chats'
          .select( // تحديد الحقول المطلوب جلبها مع العلاقات المرتبطة
            '*, student:student_id(id, full_name, role, gender, avatar_url, batch_number), teacher:teacher_id(id, full_name, role, gender, avatar_url, batch_number)',
          ) // جلب بيانات الطالب والمعلم المرتبطين بالمحادثة وتفاصيلهم
          .or('student_id.eq.$currentUserId,teacher_id.eq.$currentUserId') // جلب المحادثات التي يكون المستخدم الحالي طرفاً فيها
          .order('updated_at', ascending: false); // ترتيب المحادثات تنازلياً حسب وقت آخر تحديث

      final unreadResponse = await supabase // استعلام آخر لجلب عدد الرسائل غير المقروءة
          .from('messages') // تحديد جدول الرسائل 'messages'
          .select('chat_id') // اختيار معرف المحادثة فقط
          .neq('sender_id', currentUserId) // تصفية الرسائل التي لم يرسلها المستخدم الحالي
          .eq('receiver_id', currentUserId) // تصفية الرسائل التي استقبلها المستخدم الحالي
          .isFilter('read_at', null); // تصفية الرسائل التي لم يتم قراءتها بعد (حقل القراءة فارغ)

      Map<String, int> unreadCounts = {}; // إنشاء خريطة لتخزين عدد الرسائل غير المقروءة لكل محادثة
      for (var row in unreadResponse as List) { // الدوران على قائمة الرسائل غير المقروءة
        final cid = row['chat_id']?.toString(); // تحويل معرف المحادثة إلى نص
        if (cid != null) { // التأكد من وجود معرف للمحادثة
          unreadCounts[cid] = (unreadCounts[cid] ?? 0) + 1; // زيادة العداد الخاص بهذه المحادثة بمقدار واحد
        } // نهاية شرط التحقق من المعرف
      } // نهاية حلقة الدوران

      return (response as List).map((data) { // تحويل كل عنصر من نتائج الاستعلام إلى كائن ChatModel
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from( // تحويل البيانات الخام إلى خريطة مفاتيحها نصوص
          data as Map,
        ); // نهاية التحويل

        String displayName = dataMap['name']?.toString() ?? ''; // جلب اسم المحادثة إن وجد أو نص فارغ

        final isCurrentUserInFirstSlot = // تحديد ما إذا كان المستخدم الحالي هو المسجل في خانة الطالب
            dataMap['student_id']?.toString() == currentUserId;

        final Map<String, dynamic>? otherUserProfile = isCurrentUserInFirstSlot // استخراج الملف الشخصي للطرف الآخر
            ? (dataMap['teacher'] != null // إذا كان المستخدم هو الطالب، يتم جلب بيانات المعلم
                  ? Map<String, dynamic>.from(dataMap['teacher'] as Map)
                  : null)
            : (dataMap['student'] != null // إذا كان المستخدم هو المعلم، يتم جلب بيانات الطالب
                  ? Map<String, dynamic>.from(dataMap['student'] as Map)
                  : null);

        if (displayName.isEmpty) { // إذا لم يكن للمحادثة اسم (دردشة فردية)
          displayName = (otherUserProfile != null) // يتم استخدام اسم الطرف الآخر كاسم للمحادثة
              ? (otherUserProfile['full_name'] ?? 'مستخدم')
              : 'مستخدم غير معروف';
        } // نهاية شرط تعيين الاسم

        final otherUserId = isCurrentUserInFirstSlot // تحديد معرف الطرف الآخر في المحادثة
            ? dataMap['teacher_id']
            : dataMap['student_id'];

        final int? batchNum = otherUserProfile != null && otherUserProfile['batch_number'] != null // جلب رقم الدفعة للطرف الآخر
            ? int.tryParse(otherUserProfile['batch_number'].toString()) 
            : null;

        return ChatModel( // إنشاء كائن ChatModel بالبيانات التي تمت معالجتها
          id: dataMap['id']?.toString() ?? '', // تعيين معرف المحادثة
          userId: otherUserId?.toString() ?? '', // تعيين معرف المستخدم الآخر
          userName: displayName, // تعيين اسم العرض
          userAvatar: otherUserProfile?['avatar_url'], // تعيين رابط الصورة الشخصية
          lastMessage: dataMap['last_message'] ?? '', // تعيين نص آخر رسالة
          lastSenderId: dataMap['last_sender_id']?.toString() ?? '', // تعيين معرف مرسل آخر رسالة
          updatedAt: DateTime.parse( // تعيين وقت التحديث بعد تحويله لنوع تاريخ
            dataMap['updated_at'] ?? DateTime.now().toIso8601String(),
          ), 
          type: dataMap['type'] ?? 'chat', // تعيين نوع المحادثة (فردية أم مجموعة)
          userRole: (otherUserProfile != null) // تعيين دور المستخدم الآخر (معلم أم طالب)
              ? (otherUserProfile['role'] ?? 'student')
              : 'student', 
          gender: // تعيين جنس المستخدم الآخر (ذكر أم أنثى)
              (otherUserProfile != null &&
                  otherUserProfile['gender'] == 'female')
              ? Gender.female
              : Gender.male, 
          unreadCount: unreadCounts[dataMap['id']?.toString()] ?? 0, // تعيين عدد الرسائل غير المقروءة لهذه المحادثة
          batchNumber: batchNum, // تعيين رقم الدفعة
        ); // نهاية إنشاء كائن ChatModel
      }).toList(); // تحويل النتائج النهائية إلى قائمة (List)
    } catch (e) { // الإمساك بالأخطاء في حال حدوثها
      return []; // إرجاع قائمة فارغة عند حدوث خطأ
    } // نهاية كتلة try-catch
  } // نهاية دالة getChats

  Future<void> markMessagesAsRead(String chatId) async { // دالة لتحديث حالة الرسائل كمقروءة في قاعدة البيانات
    try { // بدء محاولة تنفيذ التحديث
      final currentUserId = supabase.auth.currentUser?.id; // الحصول على معرف المستخدم الحالي
      if (currentUserId == null) return; // الخروج إذا لم يوجد مستخدم مسجل

      await supabase // تنفيذ عملية التحديث في سوبابيس
          .from('messages') // جدول الرسائل
          .update({'read_at': DateTime.now().toIso8601String()}) // تعيين وقت القراءة للوقت الحالي
          .eq('chat_id', chatId) // تصفية الرسائل للمحادثة المحددة فقط
          .eq('receiver_id', currentUserId) // تصفية الرسائل المستلمة من قبل المستخدم الحالي
          .isFilter('read_at', null); // تحديث الرسائل التي لم تكن مقروءة فقط

      await supabase // تحديث عداد الرسائل غير المقروءة في جدول المحادثات (للتصفير)
          .from('chats')
          .update({'unread_count': 0}) 
          .eq('id', chatId); 
          
    } catch (e) {} // تجاهل الأخطاء لضمان استقرار التطبيق
  } // نهاية دالة markMessagesAsRead

  Future<List<ChatUserModel>> getAllUserProfiles() async { // دالة لجلب كافة بروفايلات المستخدمين المتاحين للدردشة
    try {
      final response = await supabase // طلب البيانات من جدول البروفايلات
          .from('profiles')
          .select('id, full_name, role, gender, avatar_url, batch_number, phone') // اختيار الحقول الضرورية فقط
          .neq('role', 'admin') // استبعاد مدراء النظام من القائمة
          .order('full_name'); // ترتيب الأسماء أبجدياً

      return (response as List).map<ChatUserModel>((data) { // تحويل قائمة البيانات المستلمة إلى كائنات ChatUserModel
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
          data as Map,
        );
        return ChatUserModel( // إنشاء نموذج مستخدم الدردشة
          id: dataMap['id']?.toString() ?? '', 
          name: dataMap['full_name'] ?? 'مستخدم', 
          role: dataMap['role'] ?? 'student', 
          gender: dataMap['gender'] == 'female' ? Gender.female : Gender.male, 
          batchNumber: dataMap['batch_number'] != null ? int.tryParse(dataMap['batch_number'].toString()) : null,
          phone: dataMap['phone']?.toString(),
        );
      }).toList(); 
    } catch (e) {
      return [];
    }
  } // نهاية دالة getAllUserProfiles

  Future<List<MessageModel>> getMessages(String chatId) async { // دالة لجلب الرسائل السابقة لمحادثة معينة
    try {
      final response = await supabase // استعلام من جدول الرسائل
          .from('messages')
          .select('*, sender:sender_id(full_name)') // جلب بيانات الرسالة مع اسم المرسل
          .eq('chat_id', chatId) // التصفية حسب معرف المحادثة
          .order('created_at', ascending: true); // الترتيب من الأقدم إلى الأحدث
      return (response as List)
          .map((data) => MessageModel.fromJson(data)) // تحويل البيانات إلى كائنات MessageModel
          .toList();
    } catch (e) {
      return [];
    }
  } // نهاية دالة getMessages

  Stream<List<MessageModel>> getMessagesStream(String chatId) { // دالة توفر تدفقاً حياً للرسائل المحدثة تلقائياً
    return supabase
        .from('messages') // مراقبة جدول الرسائل
        .stream(primaryKey: ['id']) // استخدام المعرف كمفتاح أساسي للتتبع
        .eq('chat_id', chatId) // مراقبة الرسائل الخاصة بهذه المحادثة فقط
        .order('created_at', ascending: true) // ضمان الترتيب الزمني الصحيح
        .map((maps) => maps.map((map) => MessageModel.fromJson(map)).toList()); // تحويل كل تحديث جديد لقائمة نماذج
  } // نهاية دالة getMessagesStream

  Future<void> deleteMessageFromServer(String messageId) async { // دالة لحذف رسالة معينة من الخادم
    try {
      await supabase.from('messages').delete().eq('id', messageId); // تنفيذ أمر الحذف في سوبابيس
    } catch (e) {}
  } // نهاية دالة deleteMessageFromServer

  Future<bool> sendMessage( // دالة إرسال رسالة جديدة (نصية أو وسائط)
    String chatId, 
    String senderId, 
    String text, { 
    String? audioUrl, 
    String? imageUrl, 
    String? videoUrl, 
  }) async {
    try {
      String finalSenderId = senderId; // تحديد معرف المرسل النهائي
      if (senderId == 'admin') { // إذا كان المرسل هو "أدمن" (كلمة مفتاحية)
        final currentUserId = supabase.auth.currentUser?.id; // جلب المعرف الحقيقي من سوبابيس
        if (currentUserId != null) finalSenderId = currentUserId; // تحديث المعرف
      }

      String msgText = text; // تحديد نص الرسالة
      if (text.isEmpty) { // إذا كان النص فارغاً (رسالة وسائط)
        if (imageUrl != null) {
          msgText = '[صورة]'; // وضع وصف للصورة كآخر رسالة
        } else if (videoUrl != null) {
          msgText = '[فيديو]';
        } // وضع وصف للفيديو
        else if (audioUrl != null) {
          msgText = '[صوت]';
        } // وضع وصف للصوت
      }

      final chatData = await supabase.from('chats').select('student_id, teacher_id').eq('id', chatId).single(); // جلب أطراف المحادثة
      final String receiverId = (chatData['student_id'] == finalSenderId) // تحديد من هو المستقبل بناءً على المرسل
          ? chatData['teacher_id'].toString()
          : chatData['student_id'].toString();

      await supabase.from('messages').insert({ // إدراج سجل الرسالة الجديدة في القاعدة
        'chat_id': chatId,
        'sender_id': finalSenderId,
        'receiver_id': receiverId, 
        'text': msgText,
        'audio_url': audioUrl,
        'image_url': imageUrl,
        'video_url': videoUrl,
      });

      await supabase.rpc('increment_unread_count', params: {'chat_id_param': chatId}); // استدعاء دالة قاعدة بيانات لزيادة العداد

      await supabase // تحديث جدول المحادثات ببيانات آخر رسالة ووقت التحديث
          .from('chats')
          .update({
            'last_message': msgText,
            'last_sender_id': finalSenderId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);

      return true; // إرجاع نجاح العملية
    } catch (e) {
      return false; // إرجاع فشل العملية في حال الخطأ
    }
  } // نهاية دالة sendMessage

  Future<String> uploadFile(String bucket, String path, String filePath) async { // دالة لرفع الملفات إلى التخزين السحابي
    try {
      final file = File(filePath); // إنشاء كائن ملف من المسار المحلي
      await supabase.storage.from(bucket).upload(path, file); // رفع الملف للحاوية المحددة في سوبابيس
      return SupabaseConfig.getImageUrl(bucket, path); // إرجاع الرابط العام للملف المرفوع
    } catch (e) {
      rethrow; // إعادة رمي الخطأ ليتم التعامل معه في الواجهة
    }
  } // نهاية دالة uploadFile

  Future<bool> updateChatStatus(String chatId, String status) async { // دالة لتحديث حالة المحادثة (نشطة، مؤرشفة، إلخ)
    try {
      await supabase.from('chats').update({'status': status}).eq('id', chatId); // تنفيذ التحديث في الجدول
      return true;
    } catch (e) {
      return false;
    }
  } // نهاية دالة updateChatStatus

  Future<String?> getOrCreateChat(String userId, String? type) async { // دالة ذكية لإيجاد محادثة سابقة أو إنشاء واحدة جديدة
    try {
      final currentUserId = supabase.auth.currentUser?.id; // الحصول على معرف المستخدم الحالي
      if (currentUserId == null) return null;

      final existingChat = await supabase // البحث عن أي محادثة ثنائية قائمة بين الطرفين
          .from('chats')
          .select()
          .or(
            'and(student_id.eq.$currentUserId,teacher_id.eq.$userId),and(student_id.eq.$userId,teacher_id.eq.$currentUserId)',
          )
          .maybeSingle(); // إرجاع نتيجة واحدة أو فارغة

      if (existingChat != null) { // إذا وجدت محادثة سابقة
        return existingChat['id'].toString(); // يتم إرجاع معرفها فوراً
      }

      final newChat = await supabase // إذا لم توجد محادثة، يتم إنشاء سجل جديد
          .from('chats')
          .insert({
            'student_id': userId, 
            'teacher_id': currentUserId, 
            'updated_at': DateTime.now().toIso8601String(), 
          })
          .select()
          .single(); // استلام بيانات السجل الجديد

      return newChat['id'].toString(); // إرجاع معرف المحادثة المنشأة
    } catch (e) {
      return null; 
    }
  } // نهاية دالة getOrCreateChat
} // نهاية تعريف الميكسين ChatModule
