import 'package:al_maqraa/Student/routing/student_route.dart';
import 'package:flutter/material.dart';
import 'package:al_maqraa/Student/repository/supabase_student_repository.dart';
import 'package:al_maqraa/Student/pages/chat_screen.dart';
import 'package:al_maqraa/Student/pages/circle_supervisor_screen.dart';
import 'package:get/get.dart';
import '../../Teacher/controller/settings_controller.dart';
import 'package:al_maqraa/core/controllers/profile_controller.dart';
import 'package:al_maqraa/core/controllers/notification_controller.dart'; 
import '../pages/financial_support_page.dart'; 

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.put(SettingsController());
    final profileController = Get.put(ProfileController());

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(() {
            final controller = profileController;
            final hasAvatar = controller.avatarUrl.value.isNotEmpty;

            return UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                image: hasAvatar
                    ? DecorationImage(
                        image: NetworkImage(controller.avatarUrl.value),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.4),
                          BlendMode.darken,
                        ),
                      )
                    : null,
                gradient: !hasAvatar
                    ? LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      )
                    : null,
              ),
              accountName: Text(
                controller.isLoading.value
                    ? 'loading'.tr
                    : controller.name.value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Cairo',
                ),
              ),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.email.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  if (controller.circleName.isNotEmpty)
                    Text(
                      '${'circle_label'.tr}: ${controller.circleName.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                ],
              ),
            );
          }),
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'profile'.tr,
            subtitle: 'profile_subtitle'.tr,
            color: Colors.blue,
            onTap: () => Get.toNamed(StudentRoutes.profile),
          ),
          Obx(() {
            if (!profileController.isSupervisor.value) {
              return const SizedBox.shrink();
            }
            return _buildDrawerItem(
              icon: Icons.supervisor_account_rounded,
              title: 'متابعة طلاب الحلقة',
              subtitle: 'متابعة ومراجعة إنجازات زملاء الحلقة',
              color: Colors.teal,
              onTap: () => Get.to(() => const CircleSupervisorScreen()),
            );
          }),
          _buildDrawerItem(
            icon: Icons.analytics_outlined,
            title: 'my_grades'.tr,
            subtitle: 'my_grades_subtitle'.tr,
            color: Colors.amber.shade700,
            onTap: () => Get.toNamed(StudentRoutes.grades),
          ),
          _buildDrawerItem(
            icon: Icons.add_task,
            title: 'add_plans'.tr,
            subtitle: 'add_plans_subtitle'.tr,
            color: Colors.green,
            onTap: () => Get.toNamed(StudentRoutes.plans),
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'settings'.tr,
            subtitle: 'settings_subtitle'.tr,
            color: Colors.grey,
            onTap: () => Get.toNamed(StudentRoutes.settings),
          ),
          Obx(() {
            final notificationController = Get.find<NotificationController>();
            final count = notificationController.unreadCount.value;

            return _buildDrawerItem(
              icon: Icons.mark_chat_unread_sharp,
              title: 'contact_admin'.tr,
              subtitle: 'contact_admin_subtitle'.tr,
              color: Colors.purple,
              trailing: count > 0
                  ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () async {
                Get.back(closeOverlays: false);
                final adminData =
                    await SupabaseStudentRepository().getFirstAdmin();
                if (adminData != null) {
                  Get.to(
                    () => ChatScreen(
                      otherUserId: adminData['id'].toString(),
                      otherUserName:
                          adminData['full_name'] ??
                          adminData['email'] ??
                          'role_admin'.tr,
                      otherUserRole: adminData['role'] ?? 'admin',
                    ),
                  );
                } else {
                  Get.snackbar('error'.tr, 'no_admin_found'.tr);
                }
              },
            );
          }),
          _buildDrawerItem(
            icon: Icons.favorite_border_rounded,
            title: 'financial_support'.tr,
            subtitle: 'financial_support_subtitle'.tr,
            color: Colors.pink,
            onTap: () => Get.to(() => FinancialSupportPage()),
          ),
          _buildDrawerItem(
            icon: Icons.support_agent_rounded,
            title: 'tech_support'.tr,
            subtitle: 'tech_support_details'.tr,
            color: Colors.teal,
            onTap: () => Get.toNamed('/tech_support'),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'logout'.tr,
            subtitle: 'logout_subtitle'.tr,
            color: Colors.orange,
            onTap: () => _confirmAction(
              title: 'logout'.tr,
              message: 'confirm_logout_msg'.tr,
              onConfirm: () => settingsController.logout(),
              confirmColor: Colors.orange,
            ),
          ),
          _buildDrawerItem(
            icon: Icons.delete_forever,
            title: 'delete_account'.tr,
            subtitle: 'delete_account_subtitle'.tr,
            color: Colors.red,
            onTap: () => _confirmAction(
              title: 'delete_account'.tr,
              message: 'delete_account_confirm_msg'.tr,
              onConfirm: () => settingsController.deleteAccount(),
              confirmColor: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Cairo',
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: Colors.grey,
              ),
            )
          : null,
      trailing: trailing,
      onTap: () {
        Get.back(closeOverlays: false);
        onTap();
      },
    );
  }

  void _confirmAction({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required Color confirmColor,
  }) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: 'yes'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: confirmColor,
      onConfirm: () {
        Get.back();
        onConfirm();
      },
      titleStyle: const TextStyle(fontFamily: 'Cairo'),
      middleTextStyle: const TextStyle(fontFamily: 'Cairo'),
    );
  }
}
