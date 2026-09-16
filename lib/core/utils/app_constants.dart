// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // Django Backend API Base URL
  static String get djangoApiBaseUrl {
    return 'https://almaqraalquraniahalalamiah.onrender.com'; // تصحيح الرابط بإزالة التكرار
  }

  // مفتاح الأمان لربط فلاتر بجانجو
  static const String djangoApiKey = 'maqraa_secret_2026_safe_key';

  // =============================================
  // روابط التواصل والدعم الفني (مركزية لكل التطبيق)
  // =============================================
  static const String whatsappNumber = '584264609548'; // رقم الواتساب بالصيغة الدولية بدون + أو 00
  static const String telegramUsername = 'Eng_Motasim'; // يوزر التليجرام بدون @
  // static const String linkedInUrl = 'https://www.linkedin.com/in/eng-motasim-saeed-alsalahi-4352b6331'; // رابط لينكد إن الكامل
  static const String supportEmail = 'motasimalsalahi@gmail.com'; // البريد الإلكتروني للدعم

  // روابط جاهزة للفتح
  static String get whatsappUrl => 'https://wa.me/$whatsappNumber';
  static String get telegramUrl => 'https://t.me/$telegramUsername';
  static String get emailUrl => 'mailto:$supportEmail';

  // =============================================
  // صورة الدعم الفني (من Supabase Storage)
  // =============================================
  // اسم الحاوية التي ستحفظ فيها صورتك في Supabase (استخدام حاوية profiles الموجودة)
  static const String bucketSupport = 'Technical_support';
  // مسار الصورة داخل الحاوية
  static const String supportImagePath = 'motasim.jpg';

  // =============================================
  // رابط مشاركة التطبيق (قم بإلغاء التعليق عند نشر التطبيق في المتجر)
  // static const String appShareLink = 'https://play.google.com/store/apps/details?id=com.yourapp.id';
  static const String appShareLink = ''; // فارغ مؤقتاً حتى يتم نشر التطبيق

  static const List<String> gregorianMonths = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
  ];
}
