import 'package:flutter/material.dart'; // استيراد مكتبة واجهات فلاتر الأساسية
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والترجمة والتنقل
import 'package:shared_preferences/shared_preferences.dart'; // استيراد مكتبة التخزين المحلي لحفظ الإعدادات دائمًا

/// شرح عمل الملف:
/// هذا الملف يمثل "متحكم المظهر" (ThemeController).
/// وظيفته الأساسية هي إدارة التبديل بين الوضع الفاتح (Light Mode) والوضع الليلي (Dark Mode) في التطبيق.
/// يقوم بحفظ اختيار المستخدم في ذاكرة الهاتف (SharedPreferences) ليبقى المظهر كما اختاره المستخدم حتى بعد إغلاق التطبيق وفتحه مرة أخرى.
///
/// أين يستخدم:
/// 1. في `main.dart`: لتهيئة المظهر عند بدء التشغيل.
/// 2. في "شاشة الإعدادات": عند قيام المستخدم بالنقر على زر تبديل المظهر.
/// 3. في جميع شاشات التطبيق: لتحديد الألوان المناسبة بناءً على الوضع الحالي.

class ThemeController extends GetxController {
  // تعريف الفئة كمتحكم تابع لـ GetX
  static const String _themeKey =
      'isDarkMode'; // المفتاح المستخدم لحفظ القيمة في ذاكرة الهاتف
  final _isDarkMode = false
      .obs; // متغير تفاعلي (Observable) يراقب حالة المظهر (True = ليلي، False = فاتح)

  bool get isDarkMode =>
      _isDarkMode.value; // دالة جلب الحالة الحالية للمظهر (للقراءة فقط)

  @override
  void onInit() {
    // دالة يتم تنفيذها فور إنشاء المتحكم
    super.onInit(); // تنفيذ الوظائف الأساسية لـ GetX
    _loadTheme(); // تحميل المظهر المحفوظ مسبقاً من الذاكرة
  }

  /// دالة تحميل المظهر من ذاكرة الهاتف
  void _loadTheme() async {
    final prefs =
        await SharedPreferences.getInstance(); // فتح مخزن الإعدادات المحلي
    _isDarkMode.value =
        prefs.getBool(_themeKey) ??
        false; // قراءة القيمة المحفوظة (أو استخدام False كقيمة افتراضية)
    // تغيير مظهر التطبيق بالكامل بناءً على القيمة المحملة
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  /// دالة تبديل المظهر (من فاتح إلى ليلي أو العكس)
  void toggleTheme() async {
    _isDarkMode.value =
        !_isDarkMode.value; // عكس القيمة الحالية (True تصبح False والعكس)

    // تحديث مظهر التطبيق لحظياً في جميع الشاشات
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);

    // حفظ القيمة الجديدة في ذاكرة الهاتف لضمان بقائها عند إعادة تشغيل التطبيق
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode.value);
  }
}
