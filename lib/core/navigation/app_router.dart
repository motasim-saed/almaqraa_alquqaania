// استيراد حزمة dart:io للتعرف على نظام التشغيل (أندرويد، ويندوز، إلخ)
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
// استيراد مسارات الطالب
import 'package:al_maqraa/Student/routing/student_route.dart';
// استيراد مسارات المعلم
import 'package:al_maqraa/Teacher/routing/teacher_route.dart';
// استيراد مسارات الإدارة (الأدمن)
import 'package:al_maqraa/Admin/routing/admin_route.dart';
// استيراد مسارات المنسق
import 'package:al_maqraa/Coordinator/routing/coordinator_route.dart';
// استيراد مسارات المختبر (الممتحن)
import 'package:al_maqraa/Examiner/routing/examiner_route.dart';
// استيراد حزمة GetX لإدارة التنقل بين الصفحات
import 'package:get/get.dart';
// استيراد مسارات المصادقة (تسجيل الدخول)
import 'package:al_maqraa/Auth/routing/auth_route.dart';

// استيراد شاشة الدعم الفني
import 'package:al_maqraa/core/widgets/tech_support_screen.dart';

/// فئة موجه التطبيق (AppRouter)
/// المسؤولة عن تجميع كافة مسارات التطبيق وتحديد المسارات المتاحة حسب نوع الجهاز
class AppRouter {
  static const String techSupport = '/tech_support';

  /// دالة جلب المسارات: ترجع قائمة الصفحات المتاحة للتنقل
  static List<GetPage> get routes {
    // التحقق من نظام التشغيل: إذا كان ديسك توب (ويندوز أو ماك)
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      // إرجاع مسارات الإدارة فقط لأن تطبيق الديسك توب مخصص للأدمن
      return adminRoutes;
    } else {
      // إرجاع مسارات الجوال (طالب، معلم، إلخ) لأن تطبيق الجوال مخصص لهم
      return mobileRoutes;
    }
  }

  /// قائمة مسارات تطبيق الجوال (Mobile Routes)
  /// تدمج كافة مسارات المستخدمين (طالب، معلم، ممتحن، منسق) بالإضافة لصفحات تسجيل الدخول
  static final List<GetPage> mobileRoutes = [
    GetPage(name: techSupport, page: () => const TechSupportScreen()),
    ...AuthRoutes.routes, // مسارات تسجيل الدخول والمصادقة
    ...AdminRoutes.routes, // إضافة مسارات الإدارة لدعم دخول الأدمن من الهاتف
    ...TeacherRoutes.routes, // مسارات واجهة المعلم
    ...StudentRoutes.routes, // مسارات واجهة الطالب
    ...ExaminerRoutes.routes, // مسارات واجهة المختبر
    ...CoordinatorRoutes.routes, // مسارات واجهة المنسق
  ];

  /// قائمة مسارات تطبيق الإدارة (Admin Routes)
  /// تدمج مسارات تسجيل الدخول مع مسارات لوحة تحكم الأدمن
  static final List<GetPage> adminRoutes = [
    GetPage(name: techSupport, page: () => const TechSupportScreen()),
    ...AuthRoutes.routes, // مسارات تسجيل الدخول
    ...AdminRoutes.routes, // مسارات لوحة تحكم الأدمن
  ];
}
