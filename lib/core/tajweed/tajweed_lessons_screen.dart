import 'dart:io'; // استيراد مكتبة التعامل مع الملفات
import 'package:flutter/services.dart'; // استيراد خدمات النظام للوصول للملفات المدمجة (Assets)
import 'package:flutter/material.dart'; // استيراد مكتبة واجهات فلاتر الأساسية
import 'package:get/get.dart'; // استيراد مكتبة GetX للترجمة وإدارة التنقل والرسائل المنبثقة
import 'package:path_provider/path_provider.dart'; // استيراد مكتبة للحصول على المجلدات المؤقتة في الهاتف
import 'package:open_filex/open_filex.dart'; // استيراد مكتبة لفتح الملفات باستخدام التطبيقات الخارجية (مثل قارئ PDF)

/// شرح عمل الملف:
/// هذا الملف يمثل "شاشة دروس التجويد" (TajweedLessonsScreen).
/// وظيفتها الأساسية هي عرض قائمة بملفات تعليمية (PDF) مدمجة داخل التطبيق حول أحكام التجويد.
///
/// أين يستخدم:
/// 1. في لوحة تحكم الطالب: للوصول للمادة العلمية والمذاكرة.
/// 2. في لوحة تحكم المعلم: كمرجع تعليمي أثناء الشرح في الحلقات.

class TajweedLessonsScreen extends StatelessWidget {
  const TajweedLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة الدروس: تحتوي على العنوان الظاهر واسم الملف الفعلي داخل مجلد assets/pdf/tajweed/
    final List<Map<String, String>> lessons = [
      {'title': 'مبادى علم التجويد', 'file': 'tajweed_intro.pdf'},
      {'title': 'ألاستعاذة', 'file': 'istiadha.pdf'},
      {'title': 'أحكام النون الساكنة والتنوين', 'file': 'noon_sakinah.pdf'},
      {
        'title': 'تابع احكام النون الساكنه والتنوين ',
        'file': 'noon_sakinah_part2.pdf',
      },
      {
        'title': ' احكام النون والميم المشددتين',
        'file': 'noon_meem_mushaddadah.pdf',
      },
      {'title': 'أحكام الميم الساكنه', 'file': 'meem_sakinah.pdf'},
      {'title': 'أحكام اللامات', 'file': 'laam_rules.pdf'},
      {'title': ' باب مخارج الحروف', 'file': 'makharij.pdf'},
      {'title': ' تابع مخارج الحروف', 'file': 'makharij_part2.pdf'},
      {'title': 'باب صفات الحروف', 'file': 'sifat.pdf'},
      {'title': ' تقسيم الصفات الى قوية وضعيفه', 'file': 'sifat_types.pdf'},
      {'title': ' باب التفخيم والترقيق', 'file': 'tafkheem_tarqeeq.pdf'},
      {
        'title': ' باب المثلين والمتقاربين والمتباعدين',
        'file': 'mutamathilayn.pdf',
      },
    ];

    return Scaffold(
      backgroundColor:
          Colors.transparent, // جعل الخلفية شفافة لتظهر خلفية الحاوية
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // إضافة تدرج لوني جمالي للخلفية يتناسب مع الثيم
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Get.isDarkMode
                ? [
                    Theme.of(context).cardColor,
                    Theme.of(context).scaffoldBackgroundColor,
                  ]
                : [
                    Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    Colors.white,
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الصفحة (مترجم)
              Text(
                'tajweed_lessons'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              // قائمة الدروس القابلة للتمرير
              Expanded(
                child: ListView.builder(
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          // أيقونة ملف PDF داخل مربع ملون
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          lesson['title']!, // عنوان الدرس
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'tap_to_view_lesson'.tr, // نص "اضغط لعرض الدرس" مترجم
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () =>
                            _openLesson(lesson['file']!), // فتح الملف عند النقر
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// دالة فتح ملف الدرس: تقوم بنسخ الملف من الأصول إلى الذاكرة المؤقتة ثم فتحه
  Future<void> _openLesson(String fileName) async {
    try {
      // إظهار مؤشر تحميل (Loading) لمنع المستخدم من النقر المتكرر
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // تحديد مسار الملف في الـ Assets
      final String assetPath = "assetes/pdf/tajweed/$fileName";

      // تحميل بيانات الملف الثنائية
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();

      // الحصول على مجلد مؤقت في الجهاز لكتابة الملف فيه (لأن ملفات الأصول للقراءة فقط)
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/$fileName');

      // كتابة الملف في التخزين المؤقت
      await tempFile.writeAsBytes(bytes, flush: true);

      Get.back(); // إغلاق مؤشر التحميل

      // محاولة فتح الملف باستخدام التطبيق الافتراضي في الجهاز
      final result = await OpenFilex.open(tempFile.path);

      // إذا فشل الفتح (لعدم وجود تطبيق PDF مثلاً)
      if (result.type != ResultType.done) {
        Get.snackbar(
          'error'.tr, // عنوان "خطأ" مترجم
          'no_pdf_app_error'.tr, // رسالة "لا يوجد تطبيق متوافق" مترجمة
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // التأكد من إغلاق مؤشر التحميل في حال حدوث خطأ
      // إشعار المستخدم في حال فقدان الملف من أصول التطبيق
      Get.snackbar(
        'warning'.tr, // عنوان "تنبيه" مترجم
        'file_missing_error'.tr, // رسالة "الملف غير موجود" مترجمة
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }
}
