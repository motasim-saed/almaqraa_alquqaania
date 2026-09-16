import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:al_maqraa/core/widgets/custom_showcase.dart';
import '../controller/coordinator_layout_controller.dart';
import '../../Admin/screen/widgets/admin_stat_card.dart';
import 'coordinator_circles_screen.dart';
import '../../core/controllers/global_batch_controller.dart';
import '../../core/models/shared_models.dart';
import 'coordinator_send_notification_screen.dart';

class CoordinatorStatsScreen extends StatelessWidget {
  final GlobalKey? studentMessagesKey;
  final GlobalKey? teacherMessagesKey;

  const CoordinatorStatsScreen({
    super.key,
    this.studentMessagesKey,
    this.teacherMessagesKey,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CoordinatorLayoutController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isStatsLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.fetchStats,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildGenderFilters(context, controller),
              const SizedBox(height: 24),
              
              _buildSectionTitle(context, 'admission_system_new'.tr),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AdminStatCard(
                      title: 'student_applicants'.tr,
                      value: controller.stats.value.studentApplicants.toString(),
                      icon: Icons.person_add,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AdminStatCard(
                      title: 'teacher_applicants'.tr,
                      value: controller.stats.value.teacherApplicants.toString(),
                      icon: Icons.group_add,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'currently_enrolled'.tr),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AdminStatCard(
                      title: 'accepted_students'.tr,
                      value: controller.stats.value.acceptedStudents.toString(),
                      icon: Icons.how_to_reg,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AdminStatCard(
                      title: 'accepted_teachers'.tr,
                      value: controller.stats.value.acceptedTeachers.toString(),
                      icon: Icons.verified_user,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'followup_stats'.tr),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => controller.navigateToChats(1),
                        child: AdminStatCard(
                          title: controller.studentUnreadCount > 0 ? 'new_messages_title'.tr : 'students_messages'.tr,
                          value: controller.studentUnreadCount.toString(),
                          icon: Icons.chat_bubble_outline,
                          color: controller.studentUnreadCount > 0 ? Colors.redAccent : Colors.blueGrey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => controller.navigateToChats(2),
                        child: AdminStatCard(
                          title: controller.teacherUnreadCount > 0 ? 'new_messages_title'.tr : 'teachers_messages'.tr,
                          value: controller.teacherUnreadCount.toString(),
                          icon: Icons.forum_outlined,
                          color: controller.teacherUnreadCount > 0 ? Colors.redAccent : Colors.orange,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'circles_system'.tr),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Get.to(() => const CoordinatorCirclesScreen()),
                child: AdminStatCard(
                  title: 'total_circles'.tr,
                  value: controller.stats.value.totalCircles.toString(),
                  icon: Icons.grid_view_rounded,
                  color: Colors.indigo,
                ),
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'notifications_settings'.tr),
              const SizedBox(height: 16),
              
              // الزر المحدث ليكون بنفس أسلوب البطاقات ويدعم الثيمين
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Get.to(() => const CoordinatorSendNotificationScreen()),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.indigo.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.campaign_rounded, color: Color(0xFF4F46E5), size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'send_notification'.tr,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              'notification_hint_windows'.tr,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.grey[600] : const Color(0xFF4F46E5), size: 16),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: 'Cairo',
      ),
    );
  }

  Widget _buildGenderFilters(BuildContext context, CoordinatorLayoutController layoutController) {
    final globalBatchController = Get.isRegistered<GlobalBatchController>()
        ? Get.find<GlobalBatchController>()
        : Get.put(GlobalBatchController());
    
    return Row(
      children: [
        Expanded(
          child: _buildFilterCard(
            globalBatchController: globalBatchController,
            layoutController: layoutController,
            targetGender: Gender.all,
            title: 'all'.tr,
            icon: Icons.all_inclusive,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFilterCard(
            globalBatchController: globalBatchController,
            layoutController: layoutController,
            targetGender: Gender.male,
            title: 'boys'.tr,
            icon: Icons.male,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFilterCard(
            globalBatchController: globalBatchController,
            layoutController: layoutController,
            targetGender: Gender.female,
            title: 'girls'.tr,
            icon: Icons.female,
            color: Colors.pink,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterCard({
    required GlobalBatchController globalBatchController,
    required CoordinatorLayoutController layoutController,
    required Gender targetGender,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = globalBatchController.selectedGender.value == targetGender;
    return InkWell(
      onTap: () {
        globalBatchController.selectedGender.value = targetGender;
        globalBatchController.stagedGender.value = targetGender;
        layoutController.refreshData();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: color, width: 2) : Border.all(color: Colors.transparent, width: 2),
        ),
        child: AdminStatCard(
          title: title,
          value: '',
          icon: icon,
          color: isSelected ? color : Colors.grey,
          isSmall: true,
        ),
      ),
    );
  }
}
