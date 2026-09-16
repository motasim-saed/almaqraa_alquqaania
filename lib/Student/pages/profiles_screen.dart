import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:al_maqraa/Student/controller/student_profile_controller.dart';
import '../../../components/form_failed.dart';
import '../../Teacher/screen/profile/change_password_screen.dart';
import '../../core/utils/app_cached_image.dart';
import '../../core/utils/full_screen_image_viewer.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // ألوان التدرج المميزة للطالب
    final studentPrimary = isDark
        ? const Color(0xFF1A237E)
        : const Color(0xFF283593);
    final studentSecondary = isDark
        ? const Color(0xFF0D47A1)
        : const Color.fromARGB(255, 36, 173, 211);
    final studentAccent = isDark
        ? const Color(0xFF006064)
        : const Color.fromARGB(255, 141, 228, 224);

    return GetBuilder<StudentProfileController>(
      init: StudentProfileController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              'profile_edit'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            centerTitle: true,
            backgroundColor: studentPrimary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    // قسم الهيدر بتدرج لوني مميز للطالب
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            studentPrimary,
                            studentSecondary,
                            studentAccent,
                            theme.scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: kToolbarHeight + 20),
                          // الصورة الشخصية مع زر التعديل
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
                                          tag: 'avatar_student',
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
                                              tag: 'avatar_student',
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
                          // اسم الطالب
                          Text(
                            controller.nameController.text.isEmpty
                                ? 'student_name'.tr
                                : controller.nameController.text,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          // دور الطالب
                          Text(
                            'role_student'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white70 : Colors.white70,
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
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('basic_info'.tr),
                            const SizedBox(height: 15),
                            DefaultFormFailed(
                              controller: controller.nameController,
                              type: TextInputType.name,
                              validate: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'full_name_error'.tr
                                  : null,
                              lable: 'full_name'.tr,
                              prefix: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 15),
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

                            // قسم إعدادات الفئة
                            const SizedBox(height: 25),
                            _buildSectionTitle('category_settings'.tr),
                            const SizedBox(height: 15),
                            Obx(
                              () => DropdownButtonFormField<String>(
                                value: controller.selectedCategory.value,
                                dropdownColor: theme.cardColor,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.category_outlined,
                                    color: colorScheme.primary,
                                  ),
                                  labelText: 'category'.tr,
                                  labelStyle: const TextStyle(
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                items: controller.categoryKeys
                                    .map(
                                      (key) => DropdownMenuItem(
                                        value: key,
                                        child: Text(
                                          key.tr,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => val != null
                                    ? controller.selectedCategory.value = val
                                    : null,
                              ),
                            ),

                            // قسم البيانات الأكاديمية
                            const SizedBox(height: 25),
                            _buildSectionTitle('academic_info'.tr),
                            const SizedBox(height: 15),
                            _buildInfoCard(
                              icon: Icons.email_outlined,
                              label: 'email'.tr,
                              value: controller.emailController.text,
                            ),
                            _buildInfoCard(
                              icon: Icons.batch_prediction_outlined,
                              label: 'batch_number'.tr,
                              value: controller.batchNumberController.text,
                            ),
                            _buildInfoCard(
                              icon: Icons.numbers_outlined,
                              label: 'academic_number'.tr,
                              value: controller.academicNumberController.text,
                            ),
                            _buildInfoCard(
                              icon: Icons.groups_outlined,
                              label: 'circle_name'.tr,
                              value:
                                  controller.circleNameController.text.isEmpty
                                  ? 'no_circle_currently'.tr
                                  : controller.circleNameController.text,
                            ),
                            _buildInfoCard(
                              icon: Icons.person_search_outlined,
                              label: 'teacher'.tr,
                              value:
                                  controller.teacherNameController.text.isEmpty
                                  ? 'not_available'.tr
                                  : controller.teacherNameController.text,
                            ),

                            const SizedBox(height: 40),
                            // زر حفظ التغييرات
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: studentSecondary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () => controller.updateProfile(),
                                child: controller.isLoading.value
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
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
                            // زر تغيير كلمة المرور
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
              // شاشة التحميل
              if (controller.isLoading.value &&
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

  // عنوان القسم
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

  // بطاقة عرض بيانات أكاديمية
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

