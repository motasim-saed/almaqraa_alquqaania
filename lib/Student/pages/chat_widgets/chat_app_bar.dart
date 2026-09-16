import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/chat_room_controller.dart';
// import '../controller/chat_room_controller.dart';
import 'package:al_maqraa/core/utils/app_cached_image.dart';
import 'grant_leave_bottom_sheet.dart';

/// الشريط العلوي لشاشة الدردشة
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatRoomController controller;
  final String otherUserName;
  final String otherUserRole;

  const ChatAppBar({
    super.key,
    required this.controller,
    required this.otherUserName,
    required this.otherUserRole,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Obx(() {
      if (controller.isSelectionMode.value) {
        return AppBar(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => controller.toggleSelectionMode(),
          ),
          title: Text(
            '${controller.selectedMessageIds.length} ${'selected'.tr}',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'delete'.tr,
              onPressed: () => _confirmDelete(context, controller),
            ),
          ],
        );
      }

      return AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ??
            (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Obx(() {
              final avatarUrl = controller.otherUserAvatarRx.value;
              final name = controller.otherUserNameRx.value.isNotEmpty
                  ? controller.otherUserNameRx.value
                  : otherUserName;
              return CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: AppCachedImage(
                          imageUrl: avatarUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              );
            }),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    final name = controller.otherUserNameRx.value.isNotEmpty
                        ? controller.otherUserNameRx.value
                        : otherUserName;
                    return Text(
                      name.isNotEmpty ? name : 'administration'.tr,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                  Obx(() {
                    final role = controller.otherUserRoleRx.value.isNotEmpty
                        ? controller.otherUserRoleRx.value
                        : otherUserRole;
                    return Text(
                      _formatRoleName(role),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Obx(() {
            // التحقق من أن المستخدم الحالي هو المنسق حصراً
            final myRole = controller.userRole.value.toLowerCase().trim();
            final isCoordinator = myRole == 'coordinator' || myRole == 'منسق';
            if (!isCoordinator) {
              return const SizedBox.shrink();
            }

            final otherRole = (controller.otherUserRoleRx.value.isNotEmpty
                    ? controller.otherUserRoleRx.value
                    : otherUserRole)
                .toLowerCase()
                .trim();
            final isTeacher = otherRole == 'teacher' || otherRole == 'معلم';
            final isStudent = otherRole == 'student' || otherRole == 'طالب' || otherRole.isEmpty || !isTeacher;

            // إظهار أيقونة التقويم لمنح الاستئذان فقط إذا كان الطرف الآخر طالباً
            if (!isStudent) {
              return const SizedBox.shrink();
            }

            final appBarBg = theme.appBarTheme.backgroundColor ??
                (isDark ? const Color(0xFF1E1E1E) : Colors.white);
            final bool isAppBarDark = ThemeData.estimateBrightnessForColor(appBarBg) == Brightness.dark;

            final Color actionBgColor = isAppBarDark
                ? Colors.white.withValues(alpha: 0.18)
                : colorScheme.primary.withValues(alpha: 0.12);
            final Color actionBorderColor = isAppBarDark
                ? Colors.white.withValues(alpha: 0.35)
                : colorScheme.primary.withValues(alpha: 0.35);
            final Color actionContentColor = isAppBarDark
                ? Colors.white
                : colorScheme.primary;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final currentStudentName = controller.otherUserNameRx.value.isNotEmpty
                        ? controller.otherUserNameRx.value
                        : otherUserName;
                    GrantLeaveBottomSheet.show(
                      context,
                      controller: controller,
                      studentName: currentStudentName,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: actionBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: actionBorderColor,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 20,
                          color: actionContentColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'استئذان',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: actionContentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  void _confirmDelete(BuildContext context, ChatRoomController controller) {
    Get.defaultDialog(
      title: 'delete'.tr,
      middleText: 'هل أنت متأكد من حذف الرسائل المحددة؟',
      textConfirm: 'yes'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.deleteSelectedMessages();
      },
    );
  }

  String _formatRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'coordinator':
        return 'منسق المقرأة';
      case 'admin':
        return 'إدارة المقرأة';
      case 'teacher':
        return 'معلم';
      case 'student':
        return 'طالب';
      case 'examiner':
        return 'مختبر';
      default:
        return 'مسؤول';
    }
  }
}
