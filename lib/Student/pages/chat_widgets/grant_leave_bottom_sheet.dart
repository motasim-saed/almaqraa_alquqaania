import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/chat_room_controller.dart';

/// نافذة منح استئذان رسمي للطالب (ليوم واحد أو لعدة أيام/فترة)
class GrantLeaveBottomSheet {
  static void show(
    BuildContext context, {
    required ChatRoomController controller,
    required String studentName,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    bool isRangeMode = false;
    DateTime selectedDate = DateTime.now();
    DateTimeRange selectedRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 1)),
    );
    final notesController = TextEditingController(text: 'استئذان رسمي');
    bool sendConfirmation = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final daysCount = isRangeMode ? (selectedRange.duration.inDays + 1) : 1;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // مقبض السحب
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // العنوان والأيقونة
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.event_available_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'منح استئذان رسمي',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'للطالب: $studentName',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // اختيار نوع المدة (يوم واحد / عدة أيام)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => isRangeMode = false),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isRangeMode
                                    ? colorScheme.primary
                                    : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'يوم واحد',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: !isRangeMode
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => isRangeMode = true),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isRangeMode
                                    ? colorScheme.primary
                                    : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'عدة أيام / فترة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isRangeMode
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // اختيار التاريخ
                    Text(
                      isRangeMode ? 'فترة الاستئذان ($daysCount أيام):' : 'تاريخ الاستئذان:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        if (!isRangeMode) {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: theme.copyWith(colorScheme: colorScheme),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        } else {
                          final pickedRange = await showDateRangePicker(
                            context: context,
                            initialDateRange: selectedRange,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: theme.copyWith(colorScheme: colorScheme),
                                child: child!,
                              );
                            },
                          );
                          if (pickedRange != null) {
                            setModalState(() => selectedRange = pickedRange);
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                !isRangeMode
                                    ? DateFormat('EEEE، d MMMM yyyy', 'ar').format(selectedDate)
                                    : 'من ${DateFormat('d MMM', 'ar').format(selectedRange.start)} إلى ${DateFormat('d MMM yyyy', 'ar').format(selectedRange.end)} ($daysCount أيام)',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'تغيير',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // حقل الملاحظة أو السبب
                    Text(
                      'الملاحظة أو سبب الاستئذان:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'اكتب ملاحظة أو سبب الاستئذان...',
                        hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // خيار إرسال رسالة توثيقية في الشات
                    CheckboxListTile(
                      value: sendConfirmation,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: colorScheme.primary,
                      title: const Text(
                        'إرسال إشعار توثيق في المحادثة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          sendConfirmation = val ?? true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // أزرار التحكم
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'cancel'.tr,
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setModalState(() => isSubmitting = true);
                                    final success = await controller.grantStudentLeave(
                                      singleDate: isRangeMode ? null : selectedDate,
                                      dateRange: isRangeMode ? selectedRange : null,
                                      notes: notesController.text,
                                      sendConfirmationMessage: sendConfirmation,
                                    );
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                    if (success) {
                                      Get.snackbar(
                                        'نجاح',
                                        isRangeMode
                                            ? 'تم تسجيل الاستئذان للطالب لـ $daysCount أيام بنجاح وتحديث السجلات'
                                            : 'تم تسجيل الاستئذان للطالب بنجاح وتحديث السجلات',
                                        backgroundColor: Colors.green.shade700,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.TOP,
                                      );
                                    } else {
                                      Get.snackbar(
                                        'error'.tr,
                                        'تعذر حفظ الاستئذان، يرجى المحاولة لاحقاً',
                                        backgroundColor: Colors.red.shade700,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.TOP,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isRangeMode ? 'تأكيد ومنح الاستئذان ($daysCount أيام)' : 'تأكيد ومنح الاستئذان',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
