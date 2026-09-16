// استيراد حزمة dart:io للتعامل مع الملفات
import 'dart:io';
// استيراد حزمة فلاتر للتعامل مع الواجهات والتنبيهات
// import 'package:flutter/material.dart';
// استيراد حزمة Excel لإنشاء وتعديل ملفات الجداول
import 'package:excel/excel.dart';
// استيراد حزمة GetX لدعم الترجمة وإدارة الحالة
import 'package:get/get.dart';
// استيراد حزمة path_provider للحصول على مسارات التخزين في الهاتف
import 'package:path_provider/path_provider.dart';
// استيراد حزمة open_filex لفتح الملفات بعد إنشائها
import 'package:open_filex/open_filex.dart';
// استيراد النماذج الخاصة بالإدارة والمعلمين والطلاب
import 'package:al_maqraa/Admin/models/admin_models.dart';
// استيراد نماذج الاختبارات والسجلات الشهرية والسنوية
import 'package:al_maqraa/Teacher/models/monthly_exam_model.dart';
import 'package:al_maqraa/Teacher/models/monthly_record_model.dart';
import 'package:al_maqraa/Admin/models/yearly_record_model.dart';

/// خدمة تصدير الملفات (FileExportService)
/// المسؤولة عن تحويل البيانات إلى ملفات Excel وتخزينها في الهاتف لسهولة الأرشفة والمشاركة
class FileExportService {
  /// تصدير قائمة المعلمين إلى ملف Excel
  /// [teachers]: قائمة كائنات المعلمين المراد تصديرها
  /// [selectedColumns]: قائمة اختيارية بالأعمدة المحددة للتصدير
  static Future<void> exportTeachersToExcel(
    List<TeacherModel> teachers, {
    List<String>? selectedColumns,
  }) async {
    // إنشاء ملف Excel جديد
    var excel = Excel.createExcel();
    // الحصول على الصفحة الأولى وتسميتها "Teachers"
    Sheet sheetObject = excel['Teachers'];
    excel.delete('Sheet1'); // حذف الصفحة الافتراضية الفارغة

    // تعريف كافة الأعمدة المتاحة وربطها بمفاتيح الترجمة (Arabic/English)
    final allColumns = {
      'name': 'full_name'.tr,
      'email': 'email'.tr,
      'academic_number': 'academic_number'.tr,
      'specialization': 'specialization'.tr,
      'gender': 'gender'.tr,
      'can_cover_balance': 'needs_sponsorship'.tr,
      'sponsorship_amount': 'sponsorship_amount'.tr,
      'package_type': 'package_type'.tr,
      'phone': 'phone'.tr,
    };

    // تحديد الأعمدة المطلوب تصديرها (إما المحددة من المستخدم أو الكل افتراضياً)
    final columnsToExport = selectedColumns ?? allColumns.keys.toList();

    // إضافة صف العناوين (Headers) المترجمة للملف
    sheetObject.appendRow(
      columnsToExport.map((k) => TextCellValue(allColumns[k] ?? k)).toList(),
    );

    // إضافة بيانات كل معلم صفاً بصف
    for (var teacher in teachers) {
      List<CellValue> row = [];
      for (var col in columnsToExport) {
        switch (col) {
          case 'name':
            row.add(TextCellValue(teacher.name));
            break;
          case 'email':
            row.add(TextCellValue(teacher.email));
            break;
          case 'academic_number':
            row.add(TextCellValue(teacher.academicNumber));
            break;
          case 'specialization':
            row.add(TextCellValue(teacher.specialization));
            break;
          case 'gender':
            // استخدام الترجمة للجنس
            row.add(
              TextCellValue(
                teacher.gender == Gender.male ? 'male'.tr : 'female'.tr,
              ),
            );
            break;
          case 'can_cover_balance':
            // استخدام الترجمة لحالة الكفالة
            row.add(
              TextCellValue(
                teacher.canCoverBalance
                    ? 'no_need_sponsorship'.tr
                    : 'needs_sponsorship'.tr,
              ),
            );
            break;
          case 'sponsorship_amount':
            row.add(DoubleCellValue(teacher.sponsorshipAmount ?? 0.0));
            break;
          case 'package_type':
            row.add(TextCellValue(teacher.packageType ?? ''));
            break;
          case 'phone':
            row.add(TextCellValue(teacher.phone));
            break;
          default:
            row.add(TextCellValue(''));
        }
      }
      sheetObject.appendRow(row);
    }

    // حفظ الملف وفتحه
    await _saveAndOpenFile(excel, 'teachers_export.xlsx');
  }

