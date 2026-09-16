import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/services/biometric_service.dart';
import '../../../Auth/routing/auth_route.dart';

class SettingsController extends GetxController {
  final ThemeController _themeController = Get.find<ThemeController>();
  final BiometricService _biometricService = BiometricService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final _storage = GetStorage();

  static const String _langKey = 'selectedLanguage';
  var currentLocale = Get.locale ?? const Locale('ar', 'SA');
  var isBiometricEnabled = false.obs;
  var isBiometricSupported = false.obs;
  var isNotificationsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedLang = prefs.getString(_langKey);
    if (savedLang != null) {
      currentLocale = Locale(savedLang, savedLang == 'ar' ? 'SA' : 'US');
    }

    isBiometricSupported.value = await _biometricService.canAuthenticate();
    isBiometricEnabled.value = await _biometricService.isBiometricEnabled();
    isNotificationsEnabled.value = _storage.read('is_notifications_enabled') ?? true;
    update();
  }

  void changeLanguage(String langCode, String countryCode) async {
    Locale locale = Locale(langCode, countryCode);
    Get.updateLocale(locale);
    currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, langCode);
    update();
  }

  void toggleTheme() {
    _themeController.toggleTheme();
    update();
  }

  bool get isDarkMode => _themeController.isDarkMode;

  void toggleBiometrics(bool value) async {
    if (value) {
      bool hasEnrolled = await _biometricService.hasEnrolledBiometrics();
      if (!hasEnrolled) {
        isBiometricEnabled.value = false;
        Get.snackbar(
          'alert'.tr,
          'no_biometrics_enrolled'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      bool authenticated = await _biometricService.authenticate();
      if (authenticated) {
        await _biometricService.setEnabled(true);
        isBiometricEnabled.value = true;
        Get.snackbar(
          'success'.tr,
          'biometric_enabled_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        isBiometricEnabled.value = false;
        Get.snackbar(
          'alert'.tr,
          'biometric_auth_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } else {
      await _biometricService.setEnabled(false);
      isBiometricEnabled.value = false;
    }
  }

  void toggleNotifications(bool value) {
    isNotificationsEnabled.value = value;
    _storage.write('is_notifications_enabled', value);
    update();
  }

  Future<void> logout() async {
    try {
      try {
        await _supabase.auth.signOut().timeout(const Duration(seconds: 1));
      } catch (_) {}

      Get.offAllNamed(AuthRoutes.login);
    } catch (e) {
      Get.snackbar('error'.tr, 'logout_failed'.tr);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _supabase.rpc('delete_user_account');
      await logout();
    } catch (e) {
      Get.snackbar(
        'alert'.tr,
        'delete_account_contact_msg'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      await logout();
    }
  }

  bool isArabic() => currentLocale.languageCode == 'ar';
}
