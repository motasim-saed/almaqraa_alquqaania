import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهات المستخدم
import 'package:flutter/services.dart'; // استيراد حزمة الخدمات للتحكم في مدخلات النصوص
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة والمسارات
import '../../controller/monthly_exam_controller.dart'; // استيراد متحكم الاختبارات الشهرية لإدارة البيانات
import '../../models/monthly_exam_model.dart'; // استيراد نموذج بيانات الاختبار الشهري

/// شاشة رصد درجات الاختبارات الشهرية للطلاب (واجهة المعلم)
class MonthlyExamScreen extends StatelessWidget {
  // تعريف المنشئ الثابت للفئة
  const MonthlyExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // استخدام GestureDetector حول الـ Scaffold لإغلاق لوحة المفاتيح عند الضغط في أي مكان فارغ
    return GestureDetector(
      onTap: () => FocusScope.of(
        context,
      ).unfocus(), // إلغاء التأشير (Focus) وإغلاق الكيبورد
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // تعيين لون خلفية متناسق
        appBar: AppBar(
          title: Text(
            'monthly_exams'.tr, // عرض عنوان الصفحة مترجماً (الاختبارات الشهرية)
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ), // تعيين خط عريض للعنوان
          ),
          centerTitle: true, // وضع العنوان في منتصف شريط التطبيق
          backgroundColor: colorScheme.primary, // تعيين اللون الأساسي لشريط التطبيق
          foregroundColor: colorScheme.onPrimary, // تلوين العناصر بالأبيض أو اللون المناسب للثيم
          elevation: 0, // إزالة الظل أسفل شريط التطبيق
          actions: [
            // إضافة زر في شريط التطبيق لحفظ البيانات
            IconButton(
              onPressed: () => Get.find<MonthlyExamController>()
                  .saveMonthData(), // استدعاء دالة الحفظ من المتحكم عند الضغط
              icon: const Icon(Icons.save_outlined), // أيقونة الحفظ بشكل خطي
              tooltip: 'save'.tr, // نص تلميحي يظهر عند الوقوف على الزر (حفظ)
            ),
          ],
        ),
        // استخدام GetX لمراقبة التغييرات في المتحكم وتحديث الواجهة
        body: GetX<MonthlyExamController>(
          init: MonthlyExamController(), // تهيئة المتحكم عند بدء تشغيل الشاشة
          builder: (controller) {
            // بناء عمود يحتوي على العناصر الرأسية
            return Column(
              children: [
                // استدعاء ويدجت اختيار الشهر
                _buildMonthSelector(controller),
                Expanded(
                  // التحقق مما إذا كانت البيانات قيد التحميل
                  child: controller.isLoading.value
                      ? const Center(
                          child:
                              CircularProgressIndicator(), // عرض مؤشر تحميل في منتصف الشاشة
                        )
                      : RefreshIndicator(
                          // إمكانية سحب الشاشة للأسفل لتحديث البيانات يدوياً
                          onRefresh: () async => controller.loadExamData(),
                          // التحقق مما إذا كانت قائمة السجلات فارغة
                          child: controller.examRecords.isEmpty
                              ? _buildEmptyState(context) // عرض واجهة الحالة الفارغة
                              : ListView.builder(
                                  padding: const EdgeInsets.all(
                                    16,
                                  ), // إضافة حواف للقائمة
                                  itemCount: controller
                                      .examRecords
                                      .length, // عدد الطلاب في القائمة
                                  itemBuilder: (context, index) {
                                    // بناء بطاقة اختبار لكل طالب بناءً على موقعه
                                    return _buildExamCard(
                                      controller,
                                      controller.examRecords[index],
                                      index,
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
      ),
    );
  }

  /// بناء واجهة تعرض رسالة عند عدم وجود بيانات
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // توسيط العناصر عمودياً
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: colorScheme.outline.withValues(alpha: 0.5),
          ), // أيقونة مهام فارغة
          const SizedBox(height: 16), // مسافة عمودية
          Text(
            'no_data'.tr,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ), // نص يعلم المستخدم بعدم وجود بيانات
        ],
      ),
    );
  }

  /// بناء شريط اختيار الشهر القابل للتمرير أفقياً
  Widget _buildMonthSelector(MonthlyExamController controller) {
    return Container(
      height: 60, // تحديد ارتفاع شريط الشهور
      margin: const EdgeInsets.symmetric(vertical: 12), // إضافة هوامش عمودية
      child: ListView.builder(
        controller: controller.monthScrollController, // ربط متحكم التمرير
        scrollDirection: Axis.horizontal, // جعل التمرير أفقياً
        padding: const EdgeInsets.symmetric(horizontal: 16), // إضافة حواف أفقية
        itemCount: controller.months.length, // عدد الشهور المتاحة
        itemBuilder: (context, index) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          // تحديد ما إذا كان الشهر الحالي هو المختار
          bool isSelected = controller.selectedMonthIndex.value == index;
          // تحديد ما إذا كان هذا هو الشهر الفعلي الحالي في التقويم
          bool isRealCurrentMonth = DateTime.now().month - 1 == index;
          
          return GestureDetector(
            onTap: () =>
                controller.selectMonth(index), // تغيير الشهر المختار عند الضغط
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 200,
              ), // مدة الانتقال الحركي
              width: 110, // عرض بطاقة الشهر
              margin: const EdgeInsets.only(left: 8), // مسافة بين الشهور
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : theme.cardColor, // تغيير اللون بناءً على الاختيار
                borderRadius: BorderRadius.circular(16), // جعل الحواف دائرية
                border: Border.all(
                  color: isSelected 
                      ? colorScheme.primary 
                      : (isRealCurrentMonth ? colorScheme.primary.withValues(alpha: 0.5) : theme.dividerColor),
                  width: isRealCurrentMonth || isSelected ? 2 : 1,
                ), // إضافة إطار للبطاقة
              ),
              child: Center(
                child: Text(
                  controller.months[index].tr, // عرض اسم الشهر مترجماً
                  style: TextStyle(
                    fontSize: 13, // حجم الخط
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal, // تغليظ الخط للمختار
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface, // تغيير لون النص
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// بناء بطاقة عرض درجات الطالب الواحد
  Widget _buildExamCard(
    MonthlyExamController controller,
    MonthlyExamRecord record,
    int index,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24), // مسافة أسفل البطاقة
      padding: const EdgeInsets.all(16), // حشوة داخلية للبطاقة
      decoration: BoxDecoration(
        color: theme.cardColor, // لون خلفية البطاقة
        borderRadius: BorderRadius.circular(
          24,
        ), // جعل حواف البطاقة دائرية بشكل كبير
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ], // إضافة ظل خفيف جداً
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // محاذاة المحتوى للبداية
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person, color: colorScheme.primary),
              ), // أيقونة شخصية دائرية
              const SizedBox(width: 12), // مسافة أفقية
              Expanded(
                child: Text(
                  record.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ), // عرض اسم الطالب
              _buildTotalBadge(record.totalScore, context), // عرض إجمالي الدرجات
            ],
          ),
          const SizedBox(height: 20), // مسافة عمودية
          Row(
            children: [
              // حقل إدخال درجة الحفظ (القيمة القصوى 50)
              _buildScoreField(
                controller,
                index,
                'hifz',
                'hifz'.tr,
                '50',
                record.hifzScore,
                Colors.blue,
                context,
              ),
              const SizedBox(width: 8), // مسافة أفقية
              // حقل إدخال درجة التجويد (القيمة القصوى 30)
              _buildScoreField(
                controller,
                index,
                'tajweed',
                'tajweed'.tr,
                '30',
                record.tajweedScore,
                Colors.teal,
                context,
              ),
              const SizedBox(width: 8), // مسافة أفقية
              // حقل إدخال درجة التلاوة (القيمة القصوى 20)
              _buildScoreField(
                controller,
                index,
                'tilawah',
                'tilawah'.tr,
                '20',
                record.tilawahScore,
                Colors.deepPurple,
                context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء وسم يعرض إجمالي الدرجة
  Widget _buildTotalBadge(double score, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ), // حشوة داخلية للوسم
      decoration: BoxDecoration(
        color: isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green[50],
        borderRadius: BorderRadius.circular(10),
      ), // خلفية خضراء فاتحة
      child: Text(
        '${score.toInt()}/100',
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ), // نص الدرجة
    );
  }

  /// بناء حقل إدخال الدرجة مع قيود على القيمة المدخلة وإظهار تنبيه عند التجاوز
  Widget _buildScoreField(
    MonthlyExamController controller,
    int studentIndex,
    String type,
    String label,
    String max,
    double current,
    Color color,
    BuildContext context,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ), // تسمية الحقل (حفظ، تجويد، تلاوة)
          const SizedBox(height: 5), // مسافة عمودية
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ), // خلفية ملونة خفيفة للحقل
            child: TextFormField(
              initialValue: current == 0
                  ? ''
                  : current.toString().replaceAll(
                      '.0',
                      '',
                    ), // تعيين القيمة الحالية وتحويلها لنص
              textAlign: TextAlign.center, // توسيط النص داخل الحقل
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ), // فتح لوحة مفاتيح الأرقام مع دعم الفواصل
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ), // تنسيق نص المدخلات
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'(^\d*\.?\d*)'),
                ), // السماح فقط بالأرقام والنقطة العشرية
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // وظيفة مخصصة لتقييد القيمة بالحد الأقصى تلقائياً
                  if (newValue.text.isEmpty) {
                    return newValue; // السماح بمسح الحقل
                  }
                  final double? enteredScore = double.tryParse(newValue.text);
                  final double maxScore =
                      double.tryParse(max) ?? 100.0; // تحديد الدرجة القصوى

