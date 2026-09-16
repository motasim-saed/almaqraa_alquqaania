import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Teacher/controller/settings_controller.dart';

class CoordinatorSettingsScreen extends StatelessWidget {
  const CoordinatorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr), // عنوان الشاشة معرب (الإعدادات)
        centerTitle: true,
      ),
      // استخدام GetBuilder لإدارة حالة الإعدادات وتحديثها فورياً
      body: GetBuilder<SettingsController>(
        init: SettingsController(),
        builder: (controller) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // قسم المظهر (الوضع الليلي)
              _buildSectionTitle('appearance'.tr),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.dark_mode, color: Colors.indigo),
                  title: Text('dark_mode_setting'.tr), // خيار الوضع الليلي
                  value: controller.isDarkMode,
                  onChanged: (val) => controller.toggleTheme(),
                ),
              ),
              const SizedBox(height: 20),
              // قسم اللغة (العربية والإنجليزية)
              _buildSectionTitle('language'.tr),
              Card(
                child: Column(
                  children: [
                    // خيار اللغة العربية
                    _buildLanguageItem(
                      controller,
                      title: 'arabic'.tr,
                      code: 'ar',
                      country: 'SA',
                      icon: '🇸🇦',
                    ),
                    const Divider(height: 1),
                    // خيار اللغة الإنجليزية
                    _buildLanguageItem(
                      controller,
                      title: 'english'.tr,
                      code: 'en',
                      country: 'US',
                      icon: '🇺🇸',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // قسم الأمان (تسجيل الدخول بالبصمة)
              _buildSectionTitle('security'.tr),
              Card(
                child: Obx(() => SwitchListTile(
                  secondary: const Icon(Icons.fingerprint, color: Colors.green),
                  title: Text('biometric_login'.tr), // تفعيل البصمة
                  value: controller.isBiometricEnabled.value,
                  onChanged: controller.isBiometricSupported.value 
                      ? (val) => controller.toggleBiometrics(val) 
                      : null, // تعطيل الخيار إذا كان الجهاز لا يدعم البصمة
                  subtitle: !controller.isBiometricSupported.value 
                      ? Text('not_supported_on_device'.tr) 
                      : null,
                )),
              ),
              const SizedBox(height: 20),
              // قسم الإشعارات
              _buildSectionTitle('notifications'.tr),
              Card(
                child: Obx(() => SwitchListTile(
                  secondary: const Icon(Icons.notifications_active, color: Colors.orange),
                  title: Text('enable_notifications'.tr), // تفعيل التنبيهات
                  value: controller.isNotificationsEnabled.value,
                  onChanged: (val) => controller.toggleNotifications(val),
                )),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ويدجت مساعدة لبناء عنوان القسم في الإعدادات
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
      ),
    );
  }

  /// ويدجت بناء عنصر اللغة في القائمة
  Widget _buildLanguageItem(SettingsController controller, {required String title, required String code, required String country, required String icon}) {
    // التحقق مما إذا كانت هذه اللغة هي المختارة حالياً
    bool isSelected = controller.currentLocale.languageCode == code;
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 24)),
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
      onTap: () => controller.changeLanguage(code, country), // تغيير لغة التطبيق
    );
  }
}
