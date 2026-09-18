import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/app_constants.dart';
import '../controller/student_progress_controller.dart';
import '../../Teacher/models/monthly_record_model.dart';
import '../../Examiner/model/final_exam_model.dart';

class StudentGradesScreen extends StatelessWidget {
  const StudentGradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // التأكد من وجود المتحكم أو إيجاده
    final controller = Get.find<StudentProgressController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'my_grades'.tr,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Obx(() {
        // حالة التحميل الأولية
        if (controller.isLoading.value &&
            controller.officialMonthlyRecords.isEmpty &&
            controller.dailyRecords.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchInitialData();
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'monthly_reports'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // سنعرض كافة أشهر السنة (1 إلى 12)
              ...List.generate(12, (index) {
                final monthNumber = index + 1;
                final monthName = AppConstants.gregorianMonths[index].tr;

                // البحث عن السجل الرسمي من المعلم لهذا الشهر
                final officialRecord = controller.officialMonthlyRecords
                    .firstWhereOrNull(
                      (r) =>
                          r.month == monthNumber &&
                          (r.year == null || r.year == DateTime.now().year),
                    );

                // حساب إحصائيات الحضور دائماً محلياً من السجل اليومي لضمان عرض بيانات حقيقية ودقيقة
                final stats = controller.getCalculatedStatsForMonth(
                  monthNumber,
                  DateTime.now().year,
                );

                if (officialRecord != null) {
                  // عرض التقرير الرسمي المكتمل من المعلم مع الإحصائيات الحقيقية
                  return _buildMonthCard(
                    context,
                    monthName,
                    officialRecord,
                    stats,
                    isOfficial: true,
                  );
                } else {
                  // سجل بناء للبطاقة أثناء عدم وجود تقييم
                  final localRecord = MonthlyRecord(
                    studentId: controller.studentId,
                    studentName: '',
                    attendanceDays: 0,
                    absenceDays: 0,
                    excusedDays: 0,
                    holidayDays: 0,
                    monthlyGrade: 0,
                  );
                  return _buildMonthCard(
                    context,
                    monthName,
                    localRecord,
                    stats,
                    isOfficial: false,
                  );
                }
              }), // لا نقوم بالعكس لإظهار الأشهر بالترتيب من 1 لـ 12

              const SizedBox(height: 16),
              Text(
                'final_evaluation'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // 3. عرض درجة الاختبار النهائي (تقييم السنة) من قبل المختبر
              // تظهر البطاقة فور صدور النتيجة: عند وجود سجل بدرجات فعلية (المجموع > 0)
              if ((controller.finalExamRecord.value)?.totalScore != null &&
                  controller.finalExamRecord.value!.totalScore > 0)
                _buildFinalYearGrade(context, controller.finalExamRecord.value!)
              else
                _buildFinalExamPlaceholder(context),

              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  /// بناء بطاقة الشهر المستوحاة من التصميم الجديد (بيانات شاملة ومظهر راقي)
  Widget _buildMonthCard(
    BuildContext context,
    String monthName,
    MonthlyRecord record,
    Map<String, int> stats, {
    bool isOfficial = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                width: 1.2,
              )
            : null,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // الشريط العلوي (النسبة والاسم)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isOfficial)
                  _buildGradeBadge(context, record.monthlyGrade)
                else
                  _buildPendingBadge(context),

                Row(
                  children: [
                    Text(
                      monthName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            // إحصائيات الحضور والغياب الشهرية (نعتمد على التقرير الرسمي من المعلم أولاً إذا كان متاحاً)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'present'.tr,
                  (isOfficial ? record.attendanceDays : (stats['present'] ?? 0))
                      .toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  context,
                  'absent'.tr,
                  (isOfficial ? record.absenceDays : (stats['absent'] ?? 0))
                      .toString(),
                  Colors.blueGrey,
                ),
                _buildStatItem(
                  context,
                  'excused'.tr,
                  (isOfficial ? record.excusedDays : (stats['excused'] ?? 0))
                      .toString(),
                  Colors.red,
                ),
                _buildStatItem(
                  context,
                  'holiday'.tr,
                  (isOfficial ? record.holidayDays : (stats['holiday'] ?? 0))
                      .toString(),
                  Colors.orange,
                ),
              ],
            ),
            // درجات المواد
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreMiniItem(
                  context,
                  'tilawah'.tr,
                  isOfficial ? record.tilawahScore : 0.0,
                  Colors.purple,
                ),
                _buildScoreMiniItem(
                  context,
                  'tajweed'.tr,
                  isOfficial ? record.tajweedScore : 0.0,
                  Colors.teal,
                ),
                _buildScoreMiniItem(
                  context,
                  'hifz'.tr,
                  isOfficial ? record.hifzScore : 0.0,
                  Colors.blue,
                ),
                _buildScoreMiniItem(
                  context,
                  'total'.tr,
                  isOfficial ? record.monthlyGrade.toDouble() : 0.0,
                  Colors.indigo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeBadge(BuildContext context, int grade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$grade%',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.orange,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPendingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'pending'.tr,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).hintColor,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).hintColor,
            fontWeight: FontWeight.w500,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildScoreMiniItem(BuildContext context, String label, double score, Color color) {
    return Column(
      children: [
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).hintColor,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  /// بطاقة الاختبار النهائي المستوحاة بصريًا من تصميم لوحة المختبر
  Widget _buildFinalYearGrade(BuildContext context, FinalExamRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.orange.withValues(alpha: 0.5)
              : Colors.orange.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // الشريط العلوي للاختبار النهائي (يحتوي العلامة واسم التقييم)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGradeBadge(context, record.totalScore.toInt()),
                Row(
                  children: [
                    Text(
                      'final_exam_grade'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            ),
            // درجات الاختبار النهائي بالتفصيل والموزونة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreMiniItem(
                  context,
                  'tilawah'.tr,
                  record.tilawahScore,
                  Colors.purple,
                ),
                _buildScoreMiniItem(
                  context,
                  'tajweed'.tr,
                  record.tajweedScore,
                  Colors.teal,
                ),
                _buildScoreMiniItem(context, 'hifz'.tr, record.hifzScore, Colors.blue),
                _buildScoreMiniItem(
                  context,
                  'total'.tr,
                  record.totalScore.toDouble(),
                  Colors.indigo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalExamPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.amber.withValues(alpha: 0.4)
              : Colors.amber.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: Colors.amber,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'final_exam_grade'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Colors.amber,
                  ),
                ),
                Text(
                  'waiting_examiner_result'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Cairo',
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
