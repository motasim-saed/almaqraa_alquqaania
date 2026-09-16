import 'package:flutter_dotenv/flutter_dotenv.dart';

/// شرح عمل الملف:
/// هذا الملف مسؤول عن إدارة إعدادات منصة Supabase داخل التطبيق.
/// يقوم بجلب الروابط الأساسية من ملف البيئة (.env) لضمان الأمان، 
/// ويحتوي على أسماء حاويات التخزين (Buckets) ودوال مساعدة للتعامل مع روابط الملفات.

class SupabaseConfig {
  // جلب الرابط الأساسي لمشروع Supabase من ملف الـ .env
  // تم حذف الرابط المباشر لزيادة الأمان والاعتماد كلياً على ملف الإعدادات
  static String get baseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  
  // بناء رابط الوصول لخدمة التخزين (Storage) بناءً على الرابط الأساسي المحمل
  static String get storageUrl => '$baseUrl/storage/v1/object/public';

  // تعريف أسماء الحاويات (Buckets) المستخدمة في المشروع:
  static const String bucketPledges = 'pledges';     // حاوية التعهدات
  static const String bucketTeachers = 'teachers';   // حاوية صور المعلمين
  static const String bucketAttachments = 'attachments'; // حاوية المرفقات العامة

  /// دالة مساعدة لتحويل مسار الملف المخزن إلى رابط (URL) كامل صالح للعرض.
  /// [bucket]: اسم الحاوية (مثلاً teachers أو attachments).
  /// [path]: المسار النسبي للملف داخل الحاوية.
  static String getImageUrl(String bucket, String path) {
    // إذا كان المسار المعطى رابطاً كاملاً بالفعل، يتم إرجاعه كما هو
    if (path.startsWith('http')) return path;
    
    // دمج رابط التخزين مع اسم الحاوية والمسار للحصول على الرابط النهائي
    return '$storageUrl/$bucket/$path';
  }
}
