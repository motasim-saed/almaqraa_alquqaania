import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/notification_model.dart';
import '../../repository/supabase_admin_repository.dart';
import '../../controller/admin_layout_controller.dart';
import '../../../Coordinator/controller/coordinator_layout_controller.dart';
import '../../../core/controllers/global_batch_controller.dart';

class AdminSentNotificationsScreen extends StatefulWidget {
  const AdminSentNotificationsScreen({super.key});

  @override
  State<AdminSentNotificationsScreen> createState() =>
      _AdminSentNotificationsScreenState();
}

class _AdminSentNotificationsScreenState
    extends State<AdminSentNotificationsScreen> {
  final _repository = SupabaseAdminRepository();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  
  // دالة ذكية للوصول لمتحكم البحث بأمان
  TextEditingController? get _activeSearchController {
    if (Get.isRegistered<AdminLayoutController>()) return Get.find<AdminLayoutController>().searchController;
    if (Get.isRegistered<CoordinatorLayoutController>()) return Get.find<CoordinatorLayoutController>().searchController;
    return null;
  }
      
  final _batchController = Get.find<GlobalBatchController>();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    ever(_batchController.selectedBatch, (_) => _fetchNotifications());
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await _repository.getSentNotifications();
      if (mounted) {
        setState(() {
          _notifications = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar('error'.tr, e.toString(), backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    }
  }

  List<NotificationModel> get _filteredNotifications {
    final query = _activeSearchController?.text.toLowerCase() ?? "";
    final selectedBatch = _batchController.selectedBatch.value;

    return _notifications.where((notif) {
      bool matchesBatch = selectedBatch == null || notif.batchNumber == selectedBatch;
      bool matchesQuery = notif.title.toLowerCase().contains(query) || notif.body.toLowerCase().contains(query);
      return matchesBatch && matchesQuery;
    }).toList();
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final success = await _repository.deleteNotification(id);
      if (success) {
        Get.snackbar('success'.tr, 'notification_deleted_successfully'.tr, backgroundColor: Colors.green, colorText: Colors.white);
        _fetchNotifications();
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _showEditDialog(NotificationModel notification) async {
    final titleController = TextEditingController(text: notification.title);
    final bodyController = TextEditingController(text: notification.body);
    String targetRole = notification.targetRole;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await Get.defaultDialog(
      title: 'edit_notification'.tr,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      titleStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Cairo'),
              decoration: InputDecoration(
                labelText: 'edit_title'.tr, 
                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: bodyController,
              maxLines: 3,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Cairo'),
              decoration: InputDecoration(
                labelText: 'edit_body'.tr, 
                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12)),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: targetRole,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Cairo'),
              items: [
                DropdownMenuItem(value: 'all', child: Text('all'.tr)),
                DropdownMenuItem(value: 'teacher', child: Text('teachers'.tr)),
                DropdownMenuItem(value: 'student', child: Text('students'.tr)),
                DropdownMenuItem(value: 'examiner', child: Text('examiners'.tr)),
              ],
              onChanged: (val) { if (val != null) targetRole = val; },
              decoration: InputDecoration(labelText: 'target_group'.tr, labelStyle: const TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
      textConfirm: 'save'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF4F46E5),
      onConfirm: () async {
        final success = await _repository.updateNotification(notification.id, titleController.text.trim(), bodyController.text.trim(), targetRole);
        Get.back();
        if (success) _fetchNotifications();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('sent_notifications'.tr, 
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5), // Indigo color
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        final filteredList = _filteredNotifications;
        if (_isLoading) return const Center(child: CircularProgressIndicator());

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 80, color: isDarkMode ? Colors.white10 : Colors.grey[200]),
                const SizedBox(height: 16),
                Text('no_sent_notifications'.tr, 
                  style: TextStyle(color: isDarkMode ? Colors.grey : Colors.grey[600], fontFamily: 'Cairo')
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _fetchNotifications,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final notif = filteredList[index];
              final dateStr = DateFormat('hh:mm a  yyyy/MM/dd', Get.locale?.languageCode ?? 'ar').format(notif.createdAt);

              return Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(4),
                    ),
                    border: Border.all(
                      color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.indigo.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: isDarkMode ? const Color(0xFF818CF8) : const Color(0xFF4F46E5), 
                                  fontSize: 16, 
                                  fontFamily: 'Cairo'
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit_note_rounded, color: isDarkMode ? Colors.white60 : Colors.grey[600], size: 26),
                                  onPressed: () => _showEditDialog(notif),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: isDarkMode ? Colors.redAccent.withValues(alpha: 0.6) : Colors.redAccent, size: 22),
                                  onPressed: () async {
                                    bool confirm = await Get.defaultDialog(
                                      title: 'confirm_delete'.tr,
                                      middleText: 'delete_notification_confirm_msg'.tr,
                                      textConfirm: 'yes_delete'.tr,
                                      textCancel: 'cancel'.tr,
                                      onConfirm: () => Get.back(result: true),
                                    ) ?? false;
                                    if (confirm) _deleteNotification(notif.id);
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notif.body,
                          style: TextStyle(
                            fontSize: 15, 
                            color: isDarkMode ? Colors.grey[300] : const Color(0xFF334155), 
                            height: 1.6, 
                            fontFamily: 'Cairo'
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.done_all, color: isDarkMode ? Colors.blue[400] : Colors.blue[600], size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  dateStr, 
                                  style: TextStyle(
                                    fontSize: 10, 
                                    color: isDarkMode ? Colors.grey[500] : Colors.grey[500], 
                                    fontFamily: 'Cairo'
                                  )
                                ),
                              ],
                            ),
                            _buildBadge(notif.targetRole.tr, isDarkMode),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildBadge(String text, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text, 
        style: TextStyle(
          fontSize: 10, 
          color: isDarkMode ? Colors.white70 : const Color(0xFF4F46E5), 
          fontWeight: FontWeight.bold, 
          fontFamily: 'Cairo'
        )
      ),
    );
  }
}
