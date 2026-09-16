import 'package:get/get.dart';
// استيراد متحكم الإشعارات لإدارة التنبيهات والرسائل
import '../controllers/notification_controller.dart';
// استيراد متحكم السمات للتحكم في مظهر التطبيق (فاتح/داكن)
import '../theme/theme_controller.dart';

/// فئة الربط الأولي (InitialBinding):
/// تُستخدم هذه الفئة لتعريف وتجهيز كافة المتحكمات (Controllers) والخدمات (Services)
/// التي يحتاجها التطبيق فور تشغيله وتظل متوفرة في الذاكرة أو تُحمل عند الحاجة.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // تهيئة متحكم الإشعارات وجعله متاحاً بشكل دائم لإرسال واستقبال التنبيهات
    Get.put(NotificationController(), permanent: true);
    
    // تهيئة متحكم السمات (الثيم) وجعله متاحاً بشكل دائم لتغيير ألوان التطبيق في أي وقت
    Get.put(ThemeController(), permanent: true);
    
    // يمكن إضافة المزيد من الاعتماديات هنا إذا كان التطبيق يتطلب خدمات إضافية عند البدء
  }
}
