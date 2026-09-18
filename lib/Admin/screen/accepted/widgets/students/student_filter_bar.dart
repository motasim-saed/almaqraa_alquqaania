import 'package:flutter/material.dart'; // استيراد حزمة Flutter لبناء واجهات المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالأدمن
import '../../../../controller/accepted/accepted_students_controller.dart'; // استيراد متحكم الطلاب المقبولين
import '../../../../../core/utils/quran_categories.dart'; // استيراد قائمة فئات الحفظ
import '../filter_chip_widget.dart'; // استيراد الودجت الخاص بأزرار الفلترة

// شريط الفلترة للطلاب المقبولين - StudentFilterBar
class StudentFilterBar extends StatelessWidget {
  final AcceptedStudentsController controller;
  final Gender gender;

  const StudentFilterBar({
    super.key,
    required this.controller,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final distributionFilter = gender == Gender.male
        ? controller.maleDistributionFilter
        : controller.femaleDistributionFilter;
    final categoryFilter = gender == Gender.male
        ? controller.maleCategoryFilter
        : controller.femaleCategoryFilter;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // استخدام لون الخلفية المناسب للبطاقات من الثيم
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() {
              final students = controller.acceptedStudents
                  .where((s) => s.gender == gender)
                  .toList();
              final allCount = students.length;
              final distributedCount = students.where((s) => s.isDistributed).length;
              final notDistributedCount = students.where((s) => !s.isDistributed).length;

              return Row(
                children: [
                  FilterChipWidget(
                    label: '${'all'.tr} ($allCount)',
                    isSelected: distributionFilter.value == 'all',
                    onTap: () => distributionFilter.value = 'all',
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    label: '${'distributed'.tr} ($distributedCount)',
                    isSelected: distributionFilter.value == 'distributed',
                    onTap: () => distributionFilter.value = 'distributed',
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    label: '${'not_distributed'.tr} ($notDistributedCount)',
                    isSelected: distributionFilter.value == 'not_distributed',
                    onTap: () => distributionFilter.value = 'not_distributed',
                  ),
                  const SizedBox(width: 12),
                  // فاصل رأسي محدد الارتفاع ليظهر بوضوح في الصف
                  SizedBox(
                    height: 24,
                    child: VerticalDivider(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                      thickness: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => controller.exportStudents(gender),
                    icon: const Icon(
                      Icons.description_outlined,
                      color: Colors.green, // لون الإكسل المتعارف عليه
                    ),
                    tooltip: 'export'.tr,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() {
              // تبدأ الفئات من قائمة الجنس، ثم تُطبق عليها فلترة التوزيع أولاً
              final allStudents = controller.acceptedStudents
                  .where((s) => s.gender == gender)
                  .toList();
              final df = distributionFilter.value;
              final students = allStudents
                  .where(
                    (s) =>
                        df == 'all' ||
                        (df == 'distributed' && s.isDistributed) ||
                        (df == 'not_distributed' && !s.isDistributed),
                  )
                  .toList();

              return Row(
                children: [
                  Text(
                    '${'category'.tr}:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    label: '${'all'.tr} (${students.length})',
                    isSelected: categoryFilter.value == 'all',
                    onTap: () => categoryFilter.value = 'all',
                  ),
                  ...quranCategoryKeys
                      .where(
                        (cat) => students.any((s) => s.level == cat),
                      )
                      .map(
                        (cat) => Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8),
                          child: FilterChipWidget(
                            label:
                                '${cat.tr} (${students.where((s) => s.level == cat).length})',
                            isSelected: categoryFilter.value == cat,
                            onTap: () => categoryFilter.value = cat,
                          ),
                        ),
                      ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
