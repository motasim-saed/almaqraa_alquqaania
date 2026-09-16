import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../repository/supabase_admin_repository.dart';
import '../../controller/admin_layout_controller.dart';

/// شاشة إرسال الإشعارات بتصميم عصري يدعم الثيمين واللغتين
class AdminSendNotificationScreen extends StatefulWidget {
  const AdminSendNotificationScreen({super.key});

  @override
  State<AdminSendNotificationScreen> createState() => _AdminSendNotificationScreenState();
}

class _AdminSendNotificationScreenState extends State<AdminSendNotificationScreen> {
  final _repository = SupabaseAdminRepository();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _selectedTarget = 'all';
  bool _isSending = false;

  final List<Map<String, String>> _targetGroups = [
    {'key': 'all', 'label': 'all'},
    {'key': 'student', 'label': 'students'},
    {'key': 'teacher', 'label': 'teachers'},
    {'key': 'examiner', 'label': 'examiners'},
  ];

  void _sendNotification() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      Get.snackbar(
        'warning'.tr,
        'please_enter_title_and_body'.tr,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSending = true);
    
    try {
      final success = await _repository.sendNotification(title, body, _selectedTarget);
      setState(() => _isSending = false);

      if (success) {
        Get.snackbar(
          'success'.tr,
          'notification_sent_success'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      setState(() => _isSending = false);
      Get.snackbar('error'.tr, e.toString(), backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layoutController = Get.find<AdminLayoutController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // تعتمد على خلفية اللayout الأساسي
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان الرئيسي
            Text(
              'new_notification'.tr,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            
            // اختيار الفئة
            _buildLabel('send_to'.tr, isDark),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTarget,
                  isExpanded: true,
                  dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                  items: _targetGroups.map((target) {
                    return DropdownMenuItem<String>(
                      value: target['key'],
                      child: Text(target['label']!.tr, style: const TextStyle(fontFamily: 'Cairo')),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedTarget = value!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // العنوان
            _buildLabel('notification_title'.tr, isDark),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: _inputStyle('enter_title_here'.tr, isDark),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 20),

            // المحتوى
            _buildLabel('notification_body'.tr, isDark),
            const SizedBox(height: 10),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: _inputStyle('write_message_here'.tr, isDark),
              style: const TextStyle(fontFamily: 'Cairo', height: 1.5),
            ),
            const SizedBox(height: 35),

            // زر الإرسال الأساسي
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Text('send_now'.tr, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),

            // زر الإشعارات السابقة (بشكل أكبر وأوضح)
            GestureDetector(
              onTap: () => layoutController.changeIndex(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF374151), const Color(0xFF1F2937)] 
                      : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.history_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'view_history'.tr,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                            ),
                          ),
                          Text(
                            'view_previous_notifications'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded, 
                      size: 18, 
                      color: isDark ? Colors.grey[400] : const Color(0xFF4F46E5)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
        fontFamily: 'Cairo',
      ),
    );
  }

  InputDecoration _inputStyle(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
    );
  }
}
