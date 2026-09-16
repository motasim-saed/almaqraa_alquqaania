import 'package:al_maqraa/Student/pages/daily_progress_screen.dart'; // استيراد شاشة سجل الإنجاز
import 'package:al_maqraa/core/quran/quran_screen.dart'; // استيراد شاشة المصحف
import 'package:al_maqraa/core/tajweed/tajweed_lessons_screen.dart'; // استيراد شاشة دروس التجويد
import 'package:flutter/material.dart'; // حزمة واجهات فلاتر الأساسية
import 'package:get/get.dart'; // حزمة GetX لإدارة الحالة والترجمة

/// وحدة التحكم (Controller) الخاصة بالصفحة الرئيسية للطالب
/// تدير منطق التنقل بين الصفحات المختلفة وتحديث شريط التطبيق
class HomepageStudentController extends GetxController {
  // متغير تفاعلي لمتابعة الصفحة المختارة حالياً وتغييرها في الواجهة فوراً
  var selectedIndex = 0.obs;

  // متحكم الصفحات لتمكين خاصية السحب (Swipe) والتنقل البرمجي بينها
  late PageController pageController;

  // قائمة الشاشات (التبويبات) المتاحة للطالب في الشريط السفلي
  final List<Widget> screens = [
    const DailyProgressScreen(),   // 0: تبويب سجل الإنجاز اليومي
    const QuranScreen(),           // 1: تبويب المصحف الشريف
    const TajweedLessonsScreen(),  // 2: تبويب دروس التجويد
  ];

  @override
  void onInit() {
    super.onInit(); // استدعاء دالة التهيئة للأب
    // تهيئة متحكم الصفحات مع تحديد الصفحة الابتدائية بناءً على المؤشر المختارة
    pageController = PageController(initialPage: selectedIndex.value);
  }

  @override
  void onClose() {
    pageController.dispose(); // إغلاق متحكم الصفحات عند إغلاق الكنترولر لتوفير موارد الذاكرة
    super.onClose(); // استدعاء دالة الإغلاق للأب
  }

  /// دالة لجلب مفتاح الترجمة المخصص لعنوان شريط التطبيق (AppBar) حسب الصفحة الحالية
  String getAppBarTitle() {
    switch (selectedIndex.value) {
      case 0:
        return 'daily_progress';  // عنوان سجل الإنجاز
      case 1:
        return 'quran';           // عنوان المصحف
      case 2:
        return 'tajweed';         // عنوان دروس التجويد
      default:
        return 'student_home';    // عنوان افتراضي (الرئيسية)
    }
  }

  /// تحديث الفهرس وتحريك الصفحة عند النقر يدوياً على أحد أيقونات الشريط السفلي
  void onItemTapped(int index) {
    selectedIndex.value = index; // تحديث قيمة المؤشر النشط
    // تحريك الصفحة في الـ PageView بشكل سلس (Animated)
    pageController.animateToPage(
      index, // الصفحة المستهدفة
      duration: const Duration(milliseconds: 200), // مدة الحركة (200 مللي ثانية)
      curve: Curves.easeInOut, // شكل الحركة (بدء وانتهار ناعم)
    );
  }

  /// دالة يتم استدعاؤها عند السحب اليدوي (Swipe) في الشاشة لتحديث أيقونات الشريط السفلي
  void onPageChanged(int index) {
    selectedIndex.value = index; // تحديث المؤشر النشط ليتوافق مع الصفحة الظاهرة
  }
}
