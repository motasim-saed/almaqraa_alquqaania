import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:glaze_nav_bar/glaze_nav_bar.dart';
import 'package:al_maqraa/Teacher/controller/homepage_teacher_controller.dart';
import 'package:al_maqraa/Teacher/widget/teacher_drawer.dart';
import 'package:al_maqraa/components/app_exit_wrapper.dart';
import 'package:al_maqraa/core/controllers/notification_controller.dart';
import 'package:al_maqraa/core/services/showcase_service.dart';
import 'package:al_maqraa/core/widgets/custom_showcase.dart';

class HomepageTeacher extends StatefulWidget {
  const HomepageTeacher({super.key});

  @override
  State<HomepageTeacher> createState() => _HomepageTeacherState();
}

class _HomepageTeacherState extends State<HomepageTeacher> {
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _drawerKey = GlobalKey();
  final GlobalKey _monitoringKey = GlobalKey();
  final GlobalKey _quranKey = GlobalKey();
  final GlobalKey _tajweedKey = GlobalKey();
  
  bool _showcaseStarted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final HomepageTeacherController controller = Get.put(
      HomepageTeacherController(),
    );

    return ShowCaseWidget(
      onFinish: () {
        Get.find<ShowcaseService>().markShowcaseAsSeen('teacher');
      },
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final showcaseService = Get.find<ShowcaseService>();
          if (!showcaseService.hasSeenShowcase('teacher') && !_showcaseStarted) {
            _showcaseStarted = true;
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                ShowCaseWidget.of(context).startShowCase([
                  _notificationsKey,
                  _drawerKey,
                  _monitoringKey,
                  _quranKey,
                  _tajweedKey,
                ]);
              }
            });
          }
        });

        return AppExitWrapper(
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
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
              elevation: 0,
              leading: Obx(() {
                final notificationController =
                    Get.find<NotificationController>();
                final count =
                    notificationController.unreadNotificationsCount.value;
                return CustomShowcase(
                  showcaseKey: _notificationsKey,
                  title: 'showcase_teacher_notifications_title'.tr,
                  description: 'showcase_teacher_notifications_desc'.tr,
                  child: Badge(
                    label: Text('$count'),
                    isLabelVisible: count > 0,
                    backgroundColor: colorScheme.error,
                    child: IconButton(
                      onPressed: () {
                        notificationController.markNotificationsAsSeen();
                        Get.toNamed('/teacherNotifications');
                      },
                      icon: const Icon(Icons.notifications_active_outlined),
                    ),
                  ),
                );
              }),
              actions: [
                Builder(
                  builder: (context) {
                    return CustomShowcase(
                      showcaseKey: _drawerKey,
                      title: 'showcase_teacher_drawer_title'.tr,
                      description: 'showcase_teacher_drawer_desc'.tr,
                      child: IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        tooltip: 'menu'.tr,
                      ),
                    );
                  },
                ),
              ],
            ),
            endDrawer: const TeacherDrawer(),
            body: PageView(
              controller: controller.pageController,
              onPageChanged: (index) => controller.onPageChanged(index),
              children: controller.screens,
            ),
            bottomNavigationBar: Stack(
              clipBehavior: Clip.none,
              children: [
                Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: GlazeNavBar(
                      index: controller.selectedIndex.value,
                      items: [
                        GlazeNavBarItem(
                          child: const Icon(Icons.calendar_today_outlined),
                          label: 'student_monitoring'.tr,
                        ),
                        GlazeNavBarItem(
                          child: const Icon(Icons.menu_book),
                          label: 'quran'.tr,
                        ),
                        GlazeNavBarItem(
                          child: const Icon(Icons.library_books),
                          label: 'tajweed_lessons'.tr,
                        ),
                      ],
                      onTap: (index) => controller.onItemTapped(index),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                const Color(0xFF334155),
                                const Color(0xFF1E293B),
                              ]
                            : [
                                const Color.fromARGB(255, 69, 102, 135),
                                const Color.fromARGB(255, 112, 161, 209),
                              ],
                      ),
                      buttonGradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.primary],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomShowcase(
                            showcaseKey: _monitoringKey,
                            title: 'showcase_teacher_monitoring_title'.tr,
                            description: 'showcase_teacher_monitoring_desc'.tr,
                            child: const SizedBox(height: 60),
                          ),
                        ),
                        Expanded(
                          child: CustomShowcase(
                            showcaseKey: _quranKey,
                            title: 'showcase_teacher_quran_title'.tr,
                            description: 'showcase_teacher_quran_desc'.tr,
                            child: const SizedBox(height: 60),
                          ),
                        ),
                        Expanded(
                          child: CustomShowcase(
                            showcaseKey: _tajweedKey,
                            title: 'showcase_teacher_tajweed_title'.tr,
                            description: 'showcase_teacher_tajweed_desc'.tr,
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
