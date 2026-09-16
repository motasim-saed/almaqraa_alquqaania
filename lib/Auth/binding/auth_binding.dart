// استيراد حزمة GetX لإدارة الحالة والاعتمادات
import 'package:get/get.dart';
// استيراد متحكم المصادقة (AuthController) لاستخدامه في الربط
import '../controller/auth_controller.dart';

// تعريف كلاس AuthBinding الذي يرث من Bindings لإدارة حقن الاعتمادات
class AuthBinding extends Bindings {
  @override
  // دالة dependencies هي المكان الذي يتم فيه تعريف الاعتمادات المطلوبة
  void dependencies() {
    // حقن AuthController في الذاكرة وجعله متاحاً بشكل دائم (permanent) طوال فترة تشغيل التطبيق
    Get.put(AuthController(), permanent: true);
  }
}
