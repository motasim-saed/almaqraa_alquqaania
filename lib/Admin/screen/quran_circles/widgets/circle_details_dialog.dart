import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/admin_models.dart';
import '../../../controller/quran_circles_controller.dart';
import '../../../controller/accepted/accepted_students_controller.dart';
import 'add_circle_dialog.dart';

// حوار تفاصيل الحلقة - CircleDetailsDialog
// يعرض معلومات مفصلة عن حلقة معينة تشمل المعلم، المختبر، وقائمة الطلاب
class CircleDetailsDialog extends StatelessWidget {
  final QuranCircleModel circle;
  final bool isAdmin;
  const CircleDetailsDialog({super.key, required this.circle, this.isAdmin = true});

  @override
  Widget build(BuildContext context) {
    // الحصول على المتحكمات اللازمة لجلب بيانات الطلاب المرتبطين
    final circlesController = Get.find<QuranCirclesController>();
    final studentsController = Get.isRegistered<AcceptedStudentsController>() 
        ? Get.find<AcceptedStudentsController>() 
        : Get.put(AcceptedStudentsController());

    // تصفية الطلاب المنتمين لهذه الحلقة فقط
    final circleStudents = studentsController.acceptedStudents
        .where((s) => circle.studentIds.contains(s.id))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس الحوار: اسم الحلقة وزر الإغلاق
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  circle.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 32),
            // عرض المعلم المسؤول والمختبر المعين
            _buildInfoRow(Icons.person, 'teacher'.tr, circle.teacherName),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.fact_check,
              'exam_committee'.tr,
              circle.examinerName ?? 'not_assigned_yet'.tr,
            ),
            const SizedBox(height: 8),
            // إضافة عرض رقم الدفعة
            _buildInfoRow(
              Icons.tag,
              'batch_number'.tr,
              circle.batchNumber?.toString() ?? 'not_assigned_yet'.tr,
            ),
            const SizedBox(height: 16),
            // عنوان قائمة الطلاب مع عددهم
            Text(
              '${'students'.tr} (${circleStudents.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // قائمة الطلاب القابلة للتمرير
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: circleStudents.isEmpty
                  ? Center(child: Text('no_students'.tr))
                  : ListView.builder(
                      itemCount: circleStudents.length,
                      itemBuilder: (context, index) {
                        final s = circleStudents[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            radius: 18,
                            child: Icon(Icons.school, size: 18),
                          ),
                          title: Text(s.name),
                          subtitle: Text(s.level.tr),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            // أزرار التحكم (حذف / تعديل)
            if (isAdmin)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // زر حذف الحلقة مع حوار تأكيد
                  TextButton.icon(
                    onPressed: () {
                      Get.back();
                      _confirmDelete(circle.id, circlesController);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      'delete'.tr,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // زر تعديل بيانات الحلقة (يفتح حوار الإضافة في وضع التعديل)
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.dialog(AddCircleDialog(circle: circle));
                    },
                    icon: const Icon(Icons.edit),
                    label: Text('edit'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // بناء صف لعرض معلومة (أيقونة، عنوان، قيمة)
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  // نافذة تأكيد حذف الحلقة
  void _confirmDelete(String id, QuranCirclesController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_circle'.tr),
        content: Text('confirm_delete_circle'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              controller.deleteCircle(id);
              Get.back();
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
