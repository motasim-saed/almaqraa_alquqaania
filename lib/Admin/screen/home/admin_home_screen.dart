import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهات المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../controller/home/admin_home_controller.dart'; // استيراد متحكم الصفحة الرئيسية للأدمن
import '../../controller/admin_layout_controller.dart'; // استيراد متحكم تخطيط صفحة الأدمن

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminHomeController>();
    final layoutController = Get.find<AdminLayoutController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return RefreshIndicator(
          onRefresh: () => controller.refreshData(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 3;
              double aspectRatio = 2.2;

              if (width < 1100) {
                crossAxisCount = 2;
                aspectRatio = 2.4;
              } else if (width < 1400) {
                crossAxisCount = 3;
                aspectRatio = 2.1;
              } else {
                crossAxisCount = 4; // زيادة عدد الأعمدة للشاشات الواسعة جداً
                aspectRatio = 2.0;
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 20),
                      child: Center(
                        child: Text(
                          'dashboard_overview'.tr,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      delegate: SliverChildListDelegate([
                        // --- بطاقة المتقدمين الجدد من المعلمين ---
                        _buildAdminCard(
                          context,
                          title: 'teacher_applicants'.tr,
                          icon: Icons.person_add_alt_1_rounded,
                          color: Colors.orange,
                          count: controller.stats.teacherApplicants,
                          onTap: () => layoutController.changeIndex(1),
                          isProminent: true,
                        ),
                        // --- بطاقة المتقدمين الجدد من الطلاب ---
                        _buildAdminCard(
                          context,
                          title: 'student_applicants'.tr,
                          icon: Icons.school_rounded,
                          color: Colors.blue,
                          count: controller.stats.studentApplicants,
                          onTap: () => layoutController.changeIndex(2),
                          isProminent: true,
                        ),
                        // --- بطاقة المعلمين المقبولين (ذكور) ---
                        _buildAdminCard(
                          context,
                          title: 'male_teachers'.tr,
                          icon: Icons.how_to_reg_rounded,
                          color: Colors.teal,
                          count: controller.accTeachersCtrl.maleCount,
                          onTap: () => layoutController.changeIndex(4),
                        ),
                        // --- بطاقة المعلمات المقبولات (إناث) ---
                        _buildAdminCard(
                          context,
                          title: 'female_teachers'.tr,
                          icon: Icons.how_to_reg_outlined,
                          color: Colors.pink,
                          count: controller.accTeachersCtrl.femaleCount,
                          onTap: () => layoutController.changeIndex(13),
                        ),
                        // --- بطاقة الطلاب المقبولين (ذكور) ---
                        _buildAdminCard(
                          context,
                          title: 'male_students'.tr,
                          icon: Icons.groups_rounded,
                          color: Colors.indigo,
                          count: controller.accStudentsCtrl.maleCount,
                          onTap: () => layoutController.changeIndex(5),
                        ),
                        // --- بطاقة الطالبات المقبولات (إناث) ---
                        _buildAdminCard(
                          context,
                          title: 'female_students'.tr,
                          icon: Icons.groups_3_rounded,
                          color: Colors.purple,
                          count: controller.accStudentsCtrl.femaleCount,
                          onTap: () => layoutController.changeIndex(14),
                        ),
                        // --- بطاقة إدارة حلقات القرآن الكريم ---
                        _buildAdminCard(
                          context,
                          title: 'quran_circles'.tr,
                          icon: Icons.grid_view_rounded,
                          color: Colors.green,
                          count: controller.stats.totalCircles,
                          onTap: () => layoutController.changeIndex(3),
                        ),
                        // --- بطاقة إدارة المديرين والمنسقين (إدارة الإدارة) ---
                        _buildAdminCard(
                          context,
                          title: 'manage_management_users'.tr,
                          icon: Icons.admin_panel_settings_rounded,
                          color: Colors.blueGrey,
                          count: 0,
                          onTap: () => layoutController.changeIndex(16),
                          isProminent: true,
                        ),
                        // --- بطاقة الدعم المادي ---
                        _buildAdminCard(
                          context,
                          title: 'financial_support_mgmt'.tr,
                          icon: Icons.payments_rounded,
                          color: Colors.lightGreen,
                          count: 0,
                          onTap: () => layoutController.changeIndex(17),
                          isProminent: true,
                        ),
                        // --- بطاقة إدارة الإجازات والعطلات ---
                        _buildAdminCard(
                          context,
                          title: 'holiday_management'.tr,
                          icon: Icons.event_available_rounded,
                          color: Colors.cyan,
                          count: 0,
                          onTap: () => layoutController.changeIndex(11),
                        ),
                        // --- بطاقة طلبات الاستئذان ---
                        _buildAdminCard(
                          context,
                          title: 'grant_leave_title'.tr,
                          icon: Icons.assignment_turned_in_rounded,
                          color: Colors.deepOrange,
                          count: 0,
                          onTap: () => layoutController.changeIndex(12),
                        ),
                        // --- بطاقة إرسال الإشعارات ---
                        _buildAdminCard(
                          context,
                          title: 'send_notification'.tr,
                          icon: Icons.campaign_rounded,
                          color: Colors.amber.shade800,
                          count: 0,
                          onTap: () => layoutController.changeIndex(10),
                        ),
                        // --- بطاقة التقارير الإحصائية ---
                        _buildAdminCard(
                          context,
                          title: 'reports'.tr,
                          icon: Icons.analytics_rounded,
                          color: Colors.redAccent,
                          count: 0,
                          onTap: () => layoutController.changeIndex(6),
                        ),
                        // --- بطاقة إدارة الشهادات ---
                        _buildAdminCard(
                          context,
                          title: 'certificates'.tr,
                          icon: Icons.card_membership_rounded,
                          color: Colors.blueGrey,
                          count: 0,
                          onTap: () => layoutController.changeIndex(9),
                        ),
                      ]),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
    bool isProminent = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isProminent 
              ? color.withValues(alpha: isDarkMode ? 0.6 : 0.4) 
              : (isDarkMode ? Colors.white.withValues(alpha: 0.1) : color.withValues(alpha: 0.2)),
          width: isProminent ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isProminent ? FontWeight.w900 : FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (count > 0)
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: count),
                          duration: const Duration(milliseconds: 1200),
                          builder: (context, value, child) {
                            return Text(
                              value.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            );
                          },
                        )
                      else
                        const Icon(Icons.arrow_outward_rounded, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
