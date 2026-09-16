import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/settings_controller.dart';
import 'package:al_maqraa/core/services/showcase_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr), // عنوان الشاشة معرب
        centerTitle: true,
      ),
      // استخدام GetBuilder لمتابعة تغييرات الإعدادات وتحديث الواجهة
      body: GetBuilder<SettingsController>(
        init: SettingsController(),
        builder: (controller) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                // قسم اختيار اللغة
                Text(
                  'language'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'change_language_msg'.tr,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      // خيار اللغة العربية
                      _buildLanguageOption(
                        controller,
                        title: 'arabic'.tr,
                        langCode: 'ar',
                        countryCode: 'SA',
                        iconPath: '🇸🇦',
                      ),
                      const Divider(height: 1),
                      // خيار اللغة الإنجليزية
                      _buildLanguageOption(
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
                // قسم مظهر التطبيق (الوضع الليلي)
                Text(
                  'appearance'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(
                      Icons.dark_mode,
                      color: Colors.indigo,
                    ),
                    title: Text('dark_mode'.tr),
                    value: controller.isDarkMode,
                    onChanged: (val) => controller.toggleTheme(),
                    activeColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                // قسم الإشعارات
                Obx(
                  () => Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.orange,
                      ),
                      title: Text('notifications'.tr),
                      subtitle: Text('enable_chat_notifications'.tr),
                      value: controller.isNotificationsEnabled.value,
                      onChanged: (val) => controller.toggleNotifications(val),
                      activeColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // قسم الأمان (تسجيل الدخول بالبصمة)
                Text(
                  'security'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SwitchListTile(
                      secondary: const Icon(
                        Icons.fingerprint,
                        color: Colors.green,
                      ),
                      title: Text('biometric_login'.tr),
                      value: controller.isBiometricEnabled.value,
                      onChanged: controller.isBiometricSupported.value
                          ? (val) => controller.toggleBiometrics(val)
                          : null,
                      subtitle: !controller.isBiometricSupported.value
                          ? Text('not_supported_on_device'.tr)
                          : null,
                      activeColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                const SizedBox(height: 30),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption(
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
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        controller.changeLanguage(langCode, countryCode);
      },
    );
  }
}
