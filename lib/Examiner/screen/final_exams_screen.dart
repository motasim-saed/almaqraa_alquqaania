import 'package:flutter/material.dart'; // استيراد حزمة فلاتر الأساسية لتصميم الواجهات
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والترجمة
import 'package:url_launcher/url_launcher.dart'; // استيراد مكتبة فتح الروابط الخارجية
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
              // زر ثلاث نقاط يحتوي على خيار التواصل بالواتساب
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                tooltip: 'خيارات',
                onSelected: (value) async {
                  if (value == 'whatsapp') {
                    final rawPhone = record.phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
                    final whatsappUri = Uri.parse('https://wa.me/$rawPhone');
                    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
                      Get.snackbar(
                        'تنبيه',
                        'تعذّر فتح واتساب، تأكد من تسجيل رقم الهاتف للطالب',
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  if (record.phone.isNotEmpty)
                    PopupMenuItem(
                      value: 'whatsapp',
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'تواصل بالواتساب',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              color: Color(0xFF25D366),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        'لا يوجد رقم هاتف مسجّل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
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
              _ScoreInputField(
                key: ValueKey('${record.studentId}_hifz'),
                label: 'hifz'.tr,
                maxScore: 50,
                initialScore: record.hifzScore,
                color: isDark ? Colors.blueAccent : Colors.blue,
                onScoreChanged: (val) =>
                    controller.updateScore(index, 'hifz', val),
              ),
              const SizedBox(width: 12), // مسافة بين حقل الحفظ والتجويد
              // بناء حقل إدخال درجة التجويد
              _ScoreInputField(
                key: ValueKey('${record.studentId}_tajweed'),
                label: 'tajweed'.tr,
                maxScore: 30,
                initialScore: record.tajweedScore,
                color: isDark ? Colors.tealAccent : Colors.teal,
                onScoreChanged: (val) =>
                    controller.updateScore(index, 'tajweed', val),
              ),
              const SizedBox(width: 12), // مسافة بين حقل التجويد والتلاوة
              // بناء حقل إدخال درجة التلاوة
              _ScoreInputField(
                key: ValueKey('${record.studentId}_tilawah'),
                label: 'tilawah'.tr,
                maxScore: 20,
                initialScore: record.tilawahScore,
                color: isDark ? Colors.purpleAccent : Colors.deepPurple,
                onScoreChanged: (val) =>
                    controller.updateScore(index, 'tilawah', val),
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
}

/// ويدجت مخصص لحقل إدخال الدرجة لضمان بقاء لوحة المفاتيح مفتوحة وتقييد القيم بسلاسة
class _ScoreInputField extends StatefulWidget {
  final double initialScore;
  final double maxScore;
  final Color color;
  final String label;
  final ValueChanged<double> onScoreChanged;

  const _ScoreInputField({
    super.key,
    required this.initialScore,
    required this.maxScore,
    required this.color,
    required this.label,
    required this.onScoreChanged,
  });

  @override
  State<_ScoreInputField> createState() => _ScoreInputFieldState();
}

class _ScoreInputFieldState extends State<_ScoreInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatScore(widget.initialScore),
    );
    _focusNode = FocusNode();
  }

  String _formatScore(double score) {
    if (score == 0) return '';
    return score == score.toInt() ? score.toInt().toString() : score.toString();
  }

  @override
  void didUpdateWidget(covariant _ScoreInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.initialScore != widget.initialScore) {
      final formatted = _formatScore(widget.initialScore);
      if (_controller.text != formatted) {
        _controller.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value.trim().isEmpty) {
      widget.onScoreChanged(0.0);
      return;
    }

    final double? parsed = double.tryParse(value);
    if (parsed != null) {
      if (parsed > widget.maxScore) {
        // إذا كان الرقم المدخل أكبر من الحد الأقصى (مثلاً 55 والحد 50)، يثبت على الحد الأقصى تلقائياً
        final clamped = widget.maxScore;
        final formattedClamped = _formatScore(clamped);
        _controller.value = TextEditingValue(
          text: formattedClamped,
          selection: TextSelection.collapsed(offset: formattedClamped.length),
        );
        widget.onScoreChanged(clamped);
      } else if (parsed < 0) {
        _controller.value = const TextEditingValue(
          text: '0',
          selection: TextSelection.collapsed(offset: 1),
        );
        widget.onScoreChanged(0.0);
      } else {
        widget.onScoreChanged(parsed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxScoreText = widget.maxScore == widget.maxScore.toInt()
        ? widget.maxScore.toInt().toString()
        : widget.maxScore.toString();

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? widget.color.withValues(alpha: 0.1)
              : widget.color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                color: widget.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            IntrinsicWidth(
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: widget.color.withValues(alpha: 0.35),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: _onChanged,
              ),
            ),
            const Divider(height: 12),
            Text(
              '/$maxScoreText',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
