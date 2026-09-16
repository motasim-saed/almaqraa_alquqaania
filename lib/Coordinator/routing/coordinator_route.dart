import 'package:get/get.dart';
import '../screen/coordinator_layout_screen.dart';
import '../screen/settings/coordinator_settings_screen.dart';
import '../../Teacher/screen/profile/profile_screen.dart';

class CoordinatorRoutes {
  // مسارات المنسق المعرفة في التطبيق
  static const String home = '/coordinator/home'; // شاشة التنسيق الرئيسية
  static const String settings = '/coordinator/settings'; // شاشة الإعدادات
  static const String profile = '/coordinator/profile'; // شاشة الملف الشخصي

  // قائمة الصفحات (GetPage) الخاصة بنظام GetX للملاحة
  static final List<GetPage> routes = [
    // ربط مسار الشاشة الرئيسية بـ CoordinatorLayoutScreen
    GetPage(name: home, page: () => const CoordinatorLayoutScreen()),
    // ربط مسار الإعدادات بـ CoordinatorSettingsScreen
    GetPage(name: settings, page: () => const CoordinatorSettingsScreen()),
    // ربط مسار الملف الشخصي بشاشة البروفايل (مشتركة مع المعلم)
    GetPage(name: profile, page: () => const ProfileScreen()),
  ];
}