  /// تصدير قائمة الطلاب إلى ملف Excel
  /// [students]: قائمة كائنات الطلاب
  static Future<void> exportStudentsToExcel(
    List<StudentModel> students, {
    List<String>? selectedColumns,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Students'];
    excel.delete('Sheet1');

    final allColumns = {
      'name': 'full_name'.tr,
      'email': 'email'.tr,
      'academic_number': 'academic_number'.tr,
      'level': 'level'.tr,
      'gender': 'gender'.tr,
      'is_distributed': 'is_distributed'.tr,
      'phone': 'phone'.tr,
    };

    final columnsToExport = selectedColumns ?? allColumns.keys.toList();

    // إضافة صف العناوين المترجمة
    sheetObject.appendRow(
      columnsToExport.map((k) => TextCellValue(allColumns[k] ?? k)).toList(),
    );

    // إضافة بيانات الطلاب
    for (var student in students) {
      List<CellValue> row = [];
      for (var col in columnsToExport) {
        switch (col) {
          case 'name':
            row.add(TextCellValue(student.name));
            break;
          case 'email':
            row.add(TextCellValue(student.email));
            break;
          case 'academic_number':
            row.add(TextCellValue(student.academicNumber));
            break;
          case 'level':
            row.add(TextCellValue(student.level));
            break;
          case 'gender':
            row.add(
              TextCellValue(
                student.gender == Gender.male ? 'male'.tr : 'female'.tr,
              ),
            );
            break;
          case 'is_distributed':
            row.add(
              TextCellValue(student.isDistributed ? 'yes_val'.tr : 'no_val'.tr),
            );
            break;
          case 'phone':
            row.add(TextCellValue(student.phone));
            break;
          default:
            row.add(TextCellValue(''));
        }
      }
      sheetObject.appendRow(row);
    }

    await _saveAndOpenFile(excel, 'students_export.xlsx');
  }

  /// تصدير التقرير الشهري للحلقة (درجات الحفظ والمواظبة)
  /// [circleName]: اسم الحلقة
  /// [records]: سجلات الطلاب الشهرية
  static Future<void> exportMonthlyReportToExcel(
    String circleName,
    List<MonthlyRecord> records,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Monthly Report'];
    excel.delete('Sheet1');

    // صف العناوين المترجم للتقرير الشهري
    final headers = [
      'student_name'.tr,
      'present'.tr,
      'absent'.tr,
      'excused'.tr,
      'holiday'.tr,
      'hifz_score'.tr,
      'tajweed_score'.tr,
      'tilawah_score'.tr,
      'monthly_grade'.tr,
    ];

    sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // تعبئة سجلات الطلاب
    for (var rec in records) {
      sheetObject.appendRow([
        TextCellValue(rec.studentName),
        IntCellValue(rec.attendanceDays),
        IntCellValue(rec.absenceDays),
        IntCellValue(rec.excusedDays),
        IntCellValue(rec.holidayDays),
        DoubleCellValue(rec.hifzScore.toDouble()),
        DoubleCellValue(rec.tajweedScore.toDouble()),
        DoubleCellValue(rec.tilawahScore.toDouble()),
        IntCellValue(rec.monthlyGrade),
      ]);
    }

    // إنشاء اسم الملف وتطهيره من الرموز غير الصالحة
    final fileName = 'monthly_report_${_sanitizeFileName(circleName)}.xlsx';
    await _saveAndOpenFile(excel, fileName);
  }

  /// تصدير التقرير السنوي التراكمي للحلقة (درجات الشهور)
  static Future<void> exportYearlyReportToExcel(
    String circleName,
    List<YearlyRecord> records,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Yearly Report'];
    excel.delete('Sheet1');

    // صف العناوين المترجم للتقرير السنوي (اسم الطالب + 12 شهر + المتوسط + النهائي)
    List<String> headers = ['student_name'.tr];
    for (int i = 1; i <= 12; i++) {
      headers.add('month_$i'.tr);
    }
    headers.addAll([
      'monthly_average'.tr,
      'final_exam'.tr,
      'final_result'.tr,
    ]);

    sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var rec in records) {
      List<CellValue> row = [TextCellValue(rec.studentName)];
      
      // إضافة درجات الـ 12 شهر
      for (int i = 1; i <= 12; i++) {
        final grade = rec.monthlyGrades[i];
        row.add(grade != null ? IntCellValue(grade) : TextCellValue('-'));
      }

      // إضافة المتوسط والنتائج
      row.add(DoubleCellValue(rec.monthlyAverageExam));
      row.add(DoubleCellValue(rec.finalExamResult));
      row.add(DoubleCellValue(rec.finalResult));

      sheetObject.appendRow(row);
    }

    final fileName = 'yearly_report_${_sanitizeFileName(circleName)}.xlsx';
    await _saveAndOpenFile(excel, fileName);
  }

  /// تصدير سجل درجات الاختبارات للحلقة
  static Future<void> exportExamsToExcel(
    String circleName,
    List<MonthlyExamRecord> records,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Exams Report'];
    excel.delete('Sheet1');

    final headers = [
      'student_name'.tr,
      'hifz_score'.tr,
      'tajweed_score'.tr,
      'tilawah_score'.tr,
    ];

    sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var rec in records) {
      sheetObject.appendRow([
        TextCellValue(rec.studentName),
        DoubleCellValue(rec.hifzScore.toDouble()),
        DoubleCellValue(rec.tajweedScore.toDouble()),
        DoubleCellValue(rec.tilawahScore.toDouble()),
      ]);
    }

    final fileName = 'exams_report_${_sanitizeFileName(circleName)}.xlsx';
    await _saveAndOpenFile(excel, fileName);
  }

  /// دالة داخلية لتنظيف اسم الملف من الرموز غير المسموحة التي قد تسبب خطأ في الحفظ
  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s Arab]'), '');
  }

  /// دالة داخلية لحفظ مصفوفة بايتات الـ Excel في ملف وفتحه للمستخدم
  static Future<void> _saveAndOpenFile(Excel excel, String fileName) async {
    // حفظ محتوى الـ Excel في مصفوفة بايتات
    var fileBytes = excel.save();
    if (fileBytes != null) {
      // الحصول على المجلد المؤقت للنظام
      final directory = await getTemporaryDirectory();
      // إنشاء الملف الفعلي في ذاكرة الهاتف
      final file = File('${directory.path}/$fileName')
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      try {
        // محاولة فتح الملف باستخدام التطبيقات المثبتة في الهاتف (مثل Excel)
        await OpenFilex.open(file.path);
      } catch (e) {
      }
    }
  }
}
