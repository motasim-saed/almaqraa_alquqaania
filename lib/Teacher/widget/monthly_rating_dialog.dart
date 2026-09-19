import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Teacher/controller/monthly_rating_controller.dart';
import '../../Teacher/models/monthly_rating_model.dart';
import '../../core/utils/app_constants.dart';

/// حوار إضافة/تعديل التقييم الشهري — اختيار من 5 مستويات (وليس كتابة)
/// يعرض الرسالة الموحدة لكل تقييم قبل الحفظ.
Future<void> showMonthlyRatingDialog({
  required String studentId,
  required String studentName,
  int? initialMonth,
  int? initialYear,
}) async {
  final controller = Get.isRegistered<MonthlyRatingController>()
      ? Get.find<MonthlyRatingController>()
      : Get.put(MonthlyRatingController(), permanent: true);

  final now = DateTime.now();
  final RxInt selectedMonth = (initialMonth ?? now.month).obs;
  final RxInt selectedYear = (initialYear ?? now.year).obs;
  final RxString selectedRating = 'good'.obs;

  // حمّل آخر تقييم لهذا الشهر إن وُجد لعرضه كمحدد مسبقاً
  try {
    await controller.fetchStudentRatings(studentId);
    final existing = controller.ratingForMonth(selectedMonth.value, selectedYear.value) ??
        controller.latestFor(studentId);
    if (existing != null) selectedRating.value = existing.rating;
  } catch (_) {}

  await Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Obx(() {
            final level = MonthlyRatingLevel.fromKey(selectedRating.value);
            final isArabic = Get.locale?.languageCode != 'en';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'add_monthly_rating'.tr,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            studentName,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // اختيار الشهر والسنة
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth.value,
                        decoration: InputDecoration(
                          labelText: 'the_month'.tr,
                          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: List.generate(12, (i) {
                          final m = i + 1;
                          String name;
                          try {
                            name = AppConstants.gregorianMonths[i].tr;
                          } catch (_) {
                            name = 'month_$m'.tr;
                          }
                          return DropdownMenuItem(
                            value: m,
                            child: Text(name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                          );
                        }),
                        onChanged: (v) async {
                          if (v == null) return;
                          selectedMonth.value = v;
                          final ex = controller.ratingForMonth(v, selectedYear.value);
                          if (ex != null) selectedRating.value = ex.rating;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedYear.value,
                        decoration: InputDecoration(
                          labelText: 'the_year'.tr,
                          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [now.year - 1, now.year, now.year + 1]
                            .map((y) => DropdownMenuItem(
                                  value: y,
                                  child: Text('$y', style: const TextStyle(fontFamily: 'Cairo')),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          selectedYear.value = v;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'choose_rating_level'.tr,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                // خيارات التقييم الخمسة
                ...MonthlyRatingLevel.values.map((opt) {
                  final isSelected = selectedRating.value == opt.key;
                  return GestureDetector(
                    onTap: () => selectedRating.value = opt.key,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? opt.color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? opt.color : Colors.grey.withValues(alpha: 0.25),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? opt.color : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: opt.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(opt.icon, color: opt.color, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? opt.titleAr : opt.titleEn,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected ? opt.color : null,
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < opt.stars ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 14,
                                      color: opt.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                // معاينة الرسالة الموحدة للتقييم المختار
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: level.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: level.color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.message_rounded, size: 16, color: level.color),
                          const SizedBox(width: 6),
                          Text(
                            'rating_message_preview'.tr,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: level.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isArabic ? level.messageAr : level.messageEn,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: controller.isSaving.value
                        ? null
                        : () async {
                            final ok = await controller.saveRating(
                              studentId: studentId,
                              ratingKey: selectedRating.value,
                              month: selectedMonth.value,
                              year: selectedYear.value,
                            );
                            if (ok) Get.back();
                          },
                    icon: controller.isSaving.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      'save_rating'.tr,
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: level.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    ),
    barrierDismissible: true,
  );
}
