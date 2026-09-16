import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../components/form_failed.dart';
import '../../controller/profile_controller.dart';

/// شاشة تغيير كلمة المرور للمعلم والطالب
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // متحكمات محلية لحقول كلمة المرور الجديدة وتأكيدها
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('change_password_title'.tr), // عنوان الشاشة معرب
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // حقل إدخال كلمة المرور الجديدة
              DefaultFormFailed(
                controller: newPasswordController,
                type: TextInputType.visiblePassword,
                validate: (value) {
                  if (value == null || value.isEmpty) {
                    return 'enter_new_password'.tr;
                  }
                  if (value.length < 6) return 'password_length_error'.tr;
                  return null;
                },
                lable: 'new_password'.tr,
                prefix: Icons.lock_outline,
              ),
              const SizedBox(height: 20),
              // حقل تأكيد كلمة المرور الجديدة
              DefaultFormFailed(
                controller: confirmPasswordController,
                type: TextInputType.visiblePassword,
                validate: (value) {
                  if (value != newPasswordController.text) {
                    return 'passwords_not_match'.tr; // التحقق من تطابق الكلمتين
                  }
                  return null;
                },
                lable: 'confirm_new_password'.tr,
                prefix: Icons.lock_reset,
              ),
              const SizedBox(height: 40),
              // استخدام GetBuilder للوصول لمتحكم الملف الشخصي وتنفيذ عملية التغيير
              // تمت إضافة init لضمان تهيئة المتحكم في حال لم يكن مسجلاً (مثل عند دخول الطالب)
              GetBuilder<TeacherProfileController>(
                init: TeacherProfileController(),
                builder: (controller) {
                  return SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: controller.isLoading
                          ? null
                          : () {
                              // التحقق من صحة المدخلات قبل الإرسال
                              if (formKey.currentState!.validate()) {
                                controller.changePassword(
                                  newPasswordController.text.trim(),
                                );
                              }
                            },
                      child: controller.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'update_password_btn'.tr, // زر تحديث كلمة المرور
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
