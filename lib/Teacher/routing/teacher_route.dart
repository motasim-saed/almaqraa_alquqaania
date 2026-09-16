import 'package:al_maqraa/Teacher/screen/attendance/daily_attendance_screen.dart'; // استيراد شاشة الحضور اليومي للمعلم
import 'package:al_maqraa/Teacher/screen/home/homepage_teacher.dart'; // استيراد الشاشة الرئيسية للمعلم
import 'package:al_maqraa/Teacher/screen/follow_up/monthly_follow_up_screen.dart'; // استيراد شاشة المتابعة الشهرية
import 'package:al_maqraa/Teacher/screen/exam/monthly_exam_screen.dart'; // استيراد شاشة الاختبارات الشهرية
import 'package:al_maqraa/Teacher/screen/profile/profile_screen.dart'; // استيراد شاشة الملف الشخصي للمعلم
import 'package:al_maqraa/Teacher/screen/settings/settings_screen.dart'; // استيراد شاشة الإعدادات
import 'package:al_maqraa/Teacher/screen/leave_request/teacher_leave_request_screen.dart'; // استيراد شاشة طلبات الإجازة للمعلم
import 'package:al_maqraa/Teacher/screen/notifications/teacher_notifications_screen.dart'; // استيراد شاشة الإشعارات الخاصة بالمعلم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة المسارات (Routing)

/// فئة تحتوي على تعريفات المسارات (Routes) الخاصة بوحدة المعلم في التطبيق
class TeacherRoutes {
  // تعريف أسماء المسارات كثوابت نصية لتجنب الأخطاء عند الاستدعاء
  static const String homepage = '/homepageTeacher'; // مسار الصفحة الرئيسية للمعلم
  static const String monthlyFollowUp = '/monthlyFollowUp'; // مسار صفحة المتابعة الشهرية
  static const String dailyAttendance = '/dailyAttendance'; // مسار صفحة الحضور اليومي
  static const String monthlyExam = '/monthlyExam'; // مسار صفحة الاختبارات الشهرية
  static const String profile = '/profile'; // مسار صفحة الملف الشخصي
  static const String settings = '/settings'; // مسار صفحة الإعدادات
  static const String leaveRequest = '/teacherLeaveRequest'; // مسار صفحة طلب الإجازة
  static const String notifications = '/teacherNotifications'; // مسار صفحة الإشعارات

  // قائمة بصفحات التطبيق (GetPage) التي تربط كل اسم مسار بالودجت المناسبة له
  static final List<GetPage> routes = [
    GetPage(name: homepage, page: () => const HomepageTeacher()), // ربط مسار الرئيسية بصفحة المعلم الرئيسية
    GetPage(name: monthlyFollowUp, page: () => const MonthlyFollowUpScreen()), // ربط مسار المتابعة بالشاشة الخاصة بها
    GetPage(name: dailyAttendance, page: () => const DailyAttendanceScreen()), // ربط مسار الحضور بشاشة الحضور اليومي
    GetPage(name: monthlyExam, page: () => const MonthlyExamScreen()), // ربط مسار الاختبارات بشاشة الاختبارات
    GetPage(name: profile, page: () => const ProfileScreen()), // ربط مسار الملف الشخصي بشاشته
    GetPage(name: settings, page: () => const SettingsScreen()), // ربط مسار الإعدادات بشاشة الإعدادات
    // GetPage(name: leaveRequest, page: () => const TeacherLeaveRequestScreen()), // ربط مسار الإجازة بشاشة طلبات الإجازة
    GetPage(
      name: notifications, // ربط مسار الإشعارات
      page: () => const TeacherNotificationsScreen(), // بشاشة إشعارات المعلم
    ),
  ];
}
