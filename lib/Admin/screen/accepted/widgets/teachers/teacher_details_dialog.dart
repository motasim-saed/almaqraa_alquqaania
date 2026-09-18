import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالأدمن
import '../../../../controller/accepted/accepted_teachers_controller.dart'; // استيراد متحكم المعلمين المقبولين
import '../../../../../core/controllers/global_batch_controller.dart'; // استيراد متحكم الدفعات
import '../../../../../core/utils/clipboard_utils.dart'; // استيراد دالة النسخ إلى الحافظة
import '../detail_row_widget.dart'; // استيراد ودجت عرض تفاصيل الصف

// حوار تفاصيل المعلم - TeacherDetailsDialog
class TeacherDetailsDialog {
  static void show(
    BuildContext context, 
    TeacherModel teacher, 
    AcceptedTeachersController controller, 
  ) {
    final amountController = TextEditingController(
      text: teacher.sponsorshipAmount?.toString() ?? '', 
    );
    final packageController = TextEditingController(
      text: teacher.packageType ?? '', 
    );
    final needsSponsorship = (!teacher.canCoverBalance).obs;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: theme.cardColor,
        surfaceTintColor: Colors.transparent, // منع تغير اللون التلقائي في الماتيريال 3
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDarkMode ? BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.2) : BorderSide.none,
        ),
        title: Text(
          teacher.name,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.indigo.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: 500, // تحديد عرض مناسب للديالوج على الشاشات الكبيرة
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صفوف التفاصيل - تدعم الثيم تلقائياً من خلال DetailRowWidget
                DetailRowWidget(icon: Icons.phone, label: 'phone'.tr, value: teacher.phone),
                if (teacher.age != null)
                  DetailRowWidget(icon: Icons.cake, label: 'age'.tr, value: teacher.age.toString()),
                DetailRowWidget(icon: Icons.email, label: 'email'.tr, value: teacher.email),
                DetailRowWidget(icon: Icons.numbers, label: 'academic_number'.tr, value: teacher.academicNumber),
                
                if (teacher.academicQualification != null && teacher.academicQualification!.isNotEmpty)
                  DetailRowWidget(
                    icon: Icons.history_edu,
                    label: 'academic_qualification'.tr,
                    value: teacher.academicQualification!,
                  ),
                
                // التخصص - جعلناه يبرز بلون متناسق
                DetailRowWidget(
                  icon: Icons.school,
                  label: 'specialization'.tr,
                  value: teacher.specialization,
                ),
                
                Obx(() {
                  final batchController = Get.isRegistered<GlobalBatchController>() 
                      ? Get.find<GlobalBatchController>() 
                      : Get.put(GlobalBatchController());
                  
                  final batches = batchController.availableBatches.toList();
                  if (teacher.batchNumber != null && !batches.contains(teacher.batchNumber)) {
                    batches.add(teacher.batchNumber!);
                  }
                  batches.sort();

                  // متغير محلي لتخزين الدفعة المحددة حتى تتحدث واجهة المستخدم فوراً
                  final currentBatch = controller.acceptedTeachers.firstWhereOrNull((t) => t.id == teacher.id)?.batchNumber ?? teacher.batchNumber;

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
                                controller.updateBatch(teacher.id, newVal);
                              }
                            },
                          ),
                        ), 
                      ],
                    ),
                  );
                }),
                DetailRowWidget(
                  icon: Icons.calendar_today,
                  label: 'joining_date'.tr,
                  value: teacher.date,
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 1),
                ),
                
                // عنوان تفاصيل الكفالة - لون زاهٍ وواضح جداً في الثيم الغامق
                Text(
                  'sponsorship_details'.tr,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.indigoAccent : Colors.indigo.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // مفتاح تبديل حالة الكفالة - تحسين الألوان
                Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'needs_sponsorship'.tr,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      value: needsSponsorship.value,
                      activeColor: isDarkMode ? Colors.indigoAccent : theme.primaryColor,
                      onChanged: (val) => needsSponsorship.value = val,
                    ),
                  ),
                ),

                Obx(
                  () => AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: needsSponsorship.value
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                TextField(
                                  controller: amountController,
                                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'sponsorship_amount'.tr,
                                    labelStyle: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey.shade600),
                                    prefixIcon: Icon(Icons.monetization_on, color: isDarkMode ? Colors.indigoAccent : Colors.indigo),
                                    filled: true,
                                    fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: packageController,
                                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'package_type'.tr,
                                    labelStyle: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey.shade600),
                                    prefixIcon: Icon(Icons.card_membership, color: isDarkMode ? Colors.indigoAccent : Colors.indigo),
                                    filled: true,
                                    fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          // زر نسخ كامل بيانات المعلم
          TextButton.icon(
            onPressed: () => copyToClipboard(_buildAllDataText(teacher)),
            icon: Icon(
              Icons.copy_all_rounded,
              size: 18,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
            label: Text(
              'copy_all_data'.tr,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // زر إغلاق
          TextButton(
            onPressed: () => Get.back(), 
            child: Text(
              'close'.tr,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            )
          ),
          // زر الحفظ - جعله بارزاً جداً مع لون نص أبيض ناصع
          ElevatedButton.icon(
            onPressed: () {
              _showConfirmDialog(context, teacher, needsSponsorship, amountController, packageController, controller, isDarkMode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.indigoAccent : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.black45,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.save_rounded, size: 20, color: Colors.white),
            label: Text(
              'save'.tr, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }

  // حوار التأكيد عند الحفظ
  static void _showConfirmDialog(
    BuildContext context,
    TeacherModel teacher,
    RxBool needsSponsorship,
    TextEditingController amountController,
    TextEditingController packageController,
    AcceptedTeachersController controller,
    bool isDarkMode,
  ) {
    Get.defaultDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: 'confirm_sponsorship_change'.tr,
      titleStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'sponsorship_change_explanation'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
      ),
      textConfirm: 'confirm'.tr,
      textCancel: 'close'.tr,
      confirmTextColor: Colors.white,
      cancelTextColor: isDarkMode ? Colors.white60 : Colors.black54,
      buttonColor: isDarkMode ? Colors.indigoAccent : Theme.of(context).primaryColor,
      onConfirm: () {
        if (needsSponsorship.value) {
          final parsedAmount = double.tryParse(amountController.text.trim());
          if (parsedAmount == null || parsedAmount <= 0) {
            Get.snackbar(
              'error'.tr,
              'enter_valid_sponsorship_amount'.tr,
              backgroundColor: Colors.redAccent,
              colorText: Colors.white,
            );
            return;
          }
        }
        Get.back();
        Get.back();
        controller.updateSponsorship(
          teacher,
          needsSponsorship: needsSponsorship.value,
          amount: needsSponsorship.value
              ? double.tryParse(amountController.text.trim())
              : null,
          package: needsSponsorship.value && packageController.text.trim().isNotEmpty
              ? packageController.text.trim()
              : null,
        );
      },
    );
  }

  // بناء نص يحتوي على كامل بيانات المعلم لنسخه دفعة واحدة
  static String _buildAllDataText(TeacherModel t) {
    final String gender = t.gender == Gender.male ? 'male'.tr : 'female'.tr;
    final List<String> lines = [
      '${'name'.tr}: ${t.name}',
      '${'email'.tr}: ${t.email}',
      '${'phone'.tr}: ${t.phone}',
      '${'academic_number'.tr}: ${t.academicNumber}',
      '${'gender'.tr}: $gender',
      if (t.age != null) '${'age'.tr}: ${t.age}',
      if (t.academicQualification != null && t.academicQualification!.isNotEmpty)
        '${'academic_qualification'.tr}: ${t.academicQualification}',
      '${'specialization'.tr}: ${t.specialization}',
      if (t.batchNumber != null) '${'batch_number'.tr}: ${t.batchNumber}',
      '${'joining_date'.tr}: ${t.date}',
      '${'sponsorship_status'.tr}: ${t.canCoverBalance ? 'not_needs_sponsorship'.tr : 'needs_sponsorship'.tr}',
      if (t.sponsorshipAmount != null) '${'sponsorship_amount'.tr}: ${t.sponsorshipAmount}',
      if (t.packageType != null && t.packageType!.isNotEmpty) '${'package_type'.tr}: ${t.packageType}',
    ];
    return lines.join('\n');
  }
}
