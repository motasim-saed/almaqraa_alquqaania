import 'package:flutter/material.dart'; // استيراد حزمة فلاتر الأساسية لتصميم الواجهات
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والترجمة والتنقل
import '../../core/controllers/profile_controller.dart'; // استيراد متحكم الملف الشخصي لجلب بيانات المستخدم
import '../../Teacher/controller/settings_controller.dart'; // استيراد متحكم الإعدادات للتعامل مع تسجيل الخروج
import '../../Student/pages/financial_support_page.dart'; // استيراد صفحة دعم المقرأة

class ExaminerDrawer extends StatelessWidget { // تعريف قائمة المختبر الجانبية كويدجت عديم الحالة
  const ExaminerDrawer({super.key}); // منشئ الفئة مع مفتاح التمييز الفريد

  @override // إعادة تعريف دالة بناء الواجهة
  Widget build(BuildContext context) { // دالة بناء سياق الواجهة
    final profileController = Get.put(ProfileController()); // تهيئة وربط متحكم الملف الشخصي
    final settingsController = Get.put(SettingsController()); // تهيئة وربط متحكم الإعدادات

    return Drawer( // إرجاع القائمة الجانبية (Drawer)
      child: Column( // ترتيب عناصر القائمة بشكل رأسي
        children: [ // بداية قائمة العناصر
          Obx(() { // استخدام Obx لمراقبة التغيرات في بيانات الملف الشخصي وتحديث الواجهة تلقائياً
            final hasAvatar = profileController.avatarUrl.value.isNotEmpty; // التحقق مما إذا كان المستخدم يمتلك صورة شخصية
            return UserAccountsDrawerHeader( // إنشاء ترويسة حساب المستخدم القياسية في القائمة
              decoration: BoxDecoration( // تنسيق خلفية الترويسة
                color: Theme.of(context).primaryColor, // تعيين اللون الأساسي للثيم كخلفية افتراضية
                image: hasAvatar // التحقق مما إذا كان سيتم عرض صورة كخلفية للترويسة
                    ? DecorationImage( // إعداد صورة الخلفية
                  image: NetworkImage(profileController.avatarUrl.value), // جلب الصورة من الرابط المخزن
                  fit: BoxFit.cover, // جعل الصورة تغطي كامل مساحة الترويسة
                  colorFilter: ColorFilter.mode( // إضافة فلتر لوني لتغميق الصورة لتوضيح النصوص فوقها
                    Colors.black.withValues(alpha: 0.4), // استخدام لون أسود شفاف
                    BlendMode.darken, // نمط التغميق
                  ), // نهاية الفلتر
                ) // نهاية صورة الخلفية
                    : null, // عدم استخدام صورة خلفية إذا لم تتوفر صورة الشخصية
                gradient: !hasAvatar ? LinearGradient( // استخدام تدرج لوني في حال عدم وجود صورة خلفية
                  colors: [ // قائمة ألوان التدرج
                    Theme.of(context).primaryColor, // اللون الأساسي
                    Theme.of(context).primaryColor.withValues(alpha: 0.8), // نسخة شفافة قليلاً من اللون الأساسي
                  ], // نهاية الألوان
                ) : null, // نهاية التدرج
              ), // نهاية التنسيق
              accountName: Text( // عرض اسم المستخدم في الترويسة
                profileController.name.value.isEmpty ? 'examiner_label'.tr : profileController.name.value, // الاسم أو نص افتراضي مترجم
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo'), // تنسيق خط الاسم
              ), // نهاية نص الاسم
              accountEmail: Text( // عرض البريد الإلكتروني للمستخدم
                profileController.email.value, // جلب البريد الإلكتروني من المتحكم
                style: const TextStyle(fontFamily: 'Cairo'), // تنسيق خط البريد
              ), // نهاية نص البريد
            ); // نهاية الترويسة
          }), // نهاية Obx
          Expanded( // جعل قائمة الروابط تأخذ المساحة المتبقية من الشاشة
            child: ListView( // إنشاء قائمة قابلة للتمرير للعناصر الجانبية
              padding: EdgeInsets.zero, // إلغاء المسافات الداخلية الافتراضية للقائمة
              children: [ // بداية عناصر القائمة
                _buildMenuItem( // بناء عنصر "الملف الشخصي"
                  icon: Icons.person_outline, // أيقونة الشخص المفرغة
                  title: 'profile'.tr, // نص "الملف الشخصي" المترجم
                  onTap: () { // وظيفة يتم تنفيذها عند النقر
                    Get.back(); // إغلاق القائمة الجانبية أولاً
                    Get.toNamed('/examiner/profile'); // الانتقال إلى شاشة ملف المختبر الشخصي
                  }, // نهاية وظيفة النقر
                ), // نهاية عنصر الملف الشخصي
                _buildMenuItem( // بناء عنصر "الإعدادات"
                  icon: Icons.settings_outlined, // أيقونة الترس المفرغة
                  title: 'settings'.tr, // نص "الإعدادات" المترجم
                  onTap: () { // وظيفة يتم تنفيذها عند النقر
                    Get.back(); // إغلاق القائمة الجانبية أولاً
                    Get.toNamed('/examiner/settings'); // الانتقال إلى شاشة إعدادات المختبر
                  }, // نهاية وظيفة النقر
                ), // نهاية عنصر الإعدادات
                _buildMenuItem(
                  icon: Icons.favorite_border_rounded,
                  title: 'financial_support'.tr,
                  onTap: () {
                    Get.back();
                    Get.to(() => FinancialSupportPage());
                  },
                ),
                _buildMenuItem( // بناء عنصر "الدعم الفني"
                  icon: Icons.support_agent_rounded, // أيقونة الدعم الفني
                  title: 'tech_support'.tr, // نص "الدعم الفني" المترجم
                  onTap: () { // وظيفة يتم تنفيذها عند النقر
                    Get.back(); // إغلاق القائمة الجانبية أولاً
                    Get.toNamed('/tech_support'); // الانتقال إلى شاشة الدعم الفني
                  },
                ),
              ], // نهاية عناصر ListView
            ), // نهاية ListView
          ), // نهاية Expanded
          const Divider(), // إضافة خط فاصل أفقي بسيط
          _buildMenuItem( // بناء عنصر "تسجيل الخروج"
            icon: Icons.logout, // أيقونة الخروج
            title: 'logout'.tr, // نص "تسجيل الخروج" المترجم
            color: Colors.red, // تمييز العنصر باللون الأحمر للتحذير
            onTap: () => _confirmLogout(settingsController), // استدعاء دالة تأكيد الخروج عند النقر
          ), // نهاية عنصر تسجيل الخروج
          const SizedBox(height: 20), // إضافة مسافة فارغة في أسفل القائمة للمظهر الجمالي
        ], // نهاية قائمة عناصر العمود
      ), // نهاية Column
    ); // نهاية Drawer
  } // نهاية دالة بناء الواجهة

