import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/chat_room_controller.dart';
// import '../../controller/chat_room_controller.dart';

/// شريط كتابة وإرسال الرسائل في المحادثة
class ChatInputBar extends StatelessWidget {
  final ChatRoomController controller;

  const ChatInputBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller.messageController,
                focusNode: controller.focusNode,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالتك أو ردك هنا...',
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final isSending = controller.isSending.value;
            final canSend = controller.hasText.value && !isSending;

            return Material(
              color: canSend
                  ? colorScheme.primary
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              shape: const CircleBorder(),
              elevation: canSend ? 2 : 0,
              child: InkWell(
                onTap: canSend ? () => controller.sendTextMessage() : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: canSend ? Colors.white : Colors.grey,
                          ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
