import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة
import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية للواجهات
import '../screen/final_exams_screen.dart'; // استيراد شاشة الاختبارات النهائية

class ExaminerMainLayoutController extends GetxController { // تعريف متحكم الواجهة الرئيسية للمختبر
  var selectedIndex = 0.obs;
  final PageController pageController = PageController();

  List<Widget> screens = [
    const FinalExamsScreen(),   // شاشة الاختبارات النهائية
  ];

  String getAppBarTitle() {
    return 'final_exams'.tr; // إرجاع نص "الاختبارات النهائية" المترجم
  }

  // دالة يتم استدعاؤها عند تغيير الصفحة عبر السحب اليدوي (Swipe) لتحديث رقم الصفحة
  void onPageChanged(int index) {
    selectedIndex.value = index; // تحديث قيمة الاندكس ليتزامن مع الصفحة الجديدة
  }

  // دالة يتم استدعاؤها عند النقر على أيقونات شريط التنقل السفلي (Bottom Navigation Bar)
  void onItemTapped(int index) {
    selectedIndex.value = index; // تحديث رقم الصفحة المختارة
    // تحريك الصفحة برفق (Animation) إلى الشاشة المطلوبة بدلاً من القفز المفاجئ
    pageController.animateToPage(
      index, // رقم الصفحة المستهدفة
      duration: const Duration(milliseconds: 300), // مدة الحركة الانتقالية (300 مللي ثانية)
      curve: Curves.easeInOut, // نوع الانسيابية في الحركة (بداية ونهاية ناعمة)
    );
  }

  @override
  void onClose() { // دالة يتم تنفيذها عند إغلاق أو تدمير المتحكم
    pageController.dispose(); // التخلص من متحكم الصفحات لتحرير موارد الذاكرة ومنع التسريب
    super.onClose(); // استدعاء دالة الإغلاق من الفئة الأم
  }
}
