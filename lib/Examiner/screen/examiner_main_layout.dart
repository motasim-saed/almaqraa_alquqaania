import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية للواجهات
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والترجمة
import 'final_exams_screen.dart'; // استيراد شاشة الاختبارات النهائية
import '../controller/final_exams_controller.dart'; // استيراد متحكم الاختبارات النهائية
import '../widget/examiner_drawer.dart'; // استيراد القائمة الجانبية للمختبر
import 'package:al_maqraa/core/controllers/notification_controller.dart'; // استيراد متحكم الإشعارات
import 'notifications/examiner_notifications_screen.dart'; // استيراد شاشة الإشعارات
import 'package:al_maqraa/components/app_exit_wrapper.dart'; // استيراد ويدجت الخروج المشتركة

class ExaminerMainLayout extends StatelessWidget {
  // تعريف الواجهة الرئيسية للمختبر كويدجت عديم الحالة
  const ExaminerMainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return AppExitWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'final_exams'.tr,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
          ),
          leading: Obx(() {
            final notificationController = Get.find<NotificationController>();
            final count = notificationController.unreadNotificationsCount.value;
            return Badge(
              label: Text('$count'),
              isLabelVisible: count > 0,
              child: IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  notificationController.markNotificationsAsSeen();
                  Get.to(() => const ExaminerNotificationsScreen());
                },
              ),
            );
          }),
        ),
        endDrawer: const ExaminerDrawer(),
        body: const FinalExamsScreen(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (Get.isRegistered<FinalExamsController>()) {
              Get.find<FinalExamsController>().saveExamData();
            }
          },
          backgroundColor: Colors.indigo,
          icon: const Icon(Icons.save_outlined, color: Colors.white),
          label: Text(
            'save'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}


