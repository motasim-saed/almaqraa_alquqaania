import 'package:flutter/material.dart'; // استيراد مكتبة واجهات فلاتر الأساسية
// import 'package:get/get.dart'; // استيراد GetX لإمكانية الوصول للترجمة لاحقاً

/// شرح عمل الملف:
/// هذا الملف هو "محرك السمات" (AppTheme) الخاص بالتطبيق.
/// وظيفته الأساسية هي توحيد المظهر البصري لجميع الشاشات من حيث:
/// 1. الألوان الأساسية والثانوية (Primary & Accent Colors).
/// 2. دعم الوضع الفاتح (Light Mode) والوضع الليلي (Dark Mode) تلقائياً.
/// 3. تحديد نوع الخط المستخدم (Cairo) لضمان تجربة قراءة ممتازة للغة العربية.
/// 4. توحيد أنماط البطاقات (Cards) والحقول النصية (Inputs) في كل التطبيق.
///
/// أين يستخدم:
/// - في `main.dart`: عند تعريف `GetMaterialApp` لتحديد الثيم الافتراضي.
/// - في أي شاشة: عند الرغبة في استخدام ألوان ثابتة تتبع الهوية البصرية.

class AppTheme {
  /// دالة بناء الثيم بناءً على حالة الإضاءة (فاتح أو غامق)
  static ThemeData buildTheme(Brightness brightness) {
    return ThemeData(
      brightness: brightness, // تحديد هل الثيم فاتح أم غامق
      useMaterial3: true, // تفعيل لغة التصميم Material 3 الأحدث من جوجل
      fontFamily:
          'Cairo', // تحديد الخط الأساسي للتطبيق (مناسب جداً للقرآن واللغة العربية)
      // إعداد تدرج الألوان بناءً على لون بذرة (Seed Color)
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo, // اللون الأساسي (النيلي)
        brightness: brightness,
        primary: brightness == Brightness.light
            ? Colors.indigo // لون أساسي في الوضع الفاتح
            : const Color(0xFF818CF8), // لون نيلي فاتح وواضح جداً في الوضع الليلي لضمان الظهور
        onPrimary: Colors.white,
        surface: brightness == Brightness.light
            ? const Color(0xFFF8F9FE)
            : const Color(0xFF12121A),
      ),

      // لون خلفية الشاشات (Scaffold)
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF8F9FE) // رمادي مائل للزرقة خفيف جداً للفاتح
          : const Color(0xFF0F0F15), // أسود مائل للنيلي الغامق جداً لليلي لعمق أكبر
      // تخصيص مظهر شريط التطبيق العلوي (AppBar)
      appBarTheme: AppBarTheme(
        elevation: 0, // إلغاء الظل لجعل التصميم مسطحاً وعصرياً
        backgroundColor: brightness == Brightness.light
            ? Colors.indigo // لون نيلي في الفاتح
            : const Color(0xFF16161E), // رمادي غامق جداً في الليلي ليتناسق مع الخلفية
        foregroundColor: brightness == Brightness.light 
            ? Colors.white 
            : const Color(0xFFE2E8F0), // لون أوف وايت للأيقونات والنصوص لتقليل التوهج
        centerTitle: true, // جعل العنوان في المنتصف دائماً
      ),

      // تخصيص مظهر البطاقات (Cards)
      cardTheme: CardThemeData(
        elevation: 0, // جعلها مسطحة
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ), // زوايا دائرية كبيرة
        color: brightness == Brightness.light
            ? Colors
                  .white // بطاقة بيضاء في الفاتح
            : const Color(0xFF1E1E2C), // بطاقة رمادية غامقة في الليلي
      ),

      // تخصيص مظهر حقول الإدخال (TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true, // جعل الحقل مملوءاً بلون خلفية
        fillColor: brightness == Brightness.light
            ? Colors
                  .white // خلفية بيضاء في الفاتح
            : const Color(0xFF1E1E2C), // خلفية غامقة في الليلي
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // إلغاء الإطار الافتراضي
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.indigo,
            width: 2,
          ), // إطار نيلي عند التركيز
        ),
      ),
    );
  }

  // ============== ألوان ثابتة يمكن استخدامها يدوياً في الكود ==============

  static const Color primaryColor = Colors.indigo; // اللون النيلي الأساسي
  static const Color accentColor = Colors.indigoAccent; // اللون النيلي الفاتح
  static const Color lightBg = Color(0xFFF8F9FE); // خلفية الوضع الفاتح
  static const Color darkBg = Color(0xFF12121A); // خلفية الوضع الليلي
  static const Color lightCard = Colors.white; // لون بطاقات الوضع الفاتح
  static const Color darkCard = Color(0xFF1E1E2C); // لون بطاقات الوضع الليلي

  // /// دالة لإظهار رسالة منبثقة عند تغيير الثيم (مترجمة)
  // static void showThemeChangedMessage() {
  //   Get.snackbar(
  //     'success'.tr, // عنوان "نجاح" مترجم
  //     'theme_changed'.tr, // رسالة "تم تغيير المظهر" مترجمة
  //     snackPosition: SnackPosition.BOTTOM,
  //     backgroundColor: Colors.indigo.withOpacity(0.8),
  //     colorText: Colors.white,
  //     duration: const Duration(seconds: 2),
  //   );
  // }
}
