import 'package:al_maqraa/Teacher/controller/monthly_follow_up_controller.dart'; // استيراد متحكم المتابعة الشهرية لإدارة الحالة والبيانات
import 'package:al_maqraa/Teacher/models/monthly_record_model.dart'; // استيراد نموذج سجل المتابعة الشهري لتمثيل بيانات الطالب
import 'package:flutter/material.dart'; // استيراد حزمة فلاتر الأساسية لتصميم واجهات المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة والمسارات

/// شاشة المتابعة الشهرية المحدثة لعرض إحصائيات الحضور والغياب والإجازات والدرجات
class MonthlyFollowUpScreen extends StatelessWidget {
  // تعريف المنشئ الثابت للشاشة مع مفتاح فريد
  const MonthlyFollowUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // بناء هيكل الصفحة الأساسي
    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor, // تعيين لون خلفية مريح وهادئ للصفحة
      appBar: AppBar(
        title: Text(
          'monthly_followup'.tr, // عرض عنوان الصفحة المترجم (المتابعة الشهرية)
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ), // تعيين خط عريض للعنوان
        ),
        centerTitle: true, // وضع العنوان في منتصف شريط التطبيق العلوي
        backgroundColor:
            colorScheme.primary, // تعيين اللون الأساسي لشريط التطبيق
        foregroundColor: colorScheme
            .onPrimary, // تلوين العناصر بالأبيض أو اللون المناسب للثيم
        elevation: 0, // إزالة الظل أسفل شريط التطبيق لتبسيط الواجهة
        actions: [
          // إضافة زر في شريط التطبيق لحفظ بيانات الشهر
          IconButton(
            onPressed: () => Get.find<MonthlyFollowUpController>()
                .saveMonthData(), // استدعاء دالة الحفظ عند الضغط
            icon: const Icon(Icons.save_outlined), // أيقونة الحفظ بشكل خطي
          ),
        ],
      ),
      // استخدام GetX لمراقبة التغييرات في المتحكم وتحديث الواجهة تلقائياً
      body: GetX<MonthlyFollowUpController>(
        init: MonthlyFollowUpController(), // تهيئة المتحكم عند بدء تشغيل الشاشة
        builder: (controller) {
          // بناء عمود يحتوي على العناصر الرأسية
          return Column(
            children: [
              _buildMonthSelector(controller), // استدعاء ويدجت اختيار الشهر
              Expanded(
                // التحقق من حالة التحميل لعرض مؤشر التقدم أو البيانات
                child: controller.isLoading.value
                    ? const Center(
                        child: CircularProgressIndicator(),
                      ) // عرض مؤشر تحميل دائري في المنتصف
                    : RefreshIndicator(
                        // إمكانية سحب الشاشة للأسفل لتحديث البيانات يدوياً من السيرفر
                        onRefresh: () async => controller.loadFollowUpData(),
                        // التحقق مما إذا كانت قائمة البيانات فارغة لعرض واجهة مناسبة
                        child: controller.monthData.isEmpty
                            ? _buildEmptyState(
                                context,
                              ) // عرض واجهة "لا توجد بيانات"
                            : ListView.builder(
                                padding: const EdgeInsets.all(
                                  16,
                                ), // إضافة حواف للقائمة بالكامل
                                itemCount: controller
                                    .monthData
                                    .length, // عدد الطلاب في القائمة
                                itemBuilder: (context, index) {
                                  // بناء بطاقة عرض لكل طالب بناءً على بياناته
                                  return _buildStudentCard(
                                    controller.monthData[index],
                                    context,
                                  );
                                },
                              ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// بناء واجهة تعرض أيقونة ورسالة عندما لا تتوفر بيانات للمتابعة
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // توسيط العناصر عمودياً في المنتصف
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: colorScheme.outline.withValues(alpha: 0.5),
          ), // أيقونة تعبر عن عدم وجود طلاب
          const SizedBox(height: 16), // مسافة عمودية بين الأيقونة والنص
          Text(
            'no_data'.tr,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ), // نص مترجم "لا توجد بيانات"
        ],
      ),
    );
  }

  /// بناء شريط اختيار الشهر القابل للتمرير بشكل أفقي
  Widget _buildMonthSelector(MonthlyFollowUpController controller) {
    return Container(
      height: 60, // تحديد ارتفاع شريط الشهور
      margin: const EdgeInsets.symmetric(vertical: 12), // إضافة هوامش عمودية
      child: ListView.builder(
        controller: controller.monthScrollController, // ربط متحكم التمرير لتوسيط العناصر
        scrollDirection: Axis.horizontal, // جعل التمرير أفقياً
        padding: const EdgeInsets.symmetric(horizontal: 16), // إضافة حواف أفقية
        itemCount: controller.months.length, // عدد الشهور المتاحة في المتحكم
        itemBuilder: (context, index) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          // تحديد ما إذا كان الشهر الحالي في القائمة هو المختار
          bool isSelected = controller.selectedMonthIndex.value == index;
          // تحديد ما إذا كان هذا هو الشهر الفعلي الحالي في التقويم
          bool isRealCurrentMonth = DateTime.now().month - 1 == index;

          return GestureDetector(
            onTap: () =>
                controller.selectMonth(index), // تغيير الشهر المختار عند الضغط
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 200,
              ), // مدة الانتقال الحركي السلس
              width: 110, // عرض بطاقة الشهر الواحدة
              margin: const EdgeInsets.only(
                left: 8,
              ), // مسافة بين كل بطاقة شهر وأخرى
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : theme.cardColor, // تغيير اللون بناءً على حالة الاختيار
                borderRadius: BorderRadius.circular(
                  16,
                ), // جعل حواف البطاقة دائرية
                border: Border.all(
                  color: isSelected 
                      ? colorScheme.primary 
                      : (isRealCurrentMonth ? colorScheme.primary.withValues(alpha: 0.5) : theme.dividerColor),
                  width: isRealCurrentMonth || isSelected ? 2 : 1,
                ), // إضافة إطار للبطاقة
              ),
              child: Center(
                child: Text(
                  controller
                      .months[index]
                      .tr, // عرض اسم الشهر مترجماً (يناير، فبراير...)
                  style: TextStyle(
                    fontSize: 13, // حجم الخط
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal, // تغليظ الخط للشهر المختار
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme
                              .onSurface, // تغيير لون النص بناءً على الاختيار
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// بناء بطاقة مفصلة لكل طالب تحتوي على الاسم والدرجة وإحصائيات الحضور والدرجات النوعية
  Widget _buildStudentCard(MonthlyRecord record, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // مسافة أسفل كل بطاقة طالب
      decoration: BoxDecoration(
        color: theme.cardColor, // لون خلفية البطاقة
        borderRadius: BorderRadius.circular(
          24,
        ), // جعل حواف البطاقة دائرية بشكل كبير
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ], // إضافة ظل خفيف جداً للبطاقة
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          20.0,
        ), // إضافة حواف داخلية لمحتويات البطاقة
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(
                    alpha: 0.1,
                  ), // لون خلفية دائرة الصورة
                  child: Icon(
                    Icons.person,
                    color: colorScheme.primary,
                  ), // أيقونة شخصية افتراضية
                ),
                const SizedBox(width: 12), // مسافة أفقية بين الصورة والاسم
                Expanded(
                  child: Text(
                    record.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ), // عرض اسم الطالب بخط عريض
                ),
                _buildGradeBadge(
                  record.monthlyGrade,
                  context,
                ), // استدعاء ويدجت عرض وسم الدرجة المئوية
              ],
            ),
            const Divider(height: 32), // خط فاصل أفقي مع مساحة عمودية
            // عرض إحصائيات الحضور والغياب والإجازات في صف واحد
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceAround, // توزيع العناصر بمسافات متساوية حولها
              children: [
                _buildStatItem(
                  'present'.tr,
                  record.attendanceDays.toString(),
                  Colors.green,
                  context,
                ), // عنصر إحصائي للحضور
                _buildStatItem(
                  'absent'.tr,
                  record.absenceDays.toString(),
                  Colors.red,
                  context,
                ), // عنصر إحصائي للغياب
                _buildStatItem(
                  'excused'.tr,
                  record.excusedDays.toString(),
                  colorScheme.outline,
                  context,
                ), // عنصر إحصائي للاستئذان
                _buildStatItem(
                  'holiday'.tr,
                  record.holidayDays.toString(),
                  Colors.orange,
                  context,
                ), // عنصر إحصائي للإجازات الرسمية
              ],
            ),
            const Divider(height: 32), // خط فاصل أفقي آخر
            // عرض درجات الحفظ والتجويد والتلاوة في صف واحد
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceAround, // توزيع الدرجات بمسافات متساوية
              children: [
                _buildScoreMiniItem(
                  'hifz'.tr,
                  record.hifzScore,
                  Colors.blue,
                  context,
                ), // درجة الحفظ
                _buildScoreMiniItem(
                  'tajweed'.tr,
                  record.tajweedScore,
                  Colors.teal,
                  context,
                ), // درجة التجويد
                _buildScoreMiniItem(
                  'tilawah'.tr,
                  record.tilawahScore,
                  Colors.purple,
                  context,
                ), // درجة التلاوة
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء وسم ملون يعرض النسبة المئوية لدرجة الطالب الشهرية
  Widget _buildGradeBadge(int grade, BuildContext context) {
    // تحديد لون الخلفية بناءً على مستوى الدرجة (أخضر للممتاز، برتقالي لغير ذلك)
    final Color badgeColor = grade >= 80 ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ), // حواف داخلية للوسم
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10), // حواف دائرية للوسم
      ),
      child: Text(
        '$grade%', // نص الدرجة المئوية
        style: TextStyle(
          fontWeight: FontWeight.bold, // خط عريض
          color: grade >= 80
              ? Colors.green[700]
              : Colors.orange[700], // تحديد لون النص بناءً على مستوى الدرجة
        ),
      ),
    );
  }

  /// بناء عنصر عرض مصغر للدرجة يحتوي على الرقم والتسمية (مثلاً: 50 حفظ)
  Widget _buildScoreMiniItem(
    String label,
    double score,
    Color color,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          score.toString(), // عرض قيمة الدرجة
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ), // تنسيق الرقم باللون المخصص
        ),
        const SizedBox(height: 2), // مسافة صغيرة جداً بين الرقم والنص
        Text(
          label, // عرض اسم الدرجة (حفظ، تجويد، تلاوة)
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ), // نص صغير
        ),
      ],
    );
  }

  /// بناء عنصر إحصائي عمودي يحتوي على القيمة (رقم) والتسمية (نص)
  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value, // عرض الرقم الإحصائي (مثل عدد أيام الحضور)
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ), // رقم عريض باللون المخصص
        ),
        const SizedBox(height: 4), // مسافة عمودية بين الرقم والنص
        Text(
          label, // عرض التسمية (حاضر، غائب...)
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ), // نص صغير
        ),
      ],
    );
  }
}
