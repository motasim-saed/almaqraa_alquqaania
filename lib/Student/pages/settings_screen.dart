import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Teacher/controller/settings_controller.dart';
import 'package:al_maqraa/core/services/showcase_service.dart';

/// شاشة إعدادات الطالب
/// تتيح للطالب التحكم في اللغة، المظهر (الوضع الليلي)، التنبيهات، والأمان (البصمة)
class StudentSettingsScreen extends StatelessWidget {
  const StudentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr), centerTitle: true),
      body: GetBuilder<SettingsController>(
        // نستخدم متحكم الإعدادات العام لإدارة حالة التطبيق (اللغة والمظهر)
        init: SettingsController(),
        builder: (controller) {
          return SingleChildScrollView(
            // أضفت SingleChildScrollView لتجنب مشاكل تجاوز الشاشة
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // قسم اختيار اللغة
                Text(
                  'language'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Get.isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      // خيار اللغة العربية
                      _buildLanguageOption(
                        context,
                        controller,
                        title: 'arabic'.tr,
                        langCode: 'ar',
                        countryCode: 'SA',
                        iconPath: '🇸🇦',
                      ),
                      Divider(
                        height: 1,
                        color: Theme.of(context).dividerColor.withValues(alpha:0.1),
                      ),
                      // خيار اللغة الإنجليزية
                      _buildLanguageOption(
                        context,
                        controller,
                        title: 'english'.tr,
                        langCode: 'en',
                        countryCode: 'US',
                        iconPath: '🇺🇸',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // قسم مظهر التطبيق
                Text(
                  'appearance'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Get.isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                  ),
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.dark_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text('dark_mode_setting'.tr),
                    value: controller.isDarkMode,
                    onChanged: (val) => controller.toggleTheme(),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                // قسم التنبيهات
                Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Get.isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.transparent,
                      ),
                    ),
                    child: SwitchListTile(
                      secondary: Icon(
                        Icons.notifications_active_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text('notifications'.tr),
                      subtitle: Text('enable_chat_notifications'.tr),
                      value: controller.isNotificationsEnabled.value,
                      onChanged: (val) => controller.toggleNotifications(val),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                // قسم الأمان
                Text(
                  'security'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Get.isDarkMode
                            ? Colors.white
                            : Colors.transparent,
                      ),
                    ),
                    child: SwitchListTile(
                      secondary: Icon(
                        Icons.fingerprint,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text('biometric_login'.tr),
                      value: controller.isBiometricEnabled.value,
                      onChanged: controller.isBiometricSupported.value
                          ? (val) => controller.toggleBiometrics(val)
                          : null,
                      subtitle: !controller.isBiometricSupported.value
                          ? Text('not_supported_on_device'.tr)
                          : null,
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  /// دالة لبناء خيار اختيار اللغة مع أيقونة العلم وحالة الاختيار
  Widget _buildLanguageOption(
    BuildContext context,
    SettingsController controller, {
    required String title,
    required String langCode,
    required String countryCode,
    required String iconPath,
  }) {
    bool isSelected = controller.currentLocale.languageCode == langCode;

    return ListTile(
      leading: Text(iconPath, style: const TextStyle(fontSize: 24)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : Icon(
              Icons.circle_outlined,
              color: Theme.of(context).hintColor.withValues(alpha: 0.3),
            ),
      onTap: () {
        controller.changeLanguage(langCode, countryCode);
      },
    );
  }
}
