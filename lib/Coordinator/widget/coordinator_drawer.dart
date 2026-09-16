import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/profile_controller.dart';
import '../../Teacher/controller/settings_controller.dart';
import '../../Student/pages/financial_support_page.dart'; // استيراد صفحة دعم المقرأة
// import '../../../Auth/routing/auth_route.dart';

class CoordinatorDrawer extends StatelessWidget {
  const CoordinatorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.put(ProfileController());
    final settingsController = Get.put(SettingsController());

    return Drawer(
      child: Column(
        children: [
          Obx(() {
            final hasAvatar = profileController.avatarUrl.value.isNotEmpty;
            return UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                image: hasAvatar
                    ? DecorationImage(
                        image: NetworkImage(profileController.avatarUrl.value),
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
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                        ],
                      )
                    : null,
              ),
              accountName: Text(
                profileController.name.value.isEmpty
                    ? 'coordinator_label'.tr
                    : profileController.name.value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Cairo',
                ),
              ),
              accountEmail: Text(
                profileController.email.value,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            );
          }),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'profile'.tr,
                  onTap: () {
                    Get.back();
                    Get.toNamed('/coordinator/profile');
                  },
                ),

                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'settings'.tr,
                  onTap: () {
                    Get.back();
                    Get.toNamed('/coordinator/settings');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.support_agent_rounded,
                  title: 'tech_support'.tr,
                  onTap: () {
                    Get.back();
                    Get.toNamed('/tech_support');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.favorite_border_rounded,
                  title: 'financial_support'.tr,
                  onTap: () {
                    Get.back();
                    Get.to(() => FinancialSupportPage());
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'logout'.tr,
            color: Colors.red,
            onTap: () => _confirmLogout(settingsController),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.indigo),
      title: Text(
        title,
        style: TextStyle(color: color, fontFamily: 'Cairo'),
      ),
      onTap: onTap,
    );
  }

  void _confirmLogout(SettingsController controller) {
    Get.defaultDialog(
      title: 'logout'.tr,
      middleText: 'confirm_logout_msg'.tr,
      textConfirm: 'yes'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.logout();
      },
      titleStyle: const TextStyle(fontFamily: 'Cairo'),
      middleTextStyle: const TextStyle(fontFamily: 'Cairo'),
    );
  }
}
