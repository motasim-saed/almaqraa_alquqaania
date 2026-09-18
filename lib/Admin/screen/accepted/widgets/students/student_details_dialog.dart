import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالأدمن
import '../../../../controller/accepted/accepted_students_controller.dart'; // استيراد متحكم الطلاب المقبولين
import '../../../../../core/controllers/global_batch_controller.dart'; // استيراد متحكم الدفعات
import '../../../../../core/utils/clipboard_utils.dart'; // استيراد دالة النسخ إلى الحافظة
import '../detail_row_widget.dart'; // استيراد ودجت عرض تفاصيل الصف
import 'student_transfer_dialog.dart'; // استيراد نافذة نقل/توزيع الطالب

// حوار تفاصيل الطالب - StudentDetailsDialog
// يعرض كافة بيانات الطالب المقبول مع خيارات للنقل أو التوزيع
class StudentDetailsDialog {
  // دالة ستاتيكية لعرض الحوار دون الحاجة لإنشاء كائن من الكلاس
  static void show(
    BuildContext context, // سياق التطبيق
    StudentModel student, // نموذج بيانات الطالب المراد عرض تفاصيله
    AcceptedStudentsController controller, // المتحكم لإدارة العمليات
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Get.dialog(
      // استخدام GetX لفتح نافذة الحوار
      AlertDialog(
        // استخدام AlertDialog التقليدي
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ), // حواف دائرية للنافذة
        title: Text(student.name), // عرض اسم الطالب كعنوان للنافذة
        content: SizedBox(
          width: 500, // تحديد عرض مناسب
          child: SingleChildScrollView(
            child: Column(
              // محتوى النافذة في عمود
              mainAxisSize: MainAxisSize.min, // تصغير حجم العمود ليناسب المحتوى
              crossAxisAlignment:
                  CrossAxisAlignment.start, // محاذاة المحتوى للبداية
              children: [
                // عرض الجنس (ذكر أو أنثى) مع الأيقونة المناسبة
                DetailRowWidget(
                  icon: student.gender == Gender.male
                      ? Icons.male
                      : Icons.female, // تحديد الأيقونة حسب الجنس
                  label: 'gender'.tr, // نص "الجنس" مترجم
                  value: student.gender == Gender.male
                      ? 'male'.tr
                      : 'female'.tr, // قيمة الجنس مترجمة
                ),
                // عرض رقم الهاتف
                DetailRowWidget(
                  icon: Icons.phone,
                  label: 'phone'.tr,
                  value: student.phone,
                ),
                // عرض العمر (إذا وجد)
                if (student.age != null)
                  DetailRowWidget(
                    icon: Icons.cake,
                    label: 'age'.tr,
                    value: student.age.toString(),
                  ),
                // عرض البريد الإلكتروني للطالب
                DetailRowWidget(
                  icon: Icons.email, // أيقونة البريد
                  label: 'email'.tr, // نص "البريد الإلكتروني" مترجم
                  value: student.email, // قيمة البريد من الموديل
                ),
                // عرض الرقم الأكاديمي للطالب
                DetailRowWidget(
                  icon: Icons.numbers, // أيقونة الأرقام
                  label: 'academic_number'.tr, // نص "الرقم الأكاديمي" مترجم
                  value: student.academicNumber, // قيمة الرقم الأكاديمي
                ),
                // عرض الكود الخاص
    
                // عرض المؤهل الأكاديمي (إذا وجد)
                if (student.academicQualification != null &&
                    student.academicQualification!.isNotEmpty)
                  DetailRowWidget(
                    icon: Icons.history_edu,
                    label: 'academic_qualification'.tr,
                    value: student.academicQualification!,
                  ),
                // عرض المستوى الدراسي للطالب
                DetailRowWidget(
                  icon: Icons.grade, // أيقونة الدرجة أو المستوى
                  label: 'level'.tr, // نص "المستوى" مترجم
                  value: student.level.tr, // قيمة المستوى
                ),
                Obx(() {
                  final batchController = Get.isRegistered<GlobalBatchController>() 
                      ? Get.find<GlobalBatchController>() 
                      : Get.put(GlobalBatchController());
                  
                  final batches = batchController.availableBatches.toList();
                  if (student.batchNumber != null && !batches.contains(student.batchNumber)) {
                    batches.add(student.batchNumber!);
                  }
                  batches.sort();
    
                  final currentBatch = controller.acceptedStudents.firstWhereOrNull((s) => s.id == student.id)?.batchNumber ?? student.batchNumber;
    
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.batch_prediction,
                          size: 18,
                          color: isDarkMode ? Colors.indigoAccent : theme.primaryColor,
                        ), 
                        const SizedBox(width: 10), 
                        Text(
                          '${'batch_number'.tr}: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ), 
                        Expanded(
                          child: DropdownButton<int>(
                            value: currentBatch,
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: Icon(Icons.edit, size: 16, color: isDarkMode ? Colors.indigoAccent : theme.primaryColor),
                            dropdownColor: theme.cardColor,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                            items: batches.map((batch) {
                              return DropdownMenuItem<int>(
                                value: batch,
                                child: Text(batch.toString()),
                              );
                            }).toList(),
                            onChanged: (newVal) {
                              if (newVal != null && newVal != currentBatch) {
                                controller.updateBatch(student.id, newVal);
                              }
                            },
                          ),
                        ), 
                      ],
                    ),
                  );
                }),
                // عرض تاريخ التسجيل
                DetailRowWidget(
                  icon: Icons.calendar_month,
                  label: 'joining_date'.tr,
                  value: student.date,
                ),
                // عرض حالة التوزيع على حلقة قرآنية
                DetailRowWidget(
                  icon: Icons.check_circle, // أيقونة التحقق
                  label: 'status'.tr, // نص "الحالة" مترجم
                  value:
                      student
                          .isDistributed // التحقق مما إذا كان الطالب موزعاً أم لا
                      ? '${'distributed'.tr}${student.circleName != null ? ' - ${student.circleName}' : ''}' // عرض "موزع" مع اسم الحلقة
                      : 'not_distributed'.tr, // عرض "غير موزع"
                ),
              ],
            ),
          ),
        ),
        actions: [
          // أزرار العمليات أسفل الحوار
          // زر نسخ كامل بيانات الطالب
          TextButton.icon(
            onPressed: () => copyToClipboard(_buildAllDataText(student)),
            icon: const Icon(Icons.copy_all_rounded, size: 18),
            label: Text('copy_all_data'.tr),
          ),
          // زر إغلاق النافذة
          TextButton(onPressed: () => Get.back(), child: Text('close'.tr)),
          // زر التوزيع أو النقل بناءً على حالة الطالب
          ElevatedButton(
            onPressed: () {
              Get.back(); // إغلاق الحوار الحالي أولاً
              StudentTransferDialog.show(
                context,
                student,
                controller,
              ); // فتح حوار النقل/التوزيع
            },
            style: ElevatedButton.styleFrom(
              // تنسيق الزر
              backgroundColor: Colors.indigo, // لون الخلفية أزرق غامق
              foregroundColor: Colors.white, // لون النص أبيض
            ),
            child: Text(
              // نص الزر (نقل أو توزيع) مترجم
              student.isDistributed ? 'transfer'.tr : 'distribute'.tr,
            ),
          ),
        ],
      ),
    );
  }

  // بناء نص يحتوي على كامل بيانات الطالب لنسخه دفعة واحدة
  static String _buildAllDataText(StudentModel s) {
    final String gender = s.gender == Gender.male ? 'male'.tr : 'female'.tr;
    final String status = s.isDistributed
        ? '${'distributed'.tr}${s.circleName != null ? ' - ${s.circleName}' : ''}'
        : 'not_distributed'.tr;

    final List<String> lines = [
      '${'name'.tr}: ${s.name}',
      '${'email'.tr}: ${s.email}',
      '${'phone'.tr}: ${s.phone}',
      '${'academic_number'.tr}: ${s.academicNumber}',
      '${'gender'.tr}: $gender',
      if (s.age != null) '${'age'.tr}: ${s.age}',
      if (s.academicQualification != null && s.academicQualification!.isNotEmpty)
        '${'academic_qualification'.tr}: ${s.academicQualification}',
      '${'level'.tr}: ${s.level.tr}',
      if (s.batchNumber != null) '${'batch_number'.tr}: ${s.batchNumber}',
      '${'joining_date'.tr}: ${s.date}',
      '${'status'.tr}: $status',
    ];
    return lines.join('\n');
  }
}
