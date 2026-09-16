import 'dart:io' show Platform, Directory, File; // استيراد مكتبة التعامل مع الملفات (Input/Output)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data'; // استيراد مكتبة البيانات الثنائية (Bytes)
import 'package:pdf/pdf.dart'; // استيراد حزمة PDF الأساسية للتعامل مع الألوان والقياسات
import 'package:pdf/widgets.dart' as pw; // استيراد ويدجت بناء مستندات PDF
import 'package:printing/printing.dart'; // استيراد حزمة الطباعة وجلب الخطوط من جوجل
import 'package:path_provider/path_provider.dart'; // استيراد حزمة الوصول لمجلدات النظام (تحميلات، مستندات)
import 'package:path/path.dart' as p; // استيراد مكتبة معالجة المسارات لضمان التوافق بين الأنظمة (Windows/Mobile)
import '../../Admin/controller/certificates/certificates_controller.dart'; // استيراد نموذج قالب الشهادة

/// شرح عمل الملف:
/// خدمة الشهادات (CertificateService) هي المسؤول الأول عن تحويل بيانات الطلاب إلى شهادات PDF احترافية.
/// وظائفها تشمل:
/// 1. بناء مستند PDF يحتوي على صفحة لكل طالب بناءً على قالب (Template) محدد مسبقاً.
/// 2. التحكم في مواقع الأسماء والدرجات والألوان والخطوط داخل الشهادة.
/// 3. تنظيف الأسماء من الأحرف غير الصالحة لضمان حفظ الملفات دون أخطاء في نظام ويندوز أو أندرويد.
/// 4. تنظيم حفظ الشهادات في مجلدات هرمية تلقائياً (المقرأة / الجنس / اسم الحلقة / اسم الطالب.pdf).

class CertificateService {

