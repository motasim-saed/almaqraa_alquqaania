import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:al_maqraa/core/controllers/profile_controller.dart';
import 'package:al_maqraa/Student/repository/supabase_student_repository.dart';
import 'package:al_maqraa/Student/pages/chat_screen.dart';
import '../controller/settings_controller.dart';
import '../routing/teacher_route.dart';
import '../../Student/pages/financial_support_page.dart';

/// القائمة الجانبية (Drawer) الخاصة بواجهة المعلم
class TeacherDrawer extends StatelessWidget {
  const TeacherDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب نسخة من متحكم الإعدادات للتعامل مع تسجيل الخروج وحذف الحساب
    final settingsController = Get.put(SettingsController());

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // إلغاء الحواف الافتراضية للقائمة
        children: [
          // رأس القائمة الجانبية - يعرض بيانات المعلم الحالية
          Obx(() {
            // جلب متحكم الملف الشخصي الأساسي لمراقبة البيانات
            final controller = Get.put(ProfileController());

            // التحقق من وجود صورة شخصية لاستخدامها كخلفية
            final hasAvatar = controller.avatarUrl.value.isNotEmpty;

            return UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                image: hasAvatar
                    ? DecorationImage(
                        image: NetworkImage(controller.avatarUrl.value),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(
                            alpha: 0.4,
                          ), // تعتيم الصورة لتوضيح النص
                          BlendMode.darken,
                        ),
                      )
                    : null,
                gradient: !hasAvatar
                    ? LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor, // اللون الأساسي
                          Theme.of(context).primaryColor.withValues(
                                alpha: 0.8,
                              ), // تدرج لوني
                        ],
                      )
                    : null,
              ),
              // عرض اسم المعلم أو كلمة "جاري التحميل"
              accountName: Text(
                controller.isLoading.value
                    ? 'loading'.tr
                    : controller.name.value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Cairo',
                ),
              ),
              // عرض البريد الإلكتروني واسم الحلقة المرتبط بها
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.isLoading.value ? '' : controller.email.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  if (controller.circleName.isNotEmpty)
                    Text(
                      '${'circle_colon'.tr} ${controller.circleName.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                ],
              ),
            );
          }),
          // زر الانتقال لتعديل الملف الشخصي
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'profile_edit'.tr,
            subtitle: 'drawer_subtitle_profile'.tr,
            color: Colors.blue,
            onTap: () => Get.toNamed(TeacherRoutes.profile),
          ),
          // زر متابعة الحفظ الشهري للطلاب
          _buildDrawerItem(
            icon: Icons.next_plan_outlined,
            title: 'monthly_followup'.tr,
            subtitle: 'drawer_subtitle_monthly_followup'.tr,
            color: Colors.green,
            onTap: () => Get.toNamed(TeacherRoutes.monthlyFollowUp),
          ),
          // زر رصد درجات الاختبارات الشهرية
          _buildDrawerItem(
            icon: Icons.assignment_turned_in_outlined,
            title: 'monthly_exams'.tr,
            subtitle: 'drawer_subtitle_monthly_exams'.tr,
            color: Colors.orange,
            onTap: () => Get.toNamed(TeacherRoutes.monthlyExam),
          ),
          // زر سجل التحضير اليومي للطلاب
          _buildDrawerItem(
            icon: Icons.rule_folder_outlined,
            title: 'attendance_record'.tr,
            subtitle: 'drawer_subtitle_attendance'.tr,
            color: Colors.teal,
            onTap: () => Get.toNamed(TeacherRoutes.dailyAttendance),
          ),
          // زر الإعدادات العامة (اللغة، الثيم، إلخ)
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'settings'.tr,
            subtitle: 'drawer_subtitle_settings'.tr,
            color: Colors.grey,
            onTap: () => Get.toNamed(TeacherRoutes.settings),
          ),
          // زر التواصل مع الإدارة وطلب الاستئذان
          _buildDrawerItem(
            icon: Icons.contact_support_outlined,
            title: 'contact_admin'.tr,
            subtitle: 'drawer_subtitle_contact_admin'.tr,
            color: Colors.purple,
            onTap: () async {
              Get.back(); // إغلاق الدروير أولاً
              final adminData =
                  await SupabaseStudentRepository().getFirstAdmin();
              if (adminData != null) {
                Get.to(
                  () => ChatScreen(
                    otherUserId: adminData['id'].toString(),
                    otherUserName:
                        adminData['full_name'] ??
                        (adminData['role'] == 'coordinator'
                            ? 'coordinator_label'.tr
                            : 'admin_label'.tr),
                    otherUserRole: adminData['role'] ?? 'admin',
                    chatType: 'leave_request', // نوع الدردشة طلب استئذان
                  ),
                );
              } else {
                Get.snackbar('alert'.tr, 'no_admin_found'.tr);
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.favorite_border_rounded,
            title: 'financial_support'.tr,
            subtitle: 'drawer_subtitle_financial_support'.tr,
            color: Colors.pink,
            onTap: () => Get.to(() => FinancialSupportPage()),
          ),
          _buildDrawerItem(
            icon: Icons.support_agent_rounded,
            title: 'tech_support'.tr,
            subtitle: 'tech_support_details'.tr,
            color: Colors.teal,
            onTap: () => Get.toNamed('/tech_support'),
          ),
          const Divider(), // فاصل بين القائمة والخيارات الحساسة (الخروج والحذف)
          // زر تسجيل الخروج مع تأكيد
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'logout'.tr,
            subtitle: 'drawer_subtitle_logout'.tr,
            color: Colors.orange,
            onTap: () => _confirmAction(
              title: 'logout'.tr,
              message: 'confirm_logout_msg'.tr,
              onConfirm: () => settingsController.logout(),
              confirmColor: Colors.orange,
            ),
          ),
          // زر حذف الحساب نهائياً مع تأكيد شديد
          _buildDrawerItem(
            icon: Icons.delete_forever,
            title: 'delete_account'.tr,
            subtitle: 'drawer_subtitle_delete_account'.tr,
            color: Colors.red,
            onTap: () => _confirmAction(
              title: 'delete_account'.tr,
              message: 'delete_account_confirm_msg'.tr,
              onConfirm: () => settingsController.deleteAccount(),
              confirmColor: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// وظيفة مساعدة لبناء عنصر قائمة منسق
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color), // أيقونة العنصر
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'Cairo'),
      ), // عنوان العنصر المترجم
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing:
          badgeCount > 0
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
      onTap: () {
        Get.back(); // إغلاق القائمة الجانبية دوماً قبل أي انتقال
        onTap(); // تنفيذ الانتقال المطلوب
      },
    );
  }

  /// وظيفة لإظهار مربع حوار تأكيد قبل العمليات الحساسة
  void _confirmAction({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required Color confirmColor,
  }) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: 'yes'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: confirmColor,
      onConfirm: () {
        Get.back(); // إغلاق الحوار
        onConfirm(); // تنفيذ العملية المؤكدة
      },
      titleStyle: const TextStyle(fontFamily: 'Cairo'),
      middleTextStyle: const TextStyle(fontFamily: 'Cairo'),
    );
  }
}