                  // إذا كانت القيمة المدخلة أكبر من الدرجة القصوى، يتم التقييد لأعلى درجة تلقائياً
                  if (enteredScore != null && enteredScore > maxScore) {
                    final maxStr = maxScore == maxScore.toInt()
                        ? maxScore.toInt().toString()
                        : maxScore.toString();
                    return TextEditingValue(
                      text: maxStr,
                      selection: TextSelection.collapsed(offset: maxStr.length),
                    );
                  }
                  return newValue; // قبول القيمة الجديدة
                }),
              ],
              decoration: InputDecoration(
                hintText: '0', // نص توضيحي عند فراغ الحقل
                isDense: true, // ضغط حجم الحقل
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 7,
                ), // حشوة داخلية
                border: InputBorder.none, // إزالة الحدود الافتراضية
                suffixText: '/$max', // عرض الحد الأقصى للدرجة بجانب المدخل
                suffixStyle: TextStyle(
                  fontSize: 8,
                  color: Colors.red,
                ), // تنسيق نص الحد الأقصى
              ),
              onChanged: (val) {
                // تحديث الدرجة في المتحكم عند كل حرف يكتبه المعلم
                double? score = double.tryParse(val); // تحويل المدخل لرقم
                if (score != null) {
                  controller.updateScore(
                    studentIndex,
                    type,
                    score,
                  ); // تحديث القيمة في القائمة
                } else if (val.isEmpty) {
                  controller.updateScore(
                    studentIndex,
                    type,
                    0,
                  ); // تصفير الدرجة إذا تم مسح الحقل
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