  /// دالة داخلية لبناء مستند PDF (Document) لشهادة واحدة أو مجموعة شهادات
  static Future<pw.Document> _buildPdfDocument({
    required List<Map<String, dynamic>> certificatesData, // قائمة ببيانات الطلاب المراد إصدار شهادات لهم
    String? docTitle, // عنوان المستند (يظهر في خصائص الملف)
  }) async {
    // إنشاء مستند PDF جديد
    final pdf = pw.Document(title: docTitle ?? 'Al Maqraa Certificate');
    // جلب خط "Cairo" العريض من جوجل لدعم اللغة العربية بشكل صحيح
    final arabicFontBold = await PdfGoogleFonts.cairoBold();
    // تحديد مقاس الصفحة (A4) بوضع أفقي (Landscape) المناسب للشهادات
    final pageFormat = PdfPageFormat.a4.landscape;

    // الدوران على بيانات كل طالب لإنشاء صفحة خاصة به
    for (var data in certificatesData) {
      final studentName = data['studentName'] as String; // اسم الطالب
      final finalResult = data['finalResult'] as double; // الدرجة النهائية
      final template = data['template'] as CertificateTemplate; // قالب الشهادة المختار

      // محاولة تحميل صورة الخلفية للقالب إذا كانت موجودة في الجهاز
      pw.ImageProvider? bgImage;
      if (!kIsWeb && template.backgroundImagePath != null && File(template.backgroundImagePath!).existsSync()) {
        bgImage = pw.MemoryImage(File(template.backgroundImagePath!).readAsBytesSync());
      }

      // إضافة صفحة جديدة للمستند
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat, // مقاس الصفحة
          margin: pw.EdgeInsets.zero, // إلغاء الهوامش لتمتد الخلفية على كامل الصفحة
          build: (pw.Context context) {
            final pageW = pageFormat.width; // عرض الصفحة
            final pageH = pageFormat.height; // ارتفاع الصفحة

            return pw.Stack(
              children: [
                // 1. رسم صورة الخلفية إذا وجدت لتغطي كامل الصفحة
                if (bgImage != null) pw.Positioned.fill(child: pw.Image(bgImage, fit: pw.BoxFit.fill)),

                // 2. وضع اسم الطالب في الموقع المحدد داخل القالب
                pw.Positioned(
                  left: 0, right: 0,
                  // حساب الموقع الرأسي بناءً على النسبة المئوية المحددة في القالب
                  top: template.nameY * pageH - (template.nameFontSize / 2),
                  child: pw.Container(
                    alignment: pw.Alignment.center, // توسيط الاسم أفقياً
                    child: pw.Text(
                      studentName,
                      style: pw.TextStyle(
                        font: arabicFontBold, // استخدام الخط العربي
                        fontSize: template.nameFontSize, // حجم الخط من القالب
                        color: PdfColor.fromInt(template.nameColor.toARGB32()), // لون الخط من القالب
                      ),
                      textDirection: pw.TextDirection.rtl, // تحديد اتجاه النص من اليمين لليسار
                    ),
                  ),
                ),

                // 3. وضع الدرجة النهائية في الموقع المحدد داخل القالب
                pw.Positioned(
                  // حساب الموقع الأفقي بناءً على النسبة المئوية
                  left: template.gradeX * pageW - 40,
                  top: template.gradeY * pageH - (template.gradeFontSize / 2),
                  child: pw.Text(
                    '${finalResult.toInt()}', // تحويل الدرجة لرقم صحيح
                    style: pw.TextStyle(
                      font: arabicFontBold,
                      fontSize: template.gradeFontSize,
                      color: PdfColor.fromInt(template.gradeColor.toARGB32()),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    return pdf; // إرجاع المستند المكتمل
  }

  /// دالة لتنظيف الأسماء من المسافات والأحرف التي تمنع حفظ الملفات في أنظمة التشغيل
  static String _sanitizeName(String name) {
    return name
        .trim() // إزالة المسافات الزائدة من البداية والنهاية
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_'); // استبدال أحرف المنع بشرطة سفلية
  }

  /// دالة لحفظ ملف PDF فعلياً في مجلدات منظمة ومنسقة تلقائياً
  static Future<File> saveCertificateFile({
    required Uint8List pdfBytes, // محتوى ملف الـ PDF كبيانات ثنائية
    required String studentName, // اسم الطالب لتسمية الملف
    required String genderName, // اسم الجنس (بنين/بنات) لإنشاء مجلد
    required String circleName, // اسم الحلقة لإنشاء مجلد فرعي
  }) async {
    // 1. الحصول على مسار الحفظ (مجلد التنزيلات للكمبيوتر، أو المستندات للجوال)
    Directory? baseDir;
    if (!kIsWeb && Platform.isWindows) {
      baseDir = await getDownloadsDirectory();
    } else if (!kIsWeb) {
      baseDir = await getApplicationDocumentsDirectory();
    }

    if (baseDir == null) throw Exception("Could not find storage directory");

    // 2. تنظيف الأسماء لضمان عدم حدوث خطأ أثناء إنشاء المسارات في نظام الملفات
    final cleanGender = _sanitizeName(genderName);
    final cleanCircle = _sanitizeName(circleName);
    final cleanStudent = _sanitizeName(studentName);

    // 3. بناء مسار المجلدات المتداخلة بشكل متوافق مع نظام التشغيل الحالي
    final String fullDirPath = p.join(baseDir.path, 'AlMaqraa_Certificates', cleanGender, cleanCircle);
    final Directory dir = Directory(fullDirPath);

    // إنشاء المجلدات بشكل تكراري (Recursive) إذا لم تكن موجودة
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // 4. بناء المسار النهائي للملف وحفظ البيانات فيه
    final String fullFilePath = p.join(dir.path, '$cleanStudent.pdf');
    final File file = File(fullFilePath);
    return await file.writeAsBytes(pdfBytes); // كتابة البايتات في الملف وإرجاعه
  }

  /// دالة لإنشاء بيانات PDF لشهادة طالب واحد فقط (تُستخدم للمعاينة أو الإرسال السريع)
  static Future<Uint8List> generateCertificatePdf({
    required String studentName,
    required double finalResult,
    required CertificateTemplate template,
  }) async {
    final pdf = await _buildPdfDocument(
      docTitle: studentName,
      certificatesData: [{'studentName': studentName, 'finalResult': finalResult, 'template': template}],
    );
    return pdf.save(); // إرجاع البيانات بصيغة Uint8List
  }

  /// دالة لإنشاء ملف PDF واحد يحتوي على مجموعة شهادات (Batch) دفعة واحدة
  static Future<Uint8List> generateBatchCertificatesPdf({
    required List<Map<String, dynamic>> batchData, // قائمة بيانات الطلاب والقوالب
    String? circleName, // اسم الحلقة ليظهر كعنوان للمستند
  }) async {
    final pdf = await _buildPdfDocument(
      docTitle: circleName ?? 'Batch',
      certificatesData: batchData,
    );
    return pdf.save(); // إرجاع الملف المجمع كبيانات ثنائية
  }
}
