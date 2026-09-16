import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:al_maqraa/Admin/models/admin_models.dart';
import '../../controller/chat_room_controller.dart';

/// ويدجت فقاعة الرسالة وترويسة التاريخ
class ChatMessageBubble extends StatelessWidget {
  final ChatRoomController controller;
  final MessageModel message;
  final bool isMe;

  const ChatMessageBubble({
    super.key,
    required this.controller,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final isSelected = controller.selectedMessageIds.contains(message.id);

      return GestureDetector(
        onLongPress: () {
          if (!controller.isSelectionMode.value) {
            controller.toggleSelectionMode();
          }
          controller.toggleMessageSelection(message.id);
        },
        onTap: () {
          if (controller.isSelectionMode.value) {
            controller.toggleMessageSelection(message.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          child: Align(
            alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? colorScheme.primary
                    : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F2F5)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 4 : 16),
                  bottomRight: Radius.circular(isMe ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // نص الرسالة
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      height: 1.5,
                      color: isMe
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // الوقت وحالة القراءة
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('hh:mm a').format(message.createdAt),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.75)
                              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// ويدجت ترويسة التاريخ الفاصلة بين أيام المحادثة
class ChatDateHeader extends StatelessWidget {
  final DateTime date;

  const ChatDateHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final chatDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (chatDate == today) {
      dateText = 'today'.tr;
    } else if (chatDate == yesterday) {
      dateText = 'yesterday'.tr;
    } else {
      dateText = DateFormat('EEEE, d MMMM', 'ar').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          dateText,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
