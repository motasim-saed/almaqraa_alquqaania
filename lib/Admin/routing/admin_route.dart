import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة المسارات والحالة
import '../screen/admin_main_layout.dart'; // استيراد واجهة التخطيط الرئيسية للمسؤول
import '../binding/admin_binding.dart'; // استيراد ملف الربط الخاص بالمسؤول لتهيئة المتحكمات

class AdminRoutes {
  // تعريف ثابت لمسار الصفحة الرئيسية للمسؤول
  static const String adminHome = '/admin/home';
  
  // ملاحظة: المسارات الأخرى أصبحت الآن داخلية ضمن AdminMainLayout
  
  // قائمة المسارات الخاصة بنظام المسؤول
  static final List<GetPage> routes = [
    GetPage(
      name: adminHome, // اسم المسار
      page: () => const AdminMainLayout(), // الواجهة المرتبطة بالمسار
      binding: AdminBinding(), // الربط الخاص بالواجهة لضمان حقن التبعيات
    ),
  ];

}
