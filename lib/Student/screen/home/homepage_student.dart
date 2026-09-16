import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:glaze_nav_bar/glaze_nav_bar.dart';
import 'package:al_maqraa/Student/controller/homepage_student_controller.dart';
import 'package:al_maqraa/Student/widget/student_drawer.dart';
import 'package:al_maqraa/Student/routing/student_route.dart';
import 'package:al_maqraa/core/controllers/notification_controller.dart'; // استيراد متحكم الإشعارات
import 'package:al_maqraa/components/app_exit_wrapper.dart'; // استيراد ويدجت الخروج المشتركة
import 'package:al_maqraa/core/services/showcase_service.dart';
import 'package:al_maqraa/core/widgets/custom_showcase.dart';

class HomepageStudent extends StatefulWidget {
  const HomepageStudent({super.key});

  @override
  State<HomepageStudent> createState() => _HomepageStudentState();
}

class _HomepageStudentState extends State<HomepageStudent> {
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _drawerKey = GlobalKey();
  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _quranKey = GlobalKey();
  final GlobalKey _tajweedKey = GlobalKey();
  
  bool _showcaseStarted = false;

  @override
  Widget build(BuildContext context) {
    final HomepageStudentController controller =
        Get.find<HomepageStudentController>();

    return ShowCaseWidget(
      onFinish: () {
        Get.find<ShowcaseService>().markShowcaseAsSeen('student');
      },
      // تفعيل خصائص التنقل لضمان عدم توقف الدليل
      blurValue: 1,
      autoPlay: false,
      enableAutoScroll: true,
      disableBarrierInteraction: false, // السماح بالنقر خارج المنطقة المحددة للانتقال
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final showcaseService = Get.find<ShowcaseService>();
          if (!showcaseService.hasSeenShowcase('student') && !_showcaseStarted) {
            _showcaseStarted = true;
            // زيادة التأخير قليلاً للتأكد من أن جميع العناصر (خاصة شريط التنقل) قد رُسمت
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                ShowCaseWidget.of(context).startShowCase([
                  _notificationsKey,
                  _drawerKey,
                  _progressKey,
                  _quranKey,
                  _tajweedKey,
                ]);
              }
            });
          }
        });

        return AppExitWrapper(
          child: Scaffold(
            appBar: AppBar(
              title: Obx(
                () => Text(
                  controller.getAppBarTitle().tr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              centerTitle: true,
              leading: CustomShowcase(
                showcaseKey: _notificationsKey,
                title: 'showcase_student_notifications_title'.tr,
                description: 'showcase_student_notifications_desc'.tr,
                child: Obx(() {
                  final notificationController =
                      Get.find<NotificationController>();
                  final count =
                      notificationController.unreadNotificationsCount.value;
                  return Badge(
                    label: Text('$count'),
                    isLabelVisible: count > 0,
                    child: IconButton(
                      onPressed: () {
                        notificationController.markNotificationsAsSeen();
                        Get.toNamed(StudentRoutes.notifications);
                      },
                      icon: const Icon(Icons.notifications_active_outlined),
                      tooltip: 'notifications'.tr,
                    ),
                  );
                }),
              ),
              actions: [
                CustomShowcase(
                  showcaseKey: _drawerKey,
                  title: 'showcase_student_drawer_title'.tr,
                  description: 'showcase_student_drawer_desc'.tr,
                  child: Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        tooltip: 'menu'.tr,
                      );
                    },
                  ),
                ),
              ],
            ),

            endDrawer: const StudentDrawer(),

            body: PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: controller.screens,
            ),

            bottomNavigationBar: Stack(
              clipBehavior: Clip.none,
              children: [
                Obx(
                  () => GlazeNavBar(
                    index: controller.selectedIndex.value,
                    items: [
                      GlazeNavBarItem(
                        child: const Icon(Icons.assignment_outlined),
                        label: 'progress'.tr,
                      ),
                      GlazeNavBarItem(
                        child: const Icon(Icons.menu_book),
                        label: 'quran'.tr,
                      ),
                      GlazeNavBarItem(
                        child: const Icon(Icons.library_books),
                        label: 'tajweed'.tr,
                      ),
                    ],
                  onTap: (index) => controller.onItemTapped(index),

                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.8),
                      Theme.of(context).colorScheme.primary,
                    ],
                  ),
                  buttonGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.primary,
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomShowcase(
                          showcaseKey: _progressKey,
                          title: 'showcase_student_progress_title'.tr,
                          description: 'showcase_student_progress_desc'.tr,
                          child: const SizedBox(height: 60),
                        ),
                      ),
                      Expanded(
                        child: CustomShowcase(
                          showcaseKey: _quranKey,
                          title: 'showcase_student_quran_title'.tr,
                          description: 'showcase_student_quran_desc'.tr,
                          child: const SizedBox(height: 60),
                        ),
                      ),
                      Expanded(
                        child: CustomShowcase(
                          showcaseKey: _tajweedKey,
                          title: 'showcase_student_tajweed_title'.tr,
                          description: 'showcase_student_tajweed_desc'.tr,
                          child: const SizedBox(height: 60),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}
