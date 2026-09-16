import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:al_maqraa/Auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';

// شاشة إعدادات المسؤول - AdminSettingsScreen
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();
    final isNotificationsEnabled = RxBool(
      storage.read('is_notifications_enabled') ?? true,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. قسم تغيير اللغة
        _buildSectionHeader('language'.tr),
        const SizedBox(height: 8),
        _buildSettingTile(
          title: 'arabic'.tr,
          icon: Icons.language,
          trailing: Get.locale?.languageCode == 'ar'
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () => Get.updateLocale(const Locale('ar', 'SA')),
        ),
        _buildSettingTile(
          title: 'english'.tr,
          icon: Icons.language,
          trailing: Get.locale?.languageCode == 'en'
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () => Get.updateLocale(const Locale('en', 'US')),
        ),
        const Divider(height: 32),

        // 2. قسم وضع المظهر
        _buildSectionHeader('theme_mode'.tr),
        const SizedBox(height: 8),
        _buildSettingTile(
          title: 'light_mode'.tr,
          icon: Icons.light_mode,
          trailing: !Get.isDarkMode
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () => Get.changeThemeMode(ThemeMode.light),
        ),
        _buildSettingTile(
          title: 'dark_mode'.tr,
          icon: Icons.dark_mode,
          trailing: Get.isDarkMode
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () => Get.changeThemeMode(ThemeMode.dark),
        ),
        const Divider(height: 32),

        // 3. قسم الإشعارات
        if (kIsWeb || !Platform.isWindows) ...[
          _buildSectionHeader('notifications_settings'.tr),
          const SizedBox(height: 8),
          Obx(
            () => _buildSettingTile(
              title: 'enable_notifications'.tr,
              icon: Icons.notifications_active,
              trailing: Switch(
                value: isNotificationsEnabled.value,
                onChanged: (val) {
                  isNotificationsEnabled.value = val;
                  storage.write('is_notifications_enabled', val);
                },
                activeColor: Colors.indigo,
              ),
              onTap: () {
                isNotificationsEnabled.toggle();
                storage.write('is_notifications_enabled', isNotificationsEnabled.value);
              },
            ),
          ),
          const Divider(height: 32),
        ],

        // 4. قسم الحساب
        _buildSectionHeader('account_settings'.tr),
        const SizedBox(height: 8),
        _buildSettingTile(
          title: 'change_password'.tr,
          icon: Icons.lock_reset,
          onTap: () {
            if (Get.isRegistered<AuthController>()) {
              final authCtrl = Get.find<AuthController>();
              authCtrl.resetPasswordController.clear();
              authCtrl.confirmPasswordController.clear();
            }
            Get.toNamed('/reset_password');
          },
        ),
        const Divider(height: 32),

        // 5. قسم الدعم الفني - تم تجميعه في نافذة واحدة
        _buildSectionHeader('technical_support'.tr),
        const SizedBox(height: 8),
        _buildSettingTile(
          title: 'technical_support'.tr,
          subtitle: 'tech_support_details'.tr,
          icon: Icons.support_agent_rounded,
          onTap: () => Get.toNamed('/tech_support'),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  void _showSupportDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.contact_support_rounded, color: Colors.indigo, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'technical_support'.tr,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 8),
              Text(
                'Eng. Motasim',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
              ),
              Text(
                'tech_manager'.tr,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              
              _buildDialogActionTile(
                context,
                title: '+967771511800',
                subtitle: 'click_to_copy'.tr,
                icon: Icons.phone_android_rounded,
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: '+967771511800'));
                  Get.snackbar('success'.tr, 'copy_success'.tr, 
                    backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                },
              ),
              
              _buildDialogActionTile(
                context,
                title: 'motasimalsalahi@gmail.com',
                subtitle: 'click_to_copy'.tr,
                icon: Icons.email_outlined,
                onTap: () async {
                  Clipboard.setData(const ClipboardData(text: 'motasimalsalahi@gmail.com'));
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'motasimalsalahi@gmail.com',
                    query: _encodeQueryParameters(<String, String>{
                      'subject': 'AlMaqraa Support',
                    }),
                  );
                  launchUrl(emailLaunchUri);
                },
              ),
              
              _buildDialogActionTile(
                context,
                title: 'whatsapp_support'.tr,
                subtitle: 'Eng. Motasim',
                icon: Icons.chat_outlined,
                iconColor: Colors.green,
                onTap: () async {
                  final Uri whatsappUri = Uri.parse('https://wa.me/967771511800');
                  if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
                    Get.snackbar('error'.tr, 'whatsapp_error'.tr, backgroundColor: Colors.redAccent, colorText: Colors.white);
                  }
                },
              ),
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text('close'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogActionTile(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.indigo),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing:
            trailing ??
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
