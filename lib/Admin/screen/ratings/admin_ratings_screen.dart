import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Teacher/models/monthly_rating_model.dart';
import '../../../core/models/shared_models.dart';
import '../../../core/utils/app_constants.dart';
import '../../controller/ratings/admin_ratings_controller.dart';

/// شاشة إدارة التقييمات الشهرية:
/// فلترة (جنس/حلقة/تقييم/شهر) + إرسال رسائل لأصحاب تقييم محدد + سجل الرسائل
class AdminRatingsScreen extends StatelessWidget {
  const AdminRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<AdminRatingsController>()
        ? Get.find<AdminRatingsController>()
        : Get.put(AdminRatingsController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value && controller.students.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadAll(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, controller, isDark),
                const SizedBox(height: 16),
                _buildStats(controller, isDark),
                const SizedBox(height: 16),
                _buildTabs(controller, isDark),
                const SizedBox(height: 16),
                if (controller.tabIndex.value == 0) ...[
                  _buildFilters(context, controller, isDark),
                  const SizedBox(height: 12),
                  _buildResults(context, controller, isDark),
                ] else if (controller.tabIndex.value == 1) ...[
                  _buildFilters(context, controller, isDark, compact: true),
                  const SizedBox(height: 12),
                  _buildComposer(context, controller, isDark),
                ] else ...[
                  _buildHistory(context, controller, isDark),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── الترويسة: الشهر/السنة + تحديث ─────────────────────────────
  Widget _buildHeader(
      BuildContext context, AdminRatingsController c, bool isDark) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.star_rate_rounded,
                color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ratings_management'.tr,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Obx(() => Text(
                      '${c.filtered.length} ${'students_count'.tr} • ${c.ratingsByStudent.length} ${'monthly_rating'.tr}',
                      style:
                          TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade600, fontSize: 12),
                    )),
              ],
            ),
          ),
          Obx(() => DropdownButton<int>(
                value: c.selectedMonth.value,
                underline: const SizedBox.shrink(),
                items: List.generate(12, (i) {
                  String name;
                  try {
                    name = AppConstants.gregorianMonths[i].tr;
                  } catch (_) {
                    name = '${i + 1}';
                  }
                  return DropdownMenuItem(
                      value: i + 1,
                      child: Text(name,
                          style: const TextStyle(
                              fontFamily: 'Cairo', fontSize: 13)));
                }),
                onChanged: (v) {
                  if (v != null) c.changeMonthYear(v, c.selectedYear.value);
                },
              )),
          const SizedBox(width: 8),
          Obx(() => DropdownButton<int>(
                value: c.selectedYear.value,
                underline: const SizedBox.shrink(),
                items: [now.year - 1, now.year, now.year + 1]
                    .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text('$y',
                            style: const TextStyle(fontFamily: 'Cairo'))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) c.changeMonthYear(c.selectedMonth.value, v);
                },
              )),
          IconButton(
            onPressed: () => c.loadAll(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
    );
  }

  // ── إحصائيات التقييمات (شرائح قابلة للنقر للفلترة) ─────────────
  Widget _buildStats(AdminRatingsController c, bool isDark) {
    return Obx(() {
      final stats = c.stats;
      final total = stats.values.fold<int>(0, (a, b) => a + b);
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...MonthlyRatingLevel.values.map((lv) {
            final count = stats[lv.key] ?? 0;
            final selected = c.ratingFilter.value == lv.key;
            return _statChip(
              label:
                  '${Get.locale?.languageCode == 'en' ? lv.titleEn : lv.titleAr} ($count)',
              color: lv.color,
              icon: lv.icon,
              selected: selected,
              onTap: () =>
                  c.setRatingFilter(selected ? 'all' : lv.key),
            );
          }),
          _statChip(
            label: '${'unrated'.tr} (${stats['unrated'] ?? 0})',
            color: Colors.grey,
            icon: Icons.help_outline_rounded,
            selected: c.ratingFilter.value == 'unrated',
            onTap: () => c.setRatingFilter(
                c.ratingFilter.value == 'unrated' ? 'all' : 'unrated'),
          ),
          _statChip(
            label: '${'all'.tr} ($total)',
            color: Colors.indigo,
            icon: Icons.groups_rounded,
            selected: c.ratingFilter.value == 'all',
            onTap: () => c.setRatingFilter('all'),
          ),
        ],
      );
    });
  }

  Widget _statChip({
    required String label,
    required Color color,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : color)),
          ],
        ),
      ),
    );
  }

  // ── التبويبات ────────────────────────────────────────────────
  Widget _buildTabs(AdminRatingsController c, bool isDark) {
    const tabs = ['ratings_results', 'send_rating_message', 'rating_messages_history'];
    return Obx(() => Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = c.tabIndex.value == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => c.tabIndex.value = i,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark ? Colors.indigoAccent : Colors.indigo)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tabs[i].tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ));
  }

  // ── الفلاتر: جنس + حلقة ──
  // الدفعة من الشريط العلوي (مثل بقية الشاشات)، والحلقات تتبع الجنس والدفعة والتقييم
  Widget _buildFilters(
      BuildContext context, AdminRatingsController c, bool isDark,
      {bool compact = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => _filterDropdown<String>(
                  value: c.genderFilter.value,
                  label: 'gender'.tr,
                  items: [
                    DropdownMenuItem(
                        value: 'all',
                        child: Text('all'.tr,
                            style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 13))),
                    DropdownMenuItem(
                        value: 'male',
                        child: Text('male'.tr,
                            style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 13))),
                    DropdownMenuItem(
                        value: 'female',
                        child: Text('female'.tr,
                            style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 13))),
                  ],
                  onChanged: (v) {
                    if (v != null) c.setGenderFilter(v);
                  },
                )),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Obx(() {
              final visible = c.visibleCircles;
              final currentValid = c.circleFilter.value == 'all' ||
                  visible.any((e) => e.id == c.circleFilter.value);
              return _filterDropdown<String>(
                value: currentValid ? c.circleFilter.value : 'all',
                label: 'circle_label'.tr,
                items: [
                  DropdownMenuItem(
                      value: 'all',
                      child: Text(
                          '${'all'.tr} (${visible.length})',
                          style: const TextStyle(
                              fontFamily: 'Cairo', fontSize: 13))),
                  ...visible.map((circle) => DropdownMenuItem(
                        value: circle.id,
                        child: Text(
                          circle.gender == Gender.all
                              ? circle.name
                              : '${circle.name} (${circle.gender == Gender.female ? 'female'.tr : 'male'.tr})',
                          style: const TextStyle(
                              fontFamily: 'Cairo', fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (v) {
                  if (v != null) c.circleFilter.value = v;
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown<T>({
    required T value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── النتائج ─────────────────────────────────────────────────
  Widget _buildResults(
      BuildContext context, AdminRatingsController c, bool isDark) {
    return Obx(() {
      final list = c.filtered;
      if (list.isEmpty) {
        final bool noRatingsAtAll =
            c.students.isNotEmpty && c.ratingsByStudent.isEmpty;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded,
                    size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  noRatingsAtAll
                      ? 'no_ratings_loaded_hint'.tr
                      : 'no_data'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
        );
      }
      return LayoutBuilder(builder: (context, constraints) {
        int cross = 1;
        if (constraints.maxWidth > 1400) {
          cross = 4;
        } else if (constraints.maxWidth > 1000) {
          cross = 3;
        } else if (constraints.maxWidth > 650) {
          cross = 2;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 132,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) =>
              _studentCard(context, list[i], isDark),
        );
      });
    });
  }

  Widget _studentCard(
      BuildContext context, RatedStudent item, bool isDark) {
    final s = item.student;
    final lv = item.level;
    final isArabic = Get.locale?.languageCode != 'en';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (lv?.color ?? Colors.grey).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                (lv?.color ?? Colors.indigo).withValues(alpha: 0.12),
            child: Icon(lv?.icon ?? Icons.person_rounded,
                color: lv?.color ?? Colors.indigo),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text(
                  '${s.gender == Gender.female ? 'female'.tr : 'male'.tr} • ${s.circleName?.isNotEmpty == true ? s.circleName! : 'no_circle_currently'.tr}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: (lv?.color ?? Colors.grey)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    lv == null
                        ? 'unrated'.tr
                        : (isArabic ? lv.titleAr : lv.titleEn),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: lv?.color ?? Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── إرسال رسالة لأصحاب تقييم محدد ────────────────────────────
  Widget _buildComposer(
      BuildContext context, AdminRatingsController c, bool isDark) {
    return Obx(() {
      final targets = c.targetsForMessage();
      final lv = MonthlyRatingLevel.fromKey(c.messageRating.value);
      final isArabic = Get.locale?.languageCode != 'en';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('choose_rating_level'.tr,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MonthlyRatingLevel.values.map((opt) {
                final selected = c.messageRating.value == opt.key;
                return GestureDetector(
                  onTap: () => c.messageRating.value = opt.key,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? opt.color
                          : opt.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: opt.color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(opt.icon,
                            size: 16,
                            color:
                                selected ? Colors.white : opt.color),
                        const SizedBox(width: 6),
                        Text(
                          isArabic ? opt.titleAr : opt.titleEn,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                selected ? Colors.white : opt.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lv.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: lv.color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.groups_rounded, color: lv.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'message_targets_count'.trParams(
                              {'count': targets.length.toString()}),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: lv.color,
                          ),
                        ),
                      ),
                      if (targets.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            c.setRatingFilter(c.messageRating.value);
                            c.tabIndex.value = 0;
                          },
                          child: Text('view_targets'.tr,
                              style: const TextStyle(
                                  fontFamily: 'Cairo', fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // توضيح الاستهداف: الجنس (الكل/محدد) + الدفعة + الحلقة
                  // للكل: اترك فلتر الجنس على "الكل" — لجنس محدد: اختر ذكر/أنثى من الأعلى
                  Text(
                    c.targetsDescription(),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.titleController,
              decoration: InputDecoration(
                labelText: 'notification_title'.tr,
                hintText: 'enter_title_here'.tr,
                labelStyle:
                    const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.bodyController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'notification_body'.tr,
                hintText: 'write_message_here'.tr,
                labelStyle:
                    const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              style:
                  const TextStyle(fontFamily: 'Cairo', height: 1.6),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: c.isSending.value || targets.isEmpty
                    ? null
                    : () => c.sendRatingMessage(),
                icon: c.isSending.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white),
                label: Text(
                  'send_to_rating_holders'.trParams({
                    'rating': isArabic ? lv.titleAr : lv.titleEn,
                    'count': targets.length.toString()
                  }),
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lv.color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── سجل الرسائل ─────────────────────────────────────────────
  Widget _buildHistory(
      BuildContext context, AdminRatingsController c, bool isDark) {
    return Obx(() {
      if (c.isHistoryLoading.value && c.messageHistory.isEmpty) {
        return const Center(
            child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator()));
      }
      if (c.messageHistory.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('no_rating_messages_yet'.tr,
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        );
      }
      return Column(
        children: c.messageHistory.map((m) {
          final lv =
              MonthlyRatingLevel.fromKey(m['rating']?.toString());
          final isArabic = Get.locale?.languageCode != 'en';
          final msgId = m['id']?.toString() ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: lv.color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(lv.icon, color: lv.color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m['title']?.toString() ?? '',
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: lv.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${isArabic ? lv.titleAr : lv.titleEn} • ${m['target_count'] ?? 0}',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: lv.color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  m['body']?.toString() ?? '',
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      height: 1.6),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${m['month'] ?? ''}/${m['year'] ?? ''} • ${m['created_at']?.toString().split('T').first ?? ''}',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.grey.shade600),
                      ),
                    ),
                    if (msgId.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, size: 22),
                        color: Colors.indigo,
                        tooltip: 'edit_notification'.tr,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        onPressed: () =>
                            _showEditRatingDialog(context, c, msgId, m),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20),
                        color: Colors.redAccent,
                        tooltip: 'confirm_delete'.tr,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          final confirm = await Get.defaultDialog<bool>(
                                title: 'confirm_delete'.tr,
                                middleText:
                                    'delete_notification_confirm_msg'.tr,
                                textConfirm: 'yes_delete'.tr,
                                textCancel: 'cancel'.tr,
                                confirmTextColor: Colors.white,
                                buttonColor: Colors.redAccent,
                                onConfirm: () => Get.back(result: true),
                                onCancel: () {},
                              ) ??
                              false;
                          if (confirm) c.deleteRatingMessage(msgId);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  void _showEditRatingDialog(BuildContext context,
      AdminRatingsController c, String msgId, Map<String, dynamic> m) {
    final titleCtrl =
        TextEditingController(text: m['title']?.toString() ?? '');
    final bodyCtrl = TextEditingController(text: m['body']?.toString() ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.defaultDialog(
      title: 'edit_notification'.tr,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      titleStyle: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87),
      content: Column(
        children: [
          TextField(
            controller: titleCtrl,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Cairo'),
            decoration: InputDecoration(
              labelText: 'edit_title'.tr,
              labelStyle: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bodyCtrl,
            maxLines: 4,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Cairo'),
            decoration: InputDecoration(
              labelText: 'edit_body'.tr,
              labelStyle: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
      textConfirm: 'save'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.indigo,
      onConfirm: () async {
        Get.back();
        await c.updateRatingMessage(
            msgId, titleCtrl.text, bodyCtrl.text);
      },
    );
  }
}
