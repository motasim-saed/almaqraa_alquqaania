import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:al_maqraa/Admin/models/admin_models.dart';
import '../controller/chat_room_controller.dart';
import 'chat_widgets/chat_app_bar.dart';
import 'chat_widgets/chat_message_bubble.dart';
import 'chat_widgets/chat_input_bar.dart';
import 'chat_widgets/chat_request_templates_bar.dart';
import 'chat_widgets/chat_empty_state.dart';

/// شاشة الدردشة الرسمية والمباشرة بين المستخدم والإدارة / المنسق
/// تتيح إرسال الطلبات والاستئذان والشكاوى بالقوالب الجاهزة ومتابعة المحادثة لتبادل المعلومات
class ChatScreen extends StatelessWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;
  final String? chatType;
  final List<MessageModel>? forwardedMessages;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    this.chatType,
    this.forwardedMessages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final controller = Get.put(
      ChatRoomController(
        otherUserId: otherUserId,
        chatType: chatType,
        forwardedMessages: forwardedMessages,
      ),
      tag: otherUserId,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ChatAppBar(
        controller: controller,
        otherUserName: otherUserName,
        otherUserRole: otherUserRole,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // قائمة الرسائل
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.messages.isEmpty) {
                  return ChatEmptyState(controller: controller);
                }

                return ListView.builder(
                  controller: controller.scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    final isMe = message.senderId ==
                        controller.supabase.auth.currentUser?.id;

                    bool showDateHeader = false;
                    if (index == 0) {
                      showDateHeader = true;
                    } else {
                      final prevMessage = controller.messages[index - 1];
                      if (message.createdAt.year != prevMessage.createdAt.year ||
                          message.createdAt.month != prevMessage.createdAt.month ||
                          message.createdAt.day != prevMessage.createdAt.day) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateHeader)
                          ChatDateHeader(date: message.createdAt),
                        ChatMessageBubble(
                          controller: controller,
                          message: message,
                          isMe: isMe,
                        ),
                      ],
                    );
                  },
                );
              }),
            ),

            // شريط القوالب السريعة للطلبات (يظهر للمستخدم/الطالب/المعلم ويختفي للمنسق والإدارة)
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

              if (isCoordinatorOrAdmin) {
                return const SizedBox.shrink();
              }

              return ChatRequestTemplatesBar(controller: controller);
            }),

            // شريط إدخال وإرسال الرسائل
            ChatInputBar(controller: controller),
          ],
        ),
      ),
    );
  }
}
