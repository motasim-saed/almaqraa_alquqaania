import 'package:flutter/material.dart';
import '../../controller/chat_room_controller.dart';

/// شريط القوالب السريعة لتقديم الطلبات والاستئذان
class ChatRequestTemplatesBar extends StatelessWidget {
  final ChatRoomController controller;

  const ChatRequestTemplatesBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.dashboard_customize_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'قوالب الطلبات:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildTemplateChip(
                    context,
                    label: 'طلب استئذان',
                    icon: Icons.event_note,
                    color: Colors.amber.shade800,
                    onTap: () => controller.applyTemplate(
                      '📋 [طلب استئذان / إجازة]\n'
                      '• السبب: \n'
                      '• الفترة: من [  ] إلى [  ]\n'
                      '• تفاصيل إضافية: ',
                    ),
                  ),
                  _buildTemplateChip(
                    context,
                    label: 'تقديم شكوى',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    onTap: () => controller.applyTemplate(
                      '⚠️ [تقديم شكوى / ملاحظة]\n'
                      '• موضوع الشكوى: \n'
                      '• التفاصيل: \n'
                      '• المقترح لحل المشكلة: ',
                    ),
                  ),
                 
                  _buildTemplateChip(
                    context,
                    label: 'استفسار عام',
                    icon: Icons.help_outline_rounded,
                    color: Colors.indigo,
                    onTap: () => controller.applyTemplate(
                      '❓ [استفسار للإدارة]\n'
                      '• الموضوع: \n'
                      '• نص الاستفسار: ',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        backgroundColor: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: onTap,
      ),
    );
  }
}
