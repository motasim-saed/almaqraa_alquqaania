// استيراد متحكم المصادقة للوصول إلى الوظائف والبيانات المتعلقة بعملية الدخول الأول
import 'package:al_maqraa/Auth/controller/auth_controller.dart';
// استيراد حزمة Flutter Material لتصميم واجهة المستخدم
import 'package:flutter/material.dart';
// استيراد حزمة GetX لإدارة الحالة، التنقل، والترجمة
import 'package:get/get.dart';
// استيراد مكون حقل الإدخال المخصص لعرض الأخطاء والتحقق من البيانات
import 'package:al_maqraa/components/form_failed.dart';

// تعريف كلاس FirstLoginScreen كـ StatelessWidget لشاشة التفعيل لأول مرة
class FirstLoginScreen extends StatelessWidget {
  // باني الكلاس مع تمرير المفتاح الاختياري
  FirstLoginScreen({super.key});

  // مفتاح فريد للنموذج (Form) للتحقق من صحة المدخلات في هذه الشاشة
  final _formKey = GlobalKey<FormState>();
  // البحث عن نسخة متحكم AuthController الموجودة مسبقاً في الذاكرة (تم حقنها عبر Binding)
  final AuthController controller = Get.find<AuthController>();

  @override
  // بناء واجهة المستخدم للشاشة
  Widget build(BuildContext context) {
    return Scaffold(
      // شريط التطبيق العلوي مع عنوان يدعم الترجمة
      appBar: AppBar(title: Text('first_time_activation'.tr)),
      // توسيط المحتوى في منتصف الشاشة
      body: Center(
        // جعل المحتوى قابلاً للتمرير لتجنب مشاكل المساحة عند ظهور الكيبورد
        child: SingleChildScrollView(
          // إضافة هوامش داخلية حول المحتوى بالكامل
          padding: const EdgeInsets.all(24.0),
          child: Column(
            // توسيط العناصر عمودياً في العمود
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // عرض شعار المقرأة في شكل دائري
              CircleAvatar(
                radius: 60, // نصف قطر الدائرة
                backgroundColor: Colors.blue, // لون خلفية الشعار
                backgroundImage: const AssetImage("assetes/images/maqraa.png"), // مسار صورة الشعار
              ),
              const SizedBox(height: 30), // مسافة عمودية بمقدار 30 بكسل
              // بطاقة (Card) تحتوي على نموذج إدخال البيانات بشكل أنيق وبارز
              Card(
                elevation: 4, // قيمة الظل للبطاقة
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // زوايا منحنية للبطاقة
                ),
                child: Padding(
                  // إضافة هوامش داخلية للبطاقة
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey, // ربط النموذج بالمفتاح لعمل التحقق (Validation)
                    child: Column(
                      children: [
                        // نص ترحيبي مترجم
                        Text(
                          "welcome_msg".tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center, // توسيط النص
                        ),
                        const SizedBox(height: 10), // مسافة عمودية
                        // نص تعليمات يوضح الخطوات المطلوبة للمستخدم مترجم
                        Text(
                          "activation_instructions".tr,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30), // مسافة عمودية

                        // حقل إدخال البريد الإلكتروني أو الرقم الأكاديمي (استخدمنا المفاتيح المترجمة)
                        DefaultFormFailed(
                          controller: controller.emailController, // ربط الحقل بمتحكم البيانات
                          type: TextInputType.emailAddress, // نوع لوحة المفاتيح المخصصة للإيميل
                          validate: (value) {
                            // التحقق من أن الحقل ليس فارغاً
                            if (value == null || value.isEmpty) {
                              return "valid_email_error".tr;
                            }
                            return null;
                          },
                          lable: "email_or_academic_id".tr, // تسمية الحقل مترجمة
                          prefix: Icons.email_outlined, // أيقونة في بداية الحقل
                          textInputAction: TextInputAction.next,
                          onSubmit: (_) => FocusScope.of(context).nextFocus(),
                        ),
                        const SizedBox(height: 20), // مسافة عمودية

                        // حقل إدخال الرمز الفريد (دعم الترجمة للأخطاء والعناوين)
                        DefaultFormFailed(
                          controller: controller.passwordController, // ربط الحقل بمتحكم البيانات
                          type: TextInputType.text, // نوع لوحة المفاتيح نصية
                          validate: (value) {
                            // التحقق من أن الرمز الفريد قد تم إدخاله
                            if (value == null || value.isEmpty) {
                              return "unique_code_error".tr;
                            }
                            return null;
                          },
                          isPassword: false, // النص غير مخفي لأن الرمز ليس كلمة سر تقليدية هنا
                          lable: "unique_code".tr, // تسمية الحقل مترجمة
                          prefix: Icons.vpn_key, // أيقونة المفتاح
                          textInputAction: TextInputAction.done,
                          onSubmit: (_) {
                            if (!controller.isLoading.value && _formKey.currentState!.validate()) {
                              controller.verifyFirstTimeUser();
                            }
                          },
                        ),
                        const SizedBox(height: 30), // مسافة عمودية

                        // زر تفعيل الحساب مع مراقبة حالة التحميل (Obx)
                        Obx(() => SizedBox(
                          width: double.infinity, // الزر يأخذ العرض المتاح بالكامل
                          height: 55, // ارتفاع الزر
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value 
                              ? null 
                              : () {
                                // التحقق من صحة جميع الحقول في النموذج قبل التنفيذ
                                if (_formKey.currentState!.validate()) {
                                  // استدعاء دالة التحقق لمستخدمي المرة الأولى من المتحكم
                                  controller.verifyFirstTimeUser();
                                }
                              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // لون الزر الأزرق
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12), // انحناء زوايا الزر
                              ),
                              elevation: 2, // ظل خفيف للزر
                            ),
                            child: controller.isLoading.value
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "activate_account".tr, // نص الزر مترجم
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // مسافة بين البطاقة والنص السفلي
              // صف يحتوي على نص ورابط لإنشاء حساب جديد
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // توسيط الصف
                children: [
                  // نص تساؤلي للمستخدم مترجم
                  Text(
                    "no_code_msg".tr,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  // زر نصي لفتح موقع التسجيل الخارجي
                  TextButton(
                    onPressed: () {
                      // استدعاء دالة فتح موقع التسجيل من المتحكم
                      controller.launchRegistrationWebsite();
                    },
                    child: Text(
                      "create_new_account".tr, // نص الرابط مترجم
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
