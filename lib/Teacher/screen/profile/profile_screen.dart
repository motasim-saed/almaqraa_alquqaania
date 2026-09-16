import 'package:flutter/material.dart'; // استيراد حزمة فلاتر الأساسية للواجهات
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../../components/form_failed.dart'; // استيراد ويدجت حقول الإدخال المخصصة
import '../../controller/profile_controller.dart'; // استيراد متحكم الملف الشخصي للمعلم
import 'change_password_screen.dart'; // استيراد شاشة تغيير كلمة المرور
import '../../../core/utils/app_cached_image.dart'; // استيراد ويدجت عرض الصور مع التخزين المؤقت
import '../../../core/utils/full_screen_image_viewer.dart'; // استيراد عارض الصور بملء الشاشة

/// شاشة الملف الشخصي للمعلم: تسمح بعرض وتعديل البيانات الشخصية والإعدادات
class ProfileScreen extends StatelessWidget {
  // منشئ الكلاس الثابت
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // استخدام GetBuilder لربط الواجهة بمتحكم ملف المعلم الشخصي
    return GetBuilder<TeacherProfileController>(
      init: TeacherProfileController(), // تهيئة المتحكم عند فتح الشاشة
      builder: (controller) {
        return Scaffold(
          backgroundColor:
              theme.scaffoldBackgroundColor, // تعيين لون خلفية فاتح جداً
          extendBodyBehindAppBar: true, // تمديد محتوى الجسم خلف شريط التطبيق
          appBar: AppBar(
            // عنوان الصفحة مترجم (تعديل الملف الشخصي)
            title: Text(
              'profile_edit'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            centerTitle: true, // توسيط العنوان
            backgroundColor:
                colorScheme.primary, // توحيد اللون مع اللون الأساسي للثيم
            elevation: 0, // إلغاء الظل
            iconTheme: const IconThemeData(
              color: Colors.white,
            ), // تلوين الأيقونات بالأبيض
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    // قسم الهيدر الجديد بتصميم "واتس أب"
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withValues(alpha: 0.8),
                            theme.scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: kToolbarHeight + 20),
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    if (controller.avatarUrl.value.isNotEmpty) {
                                      Get.to(
                                        () => FullScreenImageViewer(
                                          imageUrl: controller.avatarUrl.value,
                                          tag: 'avatar_image',
                                          title: 'profile_image'.tr,
                                        ),
                                      );
                                    }
                                  },
                                  child: ClipOval(
                                    child: Obx(
                                      () =>
                                          controller.avatarUrl.value.isNotEmpty
                                          ? Hero(
                                              tag: 'avatar_image',
                                              child: AppCachedImage(
                                                imageUrl:
                                                    controller.avatarUrl.value,
                                                width: 140,
                                                height: 140,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Container(
                                              width: 140,
                                              height: 140,
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                size: 80,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            controller.nameController.text,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Obx(
                            () => Text(
                              controller.role.value.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Cairo',
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // قسم حقول الإدخال والبيانات
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: controller.formKey, // مفتاح التحقق من صحة النموذج
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              'basic_info'.tr,
                            ), // عنوان القسم: البيانات الأساسية
                            const SizedBox(height: 15),
                            // حقل الاسم الكامل
                            DefaultFormFailed(
                              controller: controller.nameController,
                              type: TextInputType.name,
                              validate: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'full_name_error'.tr
                                  : null,
                              lable: 'full_name'.tr,
                              prefix: Icons.person_outline,
                            ),
                            const SizedBox(height: 15),
                            // حقل البريد الإلكتروني (مع التحقق من الصيغة ومنع التعديل لبعض الأدوار)
                            Obx(
                              () => DefaultFormFailed(
                                controller: controller.emailController,
                                type: TextInputType.emailAddress,
                                isClickable:
                                    controller.role.value != 'examiner',
                                validate: (value) {
                                  if (controller.role.value == 'examiner') {
                                    return null;
                                  }
                                  if (value == null || value.isEmpty) {
                                    return 'email_error'.tr;
                                  }
                                  if (!GetUtils.isEmail(value)) {
                                    return 'valid_email_error'.tr;
                                  }
                                  return null;
                                },
                                lable: 'email'.tr,
                                prefix: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 15),
                            // حقل رقم الهاتف
                            DefaultFormFailed(
                              controller: controller.phoneController,
                              type: TextInputType.phone,
                              validate: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'phone_error'.tr
                                  : null,
                              lable: 'phone'.tr,
                              prefix: Icons.phone_android_outlined,
                            ),

                          
                            const SizedBox(height: 25),
                            _buildSectionTitle(
                              'academic_info'.tr,
                            ), // عنوان القسم: البيانات الأكاديمية
                            const SizedBox(height: 15),
                            // بطاقات عرض البيانات غير القابلة للتعديل مباشرة (رقم أكاديمي، حلقة، مستوى)
                            _buildInfoCard(
                              icon: Icons.numbers_outlined,
                              label: 'academic_number'.tr,
                              value: controller.academicNumberController.text,
                            ),
                            _buildInfoCard(
                              icon: Icons.batch_prediction_outlined,
                              label: 'batch_number'.tr,
                              value: controller.batchNumberController.text,
                            ),
                            _buildInfoCard(
                              icon: Icons.groups_outlined,
                              label: 'circle_label'.tr,
                              value: controller.circleNameController.text,
                            ),
                            _buildInfoCard(
                              icon: Icons.auto_stories_outlined,
                              label: 'level_category'.tr,
                              value: controller.hifzLevelController.text,
                            ),

                            // إعدادات الكفالة تظهر فقط للمعلمين
                            if (controller.role.value == 'teacher') ...[
                              const SizedBox(height: 25),
                              _buildSectionTitle(
                                'sponsorship_settings'.tr,
                              ), // عنوان القسم: إعدادات الكفالة
                              const SizedBox(height: 10),
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                                color: theme.cardColor,
                                // تفعيل أو تعطيل طلب الكفالة مع نافذة تأكيد
                                child: SwitchListTile(
                                  title: Text(
                                    'need_sponsorship'.tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  subtitle: Text(
                                    'need_sponsorship_msg'.tr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  value: controller.needsSponsorship,
                                  onChanged: (value) =>
                                      _showSponsorshipConfirmation(
                                        context,
                                        controller,
                                        value,
                                      ),
                                  activeColor: colorScheme.primary,
                                ),
                              ),
                              // حقول مبالغ ونوع الكفالة تظهر عند التفعيل
                              if (controller.needsSponsorship) ...[
                                const SizedBox(height: 10),
                                DefaultFormFailed(
                                  controller:
                                      controller.sponsorshipAmountController,
                                  type: TextInputType.number,
                                  validate: (value) =>
                                      (controller.needsSponsorship &&
                                          (value == null || value.isEmpty))
                                      ? 'sponsorship_amount_error'.tr
                                      : null,
                                  lable: 'sponsorship_amount_label'.tr,
                                  prefix: Icons.monetization_on_outlined,
                                ),
                                const SizedBox(height: 15),
                                DefaultFormFailed(
                                  controller: controller.packageTypeController,
                                  type: TextInputType.text,
                                  validate: (value) =>
                                      (controller.needsSponsorship &&
                                          (value == null || value.isEmpty))
                                      ? 'package_type_error'.tr
                                      : null,
                                  lable: 'package_type_label'.tr,
                                  prefix: Icons.card_membership_outlined,
                                ),
                              ],
                            ],
                            const SizedBox(height: 40),
                            // زر حفظ التغييرات
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: controller.isLoading
                                    ? null
                                    : () => controller.updateProfile(),
                                child: controller.isLoading
                                    ? CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                      )
                                    : Text(
                                        'save_changes'.tr,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            // زر الانتقال لشاشة تغيير كلمة المرور
                            Center(
                              child: TextButton.icon(
                                onPressed: () =>
                                    Get.to(() => const ChangePasswordScreen()),
                                icon: const Icon(Icons.lock_reset),
                                label: Text(
                                  'change_password_title'.tr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // غطاء حماية وشاشة تحميل تظهر عند جلب البيانات لأول مرة
              if (controller.isLoading &&
                  controller.nameController.text.isEmpty)
                Container(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  // نافذة تأكيد لتغيير حالة الكفالة مع رسائل مخصصة تدعم الترجمة
  void _showSponsorshipConfirmation(
    BuildContext context,
    TeacherProfileController controller,
    bool newValue,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              newValue ? Icons.info_outline : Icons.warning_amber_rounded,
              color: newValue ? colorScheme.primary : colorScheme.error,
            ),
            const SizedBox(width: 10),
            Text(
              'alert'.tr,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // استدعاء رسالة التفعيل أو الإلغاء من ملف الترجمة
        content: Text(
          newValue ? 'sponsorship_enable_msg'.tr : 'sponsorship_disable_msg'.tr,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(fontFamily: 'Cairo', color: colorScheme.outline),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newValue
                  ? colorScheme.primary
                  : colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              controller.setNeedsSponsorship(newValue);
              Get.back();
            },
            child: Text(
              'confirm_btn'.tr,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء عنوان القسم بتنسيق موحد
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Cairo',
      ),
    );
  }

  // دالة مساعدة لبناء بطاقة عرض بيانات أكاديمية (أيقونة، مسمى، قيمة)
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: colorScheme.primary.withValues(alpha: 0.6),
                size: 28,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
