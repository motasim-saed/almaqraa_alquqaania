// استيراد مكتبة GetX للتعامل مع التوجيه (Routing) وإدارة الحالة
import 'package:get/get.dart';

// استيراد شاشات قسم الطلاب
import '../screen/home/homepage_student.dart';
import '../screen/leave_request/student_leave_request_screen.dart';
import '../screen/notifications/student_notifications_screen.dart';
import '../pages/settings_screen.dart';
import '../pages/profiles_screen.dart';
import '../pages/plans_screen.dart';
import '../pages/student_grades_screen.dart'; // استيراد الشاشة الجديدة
import '../binding/student_binding.dart'; // استيراد الربط الخاص بالطالب

/// فئة تحتوي على جميع مسارات (Routes) التطبيق الخاصة بقسم الطالب
class StudentRoutes {
  static const String studenthomepage = '/studenthomepage';
  static const String leaveRequest = '/studentLeaveRequest';
  static const String notifications = '/studentNotifications';
  static const String settings = '/studentSettings';
  static const String profile = '/studentProfile';
  static const String plans = '/studentPlans';
  static const String grades = '/studentGrades'; // مسار شاشة الدرجات

  static final List<GetPage> routes = [
    GetPage(
      name: studenthomepage,
      page: () => const HomepageStudent(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: leaveRequest,
      page: () => const StudentLeaveRequestScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: notifications,
      page: () => const StudentNotificationsScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: settings,
      page: () => const StudentSettingsScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: profile,
      page: () => const ProfilesScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: plans,
      page: () => const PlansScreen(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: grades,
      page: () => const StudentGradesScreen(),
      binding: StudentBinding(),
    ),
  ];
}
