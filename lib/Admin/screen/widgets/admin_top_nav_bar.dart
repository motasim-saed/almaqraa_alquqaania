import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/admin_layout_controller.dart';

class AdminTopNavigationBar extends StatelessWidget {
  const AdminTopNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminLayoutController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.indigo.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildLogo(isDark),
                const SizedBox(width: 30),
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'home'.tr, controller, isDark),
                _buildDivider(isDark),
                _buildNavItem(1, Icons.person_add_outlined, Icons.person_add, 'teacher_applicants'.tr, controller, isDark),
                _buildNavItem(2, Icons.school_outlined, Icons.school, 'student_applicants'.tr, controller, isDark),
                _buildDivider(isDark),
                _buildNavItem(4, Icons.how_to_reg_outlined, Icons.how_to_reg, 'male_teachers'.tr, controller, isDark),
                _buildNavItem(13, Icons.how_to_reg, Icons.how_to_reg, 'female_teachers'.tr, controller, isDark),
                const SizedBox(width: 10),
                _buildNavItem(5, Icons.groups_outlined, Icons.groups, 'male_students'.tr, controller, isDark),
                _buildNavItem(14, Icons.groups_3_outlined, Icons.groups_3, 'female_students'.tr, controller, isDark),
                _buildDivider(isDark),
                _buildNavItem(3, Icons.grid_view_outlined, Icons.grid_view_rounded, 'quran_circles'.tr, controller, isDark),
                _buildNavItem(8, Icons.fact_check_outlined, Icons.fact_check, 'exam_committee'.tr, controller, isDark),
                _buildNavItem(6, Icons.analytics_outlined, Icons.analytics, 'reports'.tr, controller, isDark),
                _buildNavItem(9, Icons.card_membership_outlined, Icons.card_membership, 'certificates'.tr, controller, isDark),
                _buildDivider(isDark),
                _buildNavItem(11, Icons.event_available_outlined, Icons.event_available, 'holiday_management'.tr, controller, isDark),
                _buildNavItem(12, Icons.assignment_turned_in_outlined, Icons.assignment_turned_in, 'grant_leave_title'.tr, controller, isDark),
                _buildNavItem(10, Icons.campaign_outlined, Icons.campaign, 'send_notification'.tr, controller, isDark),
                _buildNavItem(16, Icons.manage_accounts_outlined, Icons.manage_accounts, 'manage_management_users'.tr, controller, isDark),

                _buildNavItem(17, Icons.payments_outlined, Icons.payments, 'financial_support_mgmt'.tr, controller, isDark),
                const SizedBox(width: 12),
                // إضافة زر الصيانة هنا
                _buildNavItem(18, Icons.cleaning_services_outlined, Icons.cleaning_services, 'الصيانة والتخزين', controller, isDark),
                _buildNavItem(7, Icons.settings_outlined, Icons.settings, 'settings'.tr, controller, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Row(
      children: [
        Icon(Icons.admin_panel_settings, color: isDark ? Colors.indigoAccent : Colors.white, size: 28),
        const SizedBox(width: 10),
        Text(
          'admin_panel'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return VerticalDivider(width: 20, indent: 20, endIndent: 20, color: isDark ? Colors.white12 : Colors.white24);
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, AdminLayoutController controller, bool isDark) {
    return Obx(() {
      final isSelected = controller.currentIndex == index;
      final selectedColor = isDark ? Colors.indigoAccent : Colors.white;
      final unselectedColor = isDark ? Colors.white54 : Colors.white70;

      return InkWell(
        onTap: () => controller.changeIndex(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? Colors.indigo.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.15)) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 22,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedColor : unselectedColor,
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
