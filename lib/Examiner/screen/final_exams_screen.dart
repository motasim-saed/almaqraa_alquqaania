import 'package:flutter/material.dart'; // استيراد حزمة فلاتر الأساسية لتصميم الواجهات
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والترجمة
import '../controller/final_exams_controller.dart'; // استيراد متحكم الاختبارات النهائية
import '../model/final_exam_model.dart'; // استيراد نموذج بيانات سجل الاختبار

class FinalExamsScreen extends StatelessWidget {
  // تعريف شاشة الاختبارات النهائية كويدجت عديم الحالة
  const FinalExamsScreen({super.key}); // منشئ الفئة مع مفتاح التمييز الفريد

  @override // إعادة تعريف دالة بناء الواجهة
  Widget build(BuildContext context) {
    // دالة بناء سياق الواجهة
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(
        context,
      ).scaffoldBackgroundColor, // تعيين لون خلفية يتناسب مع الثيم
      // استخدام GetBuilder لربط الواجهة بالمتحكم بشكل مباشر وفعال لضمان تحديث البيانات
      child: GetBuilder<FinalExamsController>(
        init:
            FinalExamsController(), // تهيئة المتحكم لأول مرة عند فتح هذه الشاشة
        builder: (controller) {
          // بناء محتوى الجسم بناءً على حالة المتحكم الحالي
          return Column(
            // ترتيب العناصر بشكل رأسي (عمودي)
            children: [
              Expanded(
                // جعل قائمة الطلاب تأخذ كل المساحة المتبقية من الشاشة
                child: Obx(
                  // استخدام Obx لمراقبة المتغيرات اللحظية (Reactive) مثل حالة التحميل
                  () =>
                      controller
                          .isLoading
                          .value // التحقق مما إذا كان المتحكم في حالة جلب بيانات
                      ? const Center(
                          child: CircularProgressIndicator(),
                        ) // عرض مؤشر تحميل دائري في منتصف الشاشة
                      : RefreshIndicator(
                          // أداة تسمح للمستخدم بتحديث البيانات عند السحب للأسفل
                          onRefresh: () async => controller
                              .loadExamData(), // استدعاء دالة إعادة تحميل البيانات
                          child:
                              controller
                                  .examRecords
                                  .isEmpty // التحقق مما إذا كانت قائمة السجلات فارغة
                              ? _buildEmptyState(
                                  context,
                                ) // عرض واجهة "لا يوجد بيانات" في حال خلو القائمة
                              : ListView.builder(
                                  // بناء قائمة مرنة لعرض سجلات الطلاب بشكل متتابع
                                  padding: const EdgeInsets.all(
                                    16,
                                  ), // إضافة مسافات حول القائمة من جميع الجهات
                                  itemCount: controller
                                      .examRecords
                                      .length, // عدد العناصر بناءً على عدد الطلاب
                                  itemBuilder: (context, index) {
                                    // دالة بناء شكل كل عنصر (بطاقة طالب)
                                    // استدعاء دالة بناء بطاقة رصد الدرجات لكل طالب على حدة
                                    return _buildExamCard(
                                      context,
                                      controller, // تمرير المتحكم للتحكم بالعمليات
                                      controller
                                          .examRecords[index], // تمرير بيانات الطالب الحالي
                                      index, // تمرير ترتيب الطالب في القائمة
                                    );
                                  },
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

  /// دالة لبناء واجهة التنبيه في حال عدم وجود طلاب منضمين للحلقة المسندة
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      // وضع المحتوى في منتصف الشاشة
      child: Column(
        // ترتيب العناصر رأسياً
        mainAxisAlignment: MainAxisAlignment.center, // توسيط العناصر عمودياً
        children: [
          Icon(
            // عرض أيقونة تدل على المهام أو السجلات
            Icons.assignment_turned_in_outlined,
            size: 64, // حجم كبير للأيقونة ليكون واضحاً
            color: isDark
                ? Colors.grey[600]
                : Colors.grey[400], // لون رمادي باهت ليدل على الفراغ
          ),
          const SizedBox(height: 16), // مسافة فاصلة بين الأيقونة والنص
          Text(
            'no_students_in_circle'
                .tr, // عرض نص "لا يوجد طلاب في هذه الحلقة بعد" المترجم
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ), // تنسيق لون نص رمادي غامق قليلاً
          ),
        ],
      ),
    );
  }

  /// دالة لبناء بطاقة (Card) احترافية لرصد درجات كل طالب
  Widget _buildExamCard(
    BuildContext context,
    FinalExamsController controller, // المتحكم لإدارة تحديثات الدرجات
    FinalExamRecord record, // بيانات سجل الطالب الحالي
    int index, // موقع الطالب في القائمة
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      // الحاوية الأساسية للبطاقة
      margin: const EdgeInsets.only(
        bottom: 24,
      ), // مسافة فاصلة أسفل كل بطاقة طالب
      padding: const EdgeInsets.all(16), // مسافة داخلية لمحتويات البطاقة
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // خلفية البطاقة تتناسب مع الثيم
        borderRadius: BorderRadius.circular(
          24,
        ), // حواف دائرية انسيابية وعصرية للبطاقة
        border: Border.all(
          color: isDark
              ? Colors.grey[800]!
              : Colors.grey[300]!, // حواف خفيفة للبطاقة
          width: 1.5,
        ),
        boxShadow: [
          // إضافة ظل خفيف جداً لإعطاء بعد جمالي وعمق للبطاقة
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.indigo.withValues(alpha: 0.05), // لون الظل
            blurRadius: 20, // مدى تشتت ونعومة الظل
            offset: const Offset(
              0,
              10,
            ), // إزاحة الظل للأسفل ليعطي إيحاءً بالارتفاع
          ),
        ],
      ),
      child: Column(
        // ترتيب محتويات بطاقة الطالب رأسياً
        crossAxisAlignment:
            CrossAxisAlignment.start, // محاذاة العناصر لجهة البداية (اليمين)
        children: [
          Row(
            // ترتيب الاسم والمجموع في سطر واحد أفقياً
            children: [
              // حاوية دائرية تحتوي على أيقونة رمزية تمثل الطالب
              Container(
                padding: const EdgeInsets.all(
                  10,
                ), // مسافة داخل الحاوية الدائرية
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.indigo.withValues(alpha: 0.3)
                      : Colors.indigo.withValues(
                          alpha: 0.1,
                        ), // لون خلفية دائري فاتح جداً
                  shape: BoxShape.circle, // جعل الشكل دائرياً تماماً
                ),
                child: Icon(
                  Icons.person,
                  color: isDark ? Colors.indigoAccent : Colors.indigo,
                  size: 24,
                ), // أيقونة شخص بلون نيلي
              ),
              const SizedBox(width: 12), // مسافة أفقية بين الأيقونة والاسم
              Expanded(
                // جعل قسم الاسم يأخذ أكبر مساحة متاحة في السطر
                child: Text(
                  record
                      .studentName, // عرض اسم الطالب المسترجع من قاعدة البيانات
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // جعل خط الاسم عريضاً
                    fontSize: 18, // حجم خط الاسم
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color, // لون النص الأساسي
                  ),
                ),
              ),
              // استدعاء ويدجت عرض المجموع الكلي للطالب بصيغة جذابة
              _buildTotalBadge(record.totalScore),
            ],
          ),
          const SizedBox(height: 20), // مسافة فاصلة قبل قسم إدخال الدرجات
          // إنشاء صف يحتوي على ثلاثة حقول إدخال للدرجات (حفظ، تجويد، تلاوة)
          Row(
            children: [
              // بناء حقل إدخال درجة الحفظ
              _buildScoreCard(
                context,
                controller, // تمرير المتحكم
                index, // اندكس الطالب
                'hifz', // النوع البرمجي للدرجة
                'hifz'.tr, // المسمى المترجم (حفظ)
                '50', // الدرجة القصوى المسموح بها
                record.hifzScore, // القيمة الحالية من السجل
                isDark
                    ? Colors.blueAccent
                    : Colors.blue, // اللون المميز لهذا القسم (أزرق)
              ),
              const SizedBox(width: 12), // مسافة بين حقل الحفظ والتجويد
              // بناء حقل إدخال درجة التجويد
              _buildScoreCard(
                context,
                controller,
                index,
                'tajweed', // النوع البرمجي
                'tajweed'.tr, // المسمى المترجم (تجويد)
                '30', // الدرجة القصوى
                record.tajweedScore, // القيمة الحالية
                isDark
                    ? Colors.tealAccent
                    : Colors.teal, // اللون المميز (تيلي/أخضر مزرق)
              ),
              const SizedBox(width: 12), // مسافة بين حقل التجويد والتلاوة
              // بناء حقل إدخال درجة التلاوة
              _buildScoreCard(
                context,
                controller,
                index,
                'tilawah', // النوع البرمجي
                'tilawah'.tr, // المسمى المترجم (تلاوة)
                '20', // الدرجة القصوى
                record.tilawahScore, // القيمة الحالية
                isDark
                    ? Colors.purpleAccent
                    : Colors.deepPurple, // اللون المميز (أرجواني غامق)
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ويدجت لعرض المجموع الكلي للطالب من 100 مع تدرج لوني أخضر جذاب
  Widget _buildTotalBadge(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ), // مسافات داخلية للبطاقة الصغيرة
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          // استخدام تدرج لوني يوحي بالنجاح والتميز
          colors: [
            Colors.green,
            Color(0xFF43A047),
          ], // من الأخضر الفاتح للأخضر الغامق
        ),
        borderRadius: BorderRadius.circular(14), // حواف دائرية للبطاقة الصغيرة
        boxShadow: [
          // ظل أخضر خفيف حول بطاقة المجموع
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3), // لون الظل أخضر شفاف
            blurRadius: 8, // مدى نعومة الظل
            offset: const Offset(0, 4), // إزاحة الظل للأسفل قليلاً
          ),
        ],
      ),
      child: Text(
        '${'total'.tr}: ${score.toInt()}/100', // عرض "المجموع: X/100" مترجماً بالكامل
        style: const TextStyle(
          fontWeight: FontWeight.bold, // خط عريض للرقم
          color: Colors.white, // لون نص أبيض للوضوح مع الخلفية الخضراء
          fontSize: 14, // حجم خط مناسب
        ),
      ),
    );
  }

  /// دالة لبناء حقل إدخال الدرجة لكل تصنيف بشكل منفصل ومنظم
  Widget _buildScoreCard(
    BuildContext context,
    FinalExamsController controller, // المتحكم للتحديث الفوري
    int studentIndex, // ترتيب الطالب في القائمة
    String type, // نوع الدرجة (hifz, tajweed, tilawah)
    String label, // النص المعروض للمستخدم (مترجم)
    String maxScore, // القيمة القصوى لهذه الدرجة
    double currentScore, // الدرجة الحالية المدخلة
    Color color, // اللون المخصص لهذا الحقل
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // تنسيق عرض الدرجة لإخفاء الفواصل العشرية إذا كانت صفراً (مثال: 5.0 تظهر 5)
    String scoreText = currentScore == currentScore.toInt()
        ? currentScore.toInt().toString()
        : currentScore.toString();

    return Expanded(
      // جعل الحقل يتقاسم المساحة مع الحقول الأخرى بالتساوي
      child: Container(
        padding: const EdgeInsets.all(12), // مسافة داخلية لحاوية الحقل
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.04), // خلفية شفافة جداً بلون التمييز
          borderRadius: BorderRadius.circular(18), // حواف دائرية للحقل
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1.5,
          ), // إطار خفيف بلون التمييز
        ),
        child: Column(
          // ترتيب التسمية، حقل الإدخال، والدرجة القصوى رأسياً
          children: [
            // تسمية الحقل (مثل: حفظ، تجويد، الخ)
            Text(
              label,
              style: TextStyle(
                fontSize: 12, // حجم خط صغير للتسمية
                color: isDark ? color : color, // لون التسمية نفس لون التمييز
                fontWeight: FontWeight.bold, // خط عريض للتسمية
              ),
            ),
            const SizedBox(height: 8), // مسافة فاصلة
            IntrinsicWidth(
              // جعل حقل الإدخال يتناسب عرضه مع محتواه الرقمي
              child: TextFormField(
                // حقل إدخال النص الخاص بالدرجة
                key: ValueKey(
                  '${studentIndex}_${type}_$scoreText',
                ), // مفتاح فريد لتجنب مشاكل إعادة البناء
                initialValue: scoreText, // تعيين القيمة الحالية كقيمة ابتدائية
                textAlign: TextAlign.center, // توسيط الرقم داخل الحقل
                keyboardType: const TextInputType.numberWithOptions(
                  // تحديد لوحة المفاتيح الرقمية مع دعم الفواصل
                  decimal: true,
                ),
                style: TextStyle(
                  fontSize: 20, // حجم رقم الدرجة ليكون واضحاً
                  fontWeight: FontWeight.bold, // جعل الرقم عريضاً
                  color: color, // تلوين الرقم بلون التمييز الخاص به
                ),
                decoration: const InputDecoration(
                  isDense:
                      true, // جعل الحقل مضغوطاً لتقليل المساحات البيضاء الزائدة
                  border: InputBorder
                      .none, // إخفاء الإطار الافتراضي لـ TextFormField
                  contentPadding:
                      EdgeInsets.zero, // إلغاء المسافات الداخلية الافتراضية
                ),
                onChanged: (value) {
                  // محاولة تحويل النص المدخل إلى رقم عشري وتحديث المتحكم
                  double? newScore = double.tryParse(value);
                  if (newScore != null) {
                    // استدعاء دالة التحديث في المتحكم لتطبيق التغييرات فورياً
                    controller.updateScore(studentIndex, type, newScore);
                  }
                },
              ),
            ),
            const Divider(height: 12), // خط أفقي فاصل خفيف داخل بطاقة الدرجة
            // عرض الدرجة القصوى المسموح بها تحت حقل الإدخال (مثال: /50)
            Text(
              '/$maxScore',
              style: TextStyle(
                fontSize: 11, // حجم خط صغير جداً للتوضيح
                color: isDark
                    ? Colors.grey[400]
                    : Colors.grey[500], // لون رمادي هادئ
                fontWeight: FontWeight.w500, // سمك خط متوسط
              ),
            ),
          ],
        ),
      ),
    );
  }
}
