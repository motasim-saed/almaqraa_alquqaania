import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/chat_room_controller.dart';
// import '../controller/chat_room_controller.dart';

/// واجهة عند عدم وجود رسائل في المحادثة
class ChatEmptyState extends StatelessWidget {
  final ChatRoomController controller;

  const ChatEmptyState({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent_rounded,
                size: 50,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Obx(() {
              final currentRole = controller.userRole.value.toLowerCase();
              final isCoordinatorOrAdmin = [
                'coordinator',
                'admin',
                'supervisor',
                'manager',
                'منسق',
                'إدارة',
                'مدير',
              ].contains(currentRole);

              return Text(
                isCoordinatorOrAdmin ? 'محادثة وتواصل مباشر' : 'تواصل رسمي مع الإدارة والمنسق',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: theme.textTheme.bodyLarge?.color,
                ),
              );
            }),
            const SizedBox(height: 8),
            Obx(() {
              final currentRole = controller.userRole.value.toLowerCase();
              final isCoordinatorOrAdmin = [
                'coordinator',
                'admin',
                'supervisor',
                'manager',
                'منسق',
                'إدارة',
                'مدير',
              ].contains(currentRole);

              final hintText = isCoordinatorOrAdmin
                  ? 'محادثة مباشرة للتواصل والرد على الاستفسارات ومتابعة الطلبات الموجهة إليك.'
                  : 'يمكنك اختيار نوع طلبك من القوالب السريعة بالأسفل، أو كتابة رسالتك مباشرة لتبادل المعلومات ومتابعة الطلب.';

              return Text(
                hintText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: theme.hintColor,
                  fontFamily: 'Cairo',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
