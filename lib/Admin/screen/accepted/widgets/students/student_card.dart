import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import 'package:url_launcher/url_launcher.dart'; // استيراد مكتبة فتح الروابط الخارجية
import '../../../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالأدمن
import '../../../../controller/accepted/accepted_students_controller.dart'; // استيراد متحكم الطلاب المقبولين
import 'student_details_dialog.dart'; // استيراد نافذة تفاصيل الطالب
import 'student_transfer_dialog.dart'; // استيراد نافذة نقل/توزيع الطالب

// بطاقة الطالب المقبول - StudentCard
class StudentCard extends StatelessWidget {
  final StudentModel item; // نموذج بيانات الطالب
  final AcceptedStudentsController controller; // نسخة من المتحكم لإجراء العمليات

  // بناء الكلاس مع المعاملات المطلوبة
  const StudentCard({super.key, required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    // التحقق من حالة الثيم
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // تحديد لون الثيم بناءً على جنس الطالب
    final Color themeColor = item.gender == Gender.male 
        ? (isDarkMode ? Colors.indigoAccent : Theme.of(context).primaryColor)
        : (isDarkMode ? Colors.pinkAccent : Colors.pink);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.2) 
              : Colors.indigo.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black45 : Colors.indigo.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => StudentDetailsDialog.show(context, item, controller),
            child: Stack(
              children: [
                _PositionRectangle(color: themeColor.withValues(alpha: 0.07)),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildAvatar(context, themeColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${'level'.tr}: ${item.level.tr}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).hintColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(), 
                      Divider(
                        height: 24, 
                        thickness: 1.0,
                        color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)
                      ), 
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'circle'.tr,
                                  style: TextStyle(
                                    fontSize: 10, 
                                    color: isDarkMode ? Colors.white70 : Theme.of(context).hintColor,
                                  ),
                                ),
                                Text(
                                  item.isDistributed 
                                      ? (item.circleName != null ? item.circleName! : 'distributed'.tr) 
                                      : 'not_distributed'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: themeColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(item.isDistributed),
                        ],
                      ),
                      
                      const SizedBox(height: 12), 
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // زر واتساب في القائمة المنبثقة
                          if (item.phone.isNotEmpty)
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: themeColor,
                                size: 20,
                              ),
                              tooltip: 'خيارات',
                              onSelected: (value) async {
                                if (value == 'whatsapp') {
                                  final rawPhone = item.phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
                                  final whatsappUri = Uri.parse('https://wa.me/$rawPhone');
                                  if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
                                    Get.snackbar(
                                      'تنبيه',
                                      'تعذّر فتح واتساب',
                                      backgroundColor: Colors.redAccent,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'whatsapp',
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF25D366),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chat_rounded,
                                          color: Colors.white,
                                          size: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'تواصل بالواتساب',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 13,
                                          color: Color(0xFF25D366),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(width: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: themeColor.withValues(alpha: 0.2), width: 1),
                            ),
                            child: IconButton(
                              icon: Icon(
                                item.isDistributed ? Icons.transfer_within_a_station : Icons.add_task,
                                color: themeColor,
                                size: 20,
                              ),
                              tooltip: item.isDistributed ? 'transfer'.tr : 'distribute'.tr,
                              onPressed: () => StudentTransferDialog.show(context, item, controller),
                              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: (isDarkMode ? Colors.redAccent.shade100 : Theme.of(context).colorScheme.error).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: (isDarkMode ? Colors.redAccent.shade100 : Theme.of(context).colorScheme.error).withValues(alpha: 0.2), width: 1),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: isDarkMode ? Colors.redAccent.shade100 : Theme.of(context).colorScheme.error,
                                size: 20,
                              ),
                              tooltip: 'delete'.tr,
                              onPressed: () => _confirmDelete(context, item, controller),
                              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Icon(
        item.gender == Gender.male ? Icons.person_rounded : Icons.person_3_rounded,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildStatusBadge(bool isDistributed) {
    final Color statusColor = isDistributed ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        isDistributed ? 'distributed'.tr : 'not_distributed'.tr,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    );
  }

  // دالة لعرض حوار تأكيد حذف الطالب
  void _confirmDelete(BuildContext context, StudentModel student, AcceptedStudentsController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'confirm_delete'.tr,
          style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          '${'delete_confirm_msg'.tr} ${student.name}?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(), 
            child: Text('cancel'.tr, style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey))
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.removeUser(student.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}

// ودجت تزييني لرسم دائرة في خلفية البطاقة
class _PositionRectangle extends StatelessWidget {
  final Color color;
  const _PositionRectangle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -25,
      right: -25,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
