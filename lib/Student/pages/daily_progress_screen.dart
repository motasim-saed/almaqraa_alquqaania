// استيراد الحزم اللازمة
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/student_progress_controller.dart';
import '../models/student_models.dart';
import '../widget/plan_stats_widget.dart';
import 'package:intl/intl.dart';
import 'package:al_maqraa/Teacher/screen/attendance/widgets/attendance_utils.dart';
import 'package:al_maqraa/Teacher/models/daily_attendance_record_model.dart';

class DailyProgressScreen extends StatelessWidget {
  final String? studentId;
  final bool isTeacherMode;
  final bool showStats;

  final int? initialMonth;
  final int? initialYear;

  const DailyProgressScreen({
    super.key,
    this.studentId,
    this.isTeacherMode = false,
    this.showStats = true,
    this.initialMonth,
    this.initialYear,
  });

  @override
  Widget build(BuildContext context) {
    final StudentProgressController controller = Get.put(
      StudentProgressController(
        manualStudentId: studentId,
        initialMonth: initialMonth,
        initialYear: initialYear,
      ),
      tag: studentId,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Obx(() {
        final now = DateTime.now();
        final isRealCurrentMonth =
            controller.selectedMonth.value == now.month &&
            controller.selectedYear.value == now.year;
        return (isRealCurrentMonth && !isTeacherMode)
            ? FloatingActionButton.extended(
                onPressed: () => _showAddRecordDialog(context),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                // إضافة إطار للزر في الثيم الغامق ليكون أكثر وضوحاً
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: Get.isDarkMode
                      ? BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        )
                      : BorderSide.none,
                ),
                label: Text(
                  'add_daily_record'.tr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
              )
            : const SizedBox.shrink();
      }),
      body: Column(
        children: [
          _buildFilterToggle(
            context,
            controller,
          ), // زر الطي والإظهار للأشهر فقط
          Obx(
            () => AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: controller.showFilters.value
                  ? _buildMonthsHeader(
                      context,
                      controller,
                    ) // تظهر الأشهر فقط عند الفتح
                  : const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  if (showStats)
                    SliverToBoxAdapter(
                      child: _buildPersistentStatsHeader(context, controller),
                    ),
                  if (controller.dailyRecords.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_late_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'no_records_yet'.tr,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ExpandableRecordCard(
                            record: controller.dailyRecords[index],
                            isTeacherMode: isTeacherMode,
                            controller: controller,
                          ),
                          childCount: controller.dailyRecords.length,
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

  // زر للتحكم في طي وإظهار قائمة الأشهر
  Widget _buildFilterToggle(
    BuildContext context,
    StudentProgressController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.toggleFilters(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(
              color: Get.isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'select_month'.tr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'month_${controller.selectedMonth.value}'.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${DateTime.now().year}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            Obx(
              () => Icon(
                controller.showFilters.value
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthsHeader(
    BuildContext context,
    StudentProgressController controller,
  ) {
    final now = DateTime.now();
    final realCurrentMonth = now.month;
    final realCurrentYear = now.year;

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 12,
        itemBuilder: (context, index) {
          final monthNumber = index + 1;
          return Obx(() {
            final isSelected = controller.selectedMonth.value == monthNumber;
            final isTodayMonth =
                monthNumber == realCurrentMonth &&
                controller.selectedYear.value == realCurrentYear;

            return GestureDetector(
              onTap: () => controller.changeSelectedMonth(monthNumber),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : (isTodayMonth
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.05)
                            : Theme.of(context).cardColor),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : (isTodayMonth
                              ? Theme.of(context).primaryColor
                              : (Get.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Theme.of(
                                        context,
                                      ).dividerColor.withValues(alpha: 0.2))),
                    width: isTodayMonth ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTodayMonth)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'current'.tr,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white70
                                  : Theme.of(context).colorScheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      Text(
                        'month_$monthNumber'.tr,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isTodayMonth
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color),
                          fontWeight: isTodayMonth
                              ? FontWeight.bold
                              : (isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal),
                          fontFamily: 'Cairo',
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildPersistentStatsHeader(
    BuildContext context,
    StudentProgressController controller,
  ) {
    final currentMonthPlan = controller.monthlyPlans.firstWhereOrNull(
      (p) =>
          p.year == controller.selectedYear.value &&
          p.month == controller.selectedMonth.value,
    );
    if (currentMonthPlan == null) return const SizedBox(height: 10);

    return Obx(
      () => GestureDetector(
        onTap: () => controller.toggleStats(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        'current_month_goal'.tr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    controller.showStats.value
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white54,
                  ),
                ],
              ),
              if (controller.showStats.value) ...[
                const SizedBox(height: 15),
                PlanStatsWidget(description: currentMonthPlan.goalDescription),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRecordDialog(BuildContext context) {
    final hifzController = TextEditingController();
    final revisionController = TextEditingController();
    final revisionFocusNode = FocusNode();
    final controller = Get.find<StudentProgressController>();

    Future<void> submit() async {
      if (hifzController.text.isEmpty && revisionController.text.isEmpty) {
        Get.snackbar('warning'.tr, 'message_cannot_be_empty'.tr);
        return;
      }
      final error = await controller.addDailyRecord(
        hifz: hifzController.text,
        revision: revisionController.text,
      );
      if (error == null) {
        Get.back();
        Get.snackbar('success'.tr, 'daily_achievement_recorded'.tr);
      } else {
        Get.snackbar('error'.tr, error);
      }
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'record_daily_achievement'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 24),
              _buildDialogField(
                controller: hifzController,
                label: 'what_did_you_memorize'.tr,
                icon: Icons.book,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(revisionFocusNode),
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                controller: revisionController,
                label: 'what_did_you_revise'.tr,
                icon: Icons.history,
                focusNode: revisionFocusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submit(),
              ),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.isSaving.value ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: Get.isDarkMode
                            ? BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: controller.isSaving.value
                        ? CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : Text(
                            'save'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _ExpandableRecordCard extends StatefulWidget {
  final DailyRecordModel record;
  final bool isTeacherMode;
  final StudentProgressController controller;

  const _ExpandableRecordCard({
    required this.record,
    this.isTeacherMode = false,
    required this.controller,
  });

  @override
  State<_ExpandableRecordCard> createState() => _ExpandableRecordCardState();
}

class _ExpandableRecordCardState extends State<_ExpandableRecordCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final attendanceStatus = AttendanceUtils.parseStatus(
      record.attendanceStatus,
    );
    final isPresent = attendanceStatus == AttendanceStatus.present;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Get.isDarkMode
              ? Colors.white.withValues(
                  alpha: 0.15,
                ) // زيادة الوضوح في الثيم الغامق
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isPresent
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      DateFormat(
                        'EEEE, d MMMM',
                        Get.locale?.languageCode ?? 'ar',
                      ).format(record.date),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AttendanceUtils.buildAttendanceBadge(record.attendanceStatus),
                  const SizedBox(width: 8),
                  if (isPresent)
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                ],
              ),
            ),
          ),
          if (_isExpanded && isPresent)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // عرض الحفظ والمراجعة بشكل أكثر عمودية واختصاراً
                  _buildAchievementRow(
                    Icons.menu_book_rounded,
                    'hifz'.tr,
                    record.hifzContent ?? '',
                  ),
                  const SizedBox(height: 8),
                  _buildAchievementRow(
                    Icons.history_rounded,
                    'revision'.tr,
                    record.revisionContent ?? '',
                  ),
                  const SizedBox(height: 12),
                  if (widget.isTeacherMode)
                    _buildTeacherReviewSection(context, record)
                  else if (record.teacherNotes != null &&
                      record.teacherNotes!.isNotEmpty)
                    _buildStudentViewTeacherNote(record),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementRow(IconData icon, String label, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: content.isEmpty ? 'not_available'.tr : content),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentViewTeacherNote(DailyRecordModel record) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.comment, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'teacher_note'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.amber,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              _buildApprovalBadge(record.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.teacherNotes!,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Cairo',
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalBadge(String status) {
    Color bColor;
    String tText;
    if (status == 'approved') {
      bColor = Colors.green;
      tText = 'approved'.tr;
    } else if (status == 'rejected') {
      bColor = Colors.red;
      tText = 'rejected'.tr;
    } else {
      bColor = Colors.orange;
      tText = 'pending'.tr;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bColor),
      ),
      child: Text(
        tText,
        style: TextStyle(
          color: bColor,
          fontSize: 10,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTeacherReviewSection(
    BuildContext context,
    DailyRecordModel record,
  ) {
    final noteController = TextEditingController(
      text: record.teacherNotes ?? '',
    );
    String currentStatus = record.status;
    if (currentStatus != 'approved' && currentStatus != 'rejected') {
      currentStatus = 'pending';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: StatefulBuilder(
        builder: (context, setStateSB) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'teacher_review'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: currentStatus,
                      decoration: InputDecoration(
                        labelText: 'record_status'.tr,
                        labelStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text(
                            'pending'.tr,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'approved',
                          child: Text(
                            'approved'.tr,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'rejected',
                          child: Text(
                            'rejected'.tr,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setStateSB(() => currentStatus = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: noteController,
                      maxLines: 1,
                      decoration: InputDecoration(
                        labelText: 'add_note'.tr,
                        labelStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: widget.controller.isSaving.value
                        ? null
                        : () {
                            widget.controller.updateTeacherReview(
                              date: record.date,
                              status: currentStatus,
                              notes: noteController.text.trim(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: widget.controller.isSaving.value
                        ? const SizedBox(
                            height: 12,
                            width: 12,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'save_review'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
