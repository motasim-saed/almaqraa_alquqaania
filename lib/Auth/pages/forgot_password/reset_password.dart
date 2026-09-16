import 'package:al_maqraa/Auth/controller/auth_controller.dart'; // استيراد متحكم المصادقة للوصول إلى الوظائف والبيانات
import 'package:flutter/material.dart'; // استيراد حزمة Flutter Material لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة والتنقل
import '../../../components/form_failed.dart'; // استيراد مكون حقل الإدخال المخصص (DefaultFormFailed)

// تعريف كلاس ResetPassword كـ StatelessWidget لشاشة إعادة تعيين كلمة المرور
class ResetPassword extends StatelessWidget {
  ResetPassword({super.key});

  // مفتاح فريد لنموذج (Form) للتحقق من صحة البيانات المدخلة
  final _formKey = GlobalKey<FormState>();
  // البحث عن نسخة متحكم AuthController الموجودة مسبقاً في الذاكرة
  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // شريط التطبيق العلوي مع عنوان مترجم
      appBar: AppBar(title: Text('reset_password'.tr)),
      body: Center(
        // جعل المحتوى قابلاً للتمرير لتجنب مشاكل المساحة عند ظهور لوحة المفاتيح
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // إضافة هوامش داخلية حول المحتوى
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // توسيط العناصر عمودياً
            children: [
              // عرض شعار المقرأة في دائرة
              CircleAvatar(
                radius: 60, // نصف قطر الدائرة
                backgroundColor: Colors.blue, // لون الخلفية في حال لم يتم تحميل الصورة
                backgroundImage: const AssetImage("assetes/images/maqraa.png"), // مسار صورة الشعار
              ),
              const SizedBox(height: 30), // مسافة عمودية
              // بطاقة (Card) تحتوي على نموذج إدخال البيانات بشكل أنيق
              Card(
                elevation: 4, // ظل البطاقة
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // زوايا منحنية للبطاقة
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0), // هوامش داخلية للبطاقة
                  child: Form(
                    key: _formKey, // ربط النموذج بالمفتاح لعمل التحقق (Validation)
                    child: Column(
                      children: [
                        // نص تعليمات للمستخدم مترجم
                        Text(
                          "new_password_msg".tr,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 30),

                        // حقل إدخال كلمة المرور الجديدة مع مراقبة الحالة (Obx) لإظهار/إخفاء النص
                        Obx(
                          () => DefaultFormFailed(
                            controller: controller.resetPasswordController, // المتحكم في نص الحقل
                            type: TextInputType.visiblePassword, // نوع لوحة المفاتيح
                            validate: (value) { // وظيفة التحقق من صحة الإدخال
                              if (value == null || value.isEmpty) {
                                return "strong_password_error".tr; // رسالة خطأ إذا كان الحقل فارغاً
                              }
                              return null;
                            },
                            isPassword: controller.isResetPasswordHidden.value, // تحديد هل النص مخفي (نجوم) أم ظاهر
                            suffixpressed: () =>
                                controller.toggleResetPasswordVisibility(), // وظيفة تفعيل/تعطيل الإخفاء عند الضغط على الأيقونة
                            sufix: controller.isResetPasswordHidden.value
                                ? Icons.visibility_off // أيقونة العين المغلقة
                                : Icons.visibility, // أيقونة العين المفتوحة
                            lable: "new_password".tr, // تسمية الحقل مترجمة
                            prefix: Icons.lock, // أيقونة القفل في بداية الحقل
                            textInputAction: TextInputAction.next,
                            onSubmit: (_) => FocusScope.of(context).nextFocus(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // حقل تأكيد كلمة المرور الجديدة مع مراقبة الحالة (Obx)
                        Obx(
                          () => DefaultFormFailed(
                            controller: controller.confirmPasswordController, // المتحكم في نص حقل التأكيد
                            type: TextInputType.visiblePassword,
                            validate: (value) {
                              if (value == null || value.isEmpty) {
                                return "confirm_new_password".tr;
                              }
                              // التحقق من أن كلمة المرور الثانية تطابق الأولى تماماً
                              if (value !=
                                  controller.resetPasswordController.text) {
                                return "passwords_not_match".tr; // رسالة خطأ عند عدم التطابق
                              }
                              return null;
                            },
                            isPassword:
                                controller.isConfirmPasswordHidden.value,
                            suffixpressed: () =>
                                controller.toggleConfirmPasswordVisibility(),
                            sufix: controller.isConfirmPasswordHidden.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            lable: "confirm_new_password".tr,
                            prefix: Icons.lock,
                            textInputAction: TextInputAction.done,
                            onSubmit: (_) {
                              if (_formKey.currentState!.validate()) {
                                controller.setNewPassword(
                                  controller.resetPasswordController.text,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 30),

                        // زر التأكيد النهائي لتعيين كلمة المرور
                        SizedBox(
                          width: double.infinity, // الزر يأخذ العرض المتاح بالكامل
                          height: 55, // ارتفاع الزر
                          child: ElevatedButton(
                            onPressed: () {
                              // التحقق من صحة جميع الحقول في النموذج قبل التنفيذ
                              if (_formKey.currentState!.validate()) {
                                // استدعاء دالة تعيين كلمة المرور الجديدة من المتحكم
                                controller.setNewPassword(
                                  controller.resetPasswordController.text,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // لون الزر الأزرق
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12), // انحناء زوايا الزر
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              "confirm".tr, // نص الزر مترجم (تأكيد)
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
