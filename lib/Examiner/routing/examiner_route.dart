import 'package:get/get.dart';
import '../screen/examiner_main_layout.dart';
import '../../Teacher/screen/profile/profile_screen.dart';
import '../../Teacher/screen/settings/settings_screen.dart';

class ExaminerRoutes {
  // تعريف المسار الرئيسي لواجهة المختبر
  static const String examinerHome = '/examiner_home';
  static const String profile = '/examiner/profile';
  static const String settings = '/examiner/settings';

  // قائمة المسارات المتاحة داخل تطبيق المختبر لربطها بـ GetMaterialApp
  static final List<GetPage> routes = [
    GetPage(
      name: examinerHome,
      page: () => const ExaminerMainLayout(), // الواجهة التي سيتم عرضها عند طلب المسار
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
    ),
  ];
}
