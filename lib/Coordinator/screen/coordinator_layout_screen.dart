import 'package:glaze_nav_bar/glaze_nav_bar.dart'; 
import 'package:flutter/material.dart'; 
import 'package:get/get.dart'; 
import 'package:showcaseview/showcaseview.dart';
import '../../Admin/screen/communications/admin_inbox_screen.dart'; 
import '../../Admin/controller/chat_controller.dart'; 
import '../controller/coordinator_layout_controller.dart'; 
import '../widget/coordinator_drawer.dart'; 
import 'coordinator_stats_screen.dart'; 
import 'package:al_maqraa/components/app_exit_wrapper.dart'; 
import '../../core/controllers/global_batch_controller.dart'; 
import 'package:al_maqraa/core/services/showcase_service.dart';
import 'package:al_maqraa/core/widgets/custom_showcase.dart';

class CoordinatorLayoutScreen extends StatefulWidget {
  const CoordinatorLayoutScreen({super.key});

  @override
  State<CoordinatorLayoutScreen> createState() =>
      _CoordinatorLayoutScreenState();
}

class _CoordinatorLayoutScreenState extends State<CoordinatorLayoutScreen> {
  late PageController _pageController; 
  final CoordinatorLayoutController controller = Get.put(
    CoordinatorLayoutController(),
  );

  final GlobalKey _batchFilterKey = GlobalKey();
  final GlobalKey _drawerKey = GlobalKey();
  
  final GlobalKey _statsTabKey = GlobalKey();
  final GlobalKey _studentChatsTabKey = GlobalKey();
  final GlobalKey _teacherChatsTabKey = GlobalKey();
  
