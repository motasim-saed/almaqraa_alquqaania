// استيراد نموذج الرسائل للتفاعل مع بيانات الرسالة
import 'package:al_maqraa/Admin/models/admin_models.dart'; // استيراد النماذج الخاصة بالمسؤول للتعامل مع الرسائل

/// واجهة تُعَرِّف الوظائف الأساسية لمستودع محادثات الطالب (الشات)
abstract class ChatRepository { // تعريف فئة مجردة لمستودع المحادثات
  Future<String?> getOrCreateChatId( // دالة للحصول على معرف المحادثة أو إنشائه
    String currentUserId, // معرف المستخدم الحالي
    String otherUserId, { // معرف الطرف الآخر في المحادثة
    String? chatType, // نوع المحادثة (اختياري)
  }); // نهاية تعريف الدالة
  
  Future<List<MessageModel>> getMessages(String chatId); // دالة لجلب جميع الرسائل لمحادثة معينة باستخدام معرف المحادثة
  
  Future<List<MessageModel>> getMessagesSince(String chatId, DateTime since); // دالة لجلب الرسائل منذ وقت معين لمحادثة محددة
  
  Future<MessageModel> sendMessage(Map<String, dynamic> messageData); // دالة لإرسال رسالة جديدة باستخدام بيانات الرسالة
  
  Future<void> editMessage(String messageId, String newText); // دالة لتعديل نص رسالة موجودة باستخدام معرف الرسالة
  
  Future<void> deleteMessage(String messageId, {required bool forAll}); // دالة لحذف رسالة معينة مع خيار الحذف للجميع

  /// دالة للحذف الجماعي لتجنب أخطاء الاتصال وتحسين الأداء
  Future<void> deleteMessagesBatch(List<String> messageIds, {required bool forAll}); // دالة لحذف مجموعة من الرسائل دفعة واحدة
  
  Future<void> updateChatLastMessage(String chatId, String lastMessage); // دالة لتحديث نص آخر رسالة في المحادثة
  
  Stream<List<MessageModel>> getMessageStream(String chatId); // دالة للحصول على تدفق بيانات (Stream) للرسائل لمتابعة التحديثات اللحظية

  Future<Map<String, dynamic>?> getStudentDetailedInfo(String studentId); // دالة لجلب معلومات مفصلة عن الطالب باستخدام معرفه

  Future<Map<String, dynamic>?> getCircleDetails(String circleId); // دالة لجلب تفاصيل الحلقة باستخدام معرف الحلقة

  Future<String?> getProfileName(String userId); // دالة لجلب اسم المستخدم من ملفه الشخصي
} // نهاية تعريف الفئة المجردة