  Widget _buildMenuItem({ // دالة مساعدة لبناء عناصر القائمة بشكل موحد ومكرر
    required IconData icon, // أيقونة العنصر
    required String title, // نص العنوان للعنصر
    required VoidCallback onTap, // الوظيفة المطلوبة عند النقر
    Color? color, // لون اختياري للعنصر (الأيقونة والنص)
  }) { // بداية الدالة
    return ListTile( // إرجاع عنصر قائمة قياسي من فلاتر
      leading: Icon(icon, color: color ?? Colors.purple), // عرض الأيقونة في البداية بلون أرجواني افتراضي
      title: Text(title, style: TextStyle(color: color, fontFamily: 'Cairo')), // عرض العنوان مع تنسيق خط Cairo
      onTap: onTap, // ربط وظيفة النقر الممررة
    ); // نهاية ListTile
  } // نهاية دالة بناء العنصر

  void _confirmLogout(SettingsController controller) { // دالة لإظهار نافذة تأكيد تسجيل الخروج للمستخدم
    Get.defaultDialog( // عرض نافذة ديالوج (منبثقة) باستخدام GetX
      title: 'logout'.tr, // عنوان النافذة "تسجيل الخروج" مترجم
      middleText: 'confirm_logout_msg'.tr, // نص الرسالة "هل أنت متأكد؟" مترجم
      textConfirm: 'yes'.tr, // نص زر التأكيد "نعم" مترجم
      textCancel: 'cancel'.tr, // نص زر الإلغاء "إلغاء" مترجم
      confirmTextColor: Colors.white, // جعل لون نص زر التأكيد أبيضاً
      buttonColor: Colors.red, // تعيين اللون الأحمر لزر التأكيد
      onConfirm: () { // الوظيفة التي تنفذ عند النقر على "نعم"
        Get.back(); // إغلاق نافذة الديالوج أولاً
        controller.logout(); // استدعاء وظيفة تسجيل الخروج من متحكم الإعدادات
      }, // نهاية وظيفة التأكيد
      titleStyle: const TextStyle(fontFamily: 'Cairo'), // تنسيق خط عنوان الديالوج
      middleTextStyle: const TextStyle(fontFamily: 'Cairo'), // تنسيق خط رسالة الديالوج
    ); // نهاية إعدادات الديالوج
  } // نهاية دالة تأكيد الخروج
} // نهاية كلاس ExaminerDrawer