  bool _showcaseStarted = false;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      initialPage: controller.currentIndex.value,
    );

    ever(controller.currentIndex, (int index) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    if (!Get.isRegistered<AdminChatController>(tag: 'teacher')) {
      Get.lazyPut(() => AdminChatController(), tag: 'teacher');
    }
    if (!Get.isRegistered<AdminChatController>(tag: 'student')) {
      Get.lazyPut(() => AdminChatController(), tag: 'student');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    controller.changeIndex(index);
  }

  void _onNavBarTap(int index) {
    controller.changeIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      const CoordinatorStatsScreen(),
      const AdminInboxScreen(roleFilter: 'student'),
      const AdminInboxScreen(roleFilter: 'teacher'),
    ];

    return ShowCaseWidget(
      onFinish: () {
        Get.find<ShowcaseService>().markShowcaseAsSeen('coordinator');
      },
      blurValue: 1,
      autoPlay: false,
      enableAutoScroll: true,
      disableBarrierInteraction: false,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final showcaseService = Get.find<ShowcaseService>();
          if (!showcaseService.hasSeenShowcase('coordinator') && !_showcaseStarted) {
            _showcaseStarted = true;
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) {
                ShowCaseWidget.of(context).startShowCase([
                  _drawerKey,      
                  _batchFilterKey, 
                  _statsTabKey,
                  _studentChatsTabKey,
                  _teacherChatsTabKey,
                ]);
              }
            });
          }
        });

        return AppExitWrapper(
          child: Scaffold(
            drawer: const CoordinatorDrawer(),
            appBar: AppBar(
              elevation: 0,
              centerTitle: true,
              leading: Builder(
                builder: (context) {
                  return CustomShowcase(
                    showcaseKey: _drawerKey,
                    title: 'القائمة الجانبية',
                    description: 'تجد هنا الإعدادات الشخصية وتنبيهات النظام.',
                    child: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  );
                },
              ),
              title: Obx(() {
                if (controller.isSearching.value) {
                  return TextField(
                    controller: controller.searchController,
                    autofocus: true,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'search'.tr,
                      hintStyle: TextStyle(color: colorScheme.onSurface),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => controller.updateSearchQuery(value),
                  );
                }
                return Text(
                  controller.currentTitle.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontFamily: 'Cairo',
                  ),
                );
              }),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: CustomShowcase(
                  showcaseKey: _batchFilterKey,
                  title: 'فلتر الدفعات',
                  description: 'يمكنك تصفية البيانات والنتائج حسب دفعة معينة.',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: _buildBatchFilter(controller),
                  ),
                ),
              ),
            ),
            body: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: screens,
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
                      index: controller.currentIndex.value,
                      items: [
                        GlazeNavBarItem(
                          child: const Icon(Icons.analytics_outlined),
                          label: 'stats'.tr,
                        ),
                        GlazeNavBarItem(
                          child: Badge(
                            label: Text('${controller.studentUnreadCount}'),
                            isLabelVisible: controller.studentUnreadCount > 0,
                            backgroundColor: colorScheme.error,
                            child: const Icon(Icons.person_pin_outlined),
                          ),
                          label: 'student_chats'.tr,
                        ),
                        GlazeNavBarItem(
                          child: Badge(
                            label: Text('${controller.teacherUnreadCount}'),
                            isLabelVisible: controller.teacherUnreadCount > 0,
                            backgroundColor: colorScheme.error,
                            child: const Icon(
                              Icons.record_voice_over_outlined,
                            ),
                          ),
                          label: 'teacher_chats'.tr,
                        ),
                      ],
                      onTap: _onNavBarTap,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                const Color.fromARGB(255, 72, 82, 95),
                                const Color.fromARGB(255, 91, 96, 103),
                              ]
                            : [
                                const Color.fromARGB(255, 137, 140, 145),
                                const Color(0xFFCBD5E1),
                              ],
                      ),
                      buttonGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
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
                            showcaseKey: _statsTabKey,
                            title: 'الإحصائيات العامة',
                            description: 'هنا يمكنك متابعة إحصائيات الطلاب والمعلمين والحلقات بشكل شامل.',
                            child: const SizedBox(height: 60),
                          ),
                        ),
                        Expanded(
                          child: CustomShowcase(
                            showcaseKey: _studentChatsTabKey,
                            title: 'دردشة الطلاب',
                            description: 'تواصل مع الطلاب وتابع استفساراتهم. عند وجود رسائل جديدة، سيظهر تنبيه أحمر هنا.',
                            child: const SizedBox(height: 60),
                          ),
                        ),
                        Expanded(
                          child: CustomShowcase(
                            showcaseKey: _teacherChatsTabKey,
                            title: 'دردشة المعلمين',
                            description: 'تواصل مع المعلمين وتابع طلباتهم. سيظهر تنبيه هنا فور وصول رسالة جديدة من المعلمين.',
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

  Widget _buildBatchFilter(CoordinatorLayoutController controller) {
    final textColor = Theme.of(context).colorScheme.primary;
    
    return GetBuilder<GlobalBatchController>(
      init: GlobalBatchController(),
      builder: (batchCtrl) {
        return Obx(() {
          if (batchCtrl.isLoadingBatches.value) {
            return const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final isModified = batchCtrl.selectedBatch.value != batchCtrl.stagedBatch.value;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // زر التأكيد
              Container(
                decoration: BoxDecoration(
                  color: isModified ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.check_circle_rounded,
                    color: isModified ? Colors.green : Colors.grey.withValues(alpha: 0.4),
                    size: 24,
                  ),
                  onPressed: isModified ? () => batchCtrl.applyFilter() : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
              
              const SizedBox(width: 8),

              // القائمة المنسدلة
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: textColor.withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: batchCtrl.stagedBatch.value,
                    icon: Icon(
                      Icons.filter_list,
                      color: textColor,
                      size: 18,
                    ),
                    dropdownColor: Theme.of(context).cardColor,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'الجميع',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...batchCtrl.availableBatches.map((batchNum) {
                        return DropdownMenuItem<int?>(
                          value: batchNum,
                          child: Text(
                            'الدفعة $batchNum',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        );
                      }),
                    ],
                    onChanged: (newBatchId) {
                      batchCtrl.updateStagedBatch(newBatchId);
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // نص الفلترة
              const Text(
                'الفلترة على حسب الدفع',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );
        });
      },
    );
  }
}
