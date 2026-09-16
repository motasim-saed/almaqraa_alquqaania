import 'package:al_maqraa/Teacher/pages/data_students.dart';
import 'package:al_maqraa/core/quran/quran_screen.dart';
import 'package:al_maqraa/core/tajweed/tajweed_lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// متحكم الواجهة الرئيسية للمعلم لإدارة التنقل بين الشاشات
class HomepageTeacherController extends GetxController {
  // متغير مراقب لتخزين مؤشر التبويب المختار حالياً
  var selectedIndex = 0.obs;

  // وحدة التحكم في الصفحات لتمكين التمرير بين الشاشات
  late final PageController pageController = PageController(
    initialPage: selectedIndex.value,
  );

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  // قائمة الشاشات الفعلية التي يتم التبديل بينها في الواجهة الرئيسية
  final List<Widget> screens = [
    const DataStudents(), // شاشة متابعة بيانات الطلاب
    const QuranScreen(), // شاشة المصحف الإلكتروني
    const TajweedLessonsScreen(), // شاشة دروس التجويد
  ];

  /// دالة لجلب عنوان الـ AppBar بناءً على الصفحة المختارة
  String getAppBarTitle() {
    switch (selectedIndex.value) {
      case 0:
        return 'student_monitoring';
      case 1:
        return 'quran';
      case 2:
        return 'tajweed_lessons';
      default:
        return 'teacher_home';
    }
  }

  // وظيفة يتم استدعاؤها عند الضغط على أي تبويب في شريط التنقل السفلي
  void onItemTapped(int index) {
    selectedIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // وظيفة يتم استدعاؤها عند تغيير الصفحة بالسحب
  void onPageChanged(int index) {
    selectedIndex.value = index;
  }
}
