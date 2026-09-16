import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والتنقل
import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية للواجهات
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد مكتبة سوبابيس للتعامل مع قاعدة البيانات السحابية
import 'package:get_storage/get_storage.dart'; // استيراد GetStorage للكاش
import '../model/final_exam_model.dart'; // استيراد نموذج بيانات سجل الاختبارات النهائية
// import 'package:flutter/foundation.dart'; // استيراد مكتبة الأساسيات للتحقق من وضع التطوير

class FinalExamsController extends GetxController {
  // تعريف فئة المتحكم الخاص بالاختبارات النهائية
  final SupabaseClient _supabase = Supabase.instance.client; // إنشاء نسخة من عميل سوبابيس للعمليات البرمجية
  final GetStorage _storage = GetStorage(); // أداة التخزين المحلي
  static const String _examCacheKey = 'examiner_final_exams_cache';

  var examRecords =
      <FinalExamRecord>[].obs; // قائمة مراقبة تحتوي على سجلات اختبارات الطلاب
  var isLoading = false.obs; // متغير مراقبة لحالة التحميل لعرض مؤشر الانتظار

  String? _circleId; // متغير خاص لتخزين معرف الحلقة الحالي
  String? _teacherId; // متغير خاص لتخزين معرف المعلم المرتبط بالحلقة
  String? _examinerId; // متغير خاص لتخزين معرف المختبر الحالي

  @override
  void onInit() {
    // دالة تهيئة المتحكم عند استدعائه لأول مرة
    super.onInit(); // استدعاء دالة التهيئة من الفئة الأم
    _loadFromCache(); // تحميل البيانات من الكاش فوراً
    loadExamData(); // البدء بتحميل بيانات الاختبارات من السيرفر وتحديث الكاش
  }

  void _saveToCache() {
    _storage.write(_examCacheKey, examRecords.map((e) => e.toJson('', '', '')).toList());
  }

  void _loadFromCache() {
    final cached = _storage.read(_examCacheKey);
    if (cached != null) {
      examRecords.assignAll((cached as List).map((e) => FinalExamRecord.fromJson(e)).toList());
    }
  }

  Future<void> loadExamData() async {
    // دالة لجلب بيانات الطلاب وسجلات اختباراتهم من قاعدة البيانات
    if (examRecords.isEmpty) {
      isLoading.value = true; // تفعيل حالة التحميل فقط إذا كان الكاش فارغاً
    }
    try {
      // بدء كتلة محاولة التنفيذ للتعامل مع الأخطاء المحتملة
      _examinerId = _supabase
          .auth
          .currentUser
          ?.id; // جلب المعرف الفريد للمستخدم الحالي (المختبر)
      if (_examinerId == null) {
        return; // الخروج من الدالة إذا لم يتم العثور على مستخدم مسجل
      }

      final circleData =
          await _supabase // الاستعلام عن الحلقة المرتبطة بهذا المختبر
              .from('circles') // الوصول لجدول الحلقات
              .select('id, teacher_id') // اختيار حقول المعرف ومعرف المعلم فقط
              .eq(
                'examiner_id',
                _examinerId!,
              ) // تصفية النتائج بناءً على معرف المختبر
              .maybeSingle(); // الحصول على نتيجة واحدة أو لا شيء

      if (circleData == null) {
        // التحقق مما إذا كانت النتائج فارغة
        examRecords.value = []; // تفريغ قائمة السجلات في الواجهة
        return; // التوقف عن إكمال التنفيذ
      }

      _circleId = circleData['id']
          ?.toString(); // تخزين معرف الحلقة بعد تحويله لنص
      _teacherId = circleData['teacher_id']
          ?.toString(); // تخزين معرف المعلم بعد تحويله لنص

      if (_circleId == null) return; // التأكد من وجود معرف للحلقة قبل المتابعة

      final membersResponse =
          await _supabase // الاستعلام عن الطلاب المنضمين لهذه الحلقة
              .from('circle_members') // الوصول لجدول أعضاء الحلقات
              .select(
                'student_id, profiles:student_id(full_name)',
              ) // جلب معرف الطالب واسمه من جدول البروفايلات
              .eq(
                'circle_id',
                _circleId!,
              ); // تصفية الطلاب حسب معرف الحلقة الحالية

      List<FinalExamRecord> initialRecords =
          []; // إنشاء قائمة مؤقتة لتجهيز السجلات
      for (var row in membersResponse as List) {
        // التكرار على كل سطر من نتائج الطلاب
        final profile =
            row['profiles']
                as Map<String, dynamic>?; // استخراج بيانات البروفايل (الاسم)
        final studentName =
            profile?['full_name'] ??
            'unknown_student'.tr; // تعيين الاسم أو نص افتراضي مترجم
        initialRecords.add(
          FinalExamRecord(
            // إضافة كائن سجل جديد للقائمة المؤقتة
            studentId: row['student_id'].toString(), // تعيين معرف الطالب
            studentName: studentName, // تعيين اسم الطالب
          ),
        );
      }

      final currentYear = DateTime.now().year; // تحديد السنة الميلادية الحالية
      final savedRecordsResponse =
          await _supabase // جلب سجلات الاختبارات المحفوظة مسبقاً للسنة الحالية
              .from('final_exams') // الوصول لجدول الاختبارات النهائية
              .select() // اختيار جميع الحقول المتاحة
              .eq('circle_id', _circleId!) // الفلترة حسب الحلقة
              .eq('year', currentYear); // الفلترة حسب السنة الحالية

      Map<String, FinalExamRecord> savedMap =
          {}; // إنشاء خريطة لربط المعرف بالسجل لسرعة الوصول
      for (var row in savedRecordsResponse as List) {
        // التكرار على السجلات المحفوظة المستلمة
        final rec = FinalExamRecord.fromJson(
          row,
        ); // تحويل البيانات من JSON إلى كائن برمجي
        savedMap[rec.studentId] =
            rec; // إضافة السجل للخريطة باستخدام معرف الطالب كمفتاح
      }

      for (int i = 0; i < initialRecords.length; i++) {
        // دمج البيانات المحفوظة مع قائمة الطلاب الحالية
        final sid = initialRecords[i]
            .studentId; // الحصول على معرف الطالب من السجل الحالي
        if (savedMap.containsKey(sid)) {
          // إذا وجد سجل محفوظ مسبقاً لهذا الطالب
          initialRecords[i].hifzScore =
              savedMap[sid]!.hifzScore; // تعيين درجة الحفظ المخزنة
          initialRecords[i].tajweedScore =
              savedMap[sid]!.tajweedScore; // تعيين درجة التجويد المخزنة
          initialRecords[i].tilawahScore =
              savedMap[sid]!.tilawahScore; // تعيين درجة التلاوة المخزنة
        }
      }

      examRecords.value =
          initialRecords; // تحديث قائمة السجلات النهائية لعرضها في الواجهة
    } catch (e) {
      // في حالة فشل أي عملية من العمليات السابقة
      Get.snackbar(
        // عرض رسالة تنبيه للمستخدم تفيد بوجود خطأ
        'alert'.tr, // عنوان التنبيه المترجم
        'error_loading_data'.tr, // رسالة خطأ في التحميل مترجمة
        backgroundColor: Colors.orange, // لون خلفية التنبيه
        colorText: Colors.white, // لون نص التنبيه
      );
    } finally {
      // كود يتم تنفيذه في جميع الأحوال (نجاح أو فشل)
      isLoading.value = false; // إيقاف حالة التحميل لإخفاء مؤشر الانتظار
      _saveToCache(); // تحديث الكاش بالبيانات الجديدة
    }
  }

  void updateScore(int studentIndex, String type, double newScore) {
    // دالة لتعديل الدرجات مع التحقق من الحدود
    if (studentIndex < 0 || studentIndex >= examRecords.length) {
      return; // التأكد من صحة موقع الطالب في القائمة
    }

    final record = examRecords[studentIndex]; // الوصول للسجل المطلوب تعديله

    // منع إدخال قيم سالبة
    double validatedScore = newScore < 0 ? 0 : newScore;

    switch (type) {
      // تحديد نوع الدرجة وتطبيق الحد الأقصى المطلوب
      case 'hifz': // درجة الحفظ (الحد الأقصى 50)
        // إذا كانت القيمة > 50 يتم تخزين 50، وإلا يتم تخزين القيمة المدخلة
        record.hifzScore = validatedScore > 50 ? 50 : validatedScore;
        break;
      case 'tajweed': // درجة التجويد (الحد الأقصى 30)
        // إذا كانت القيمة > 30 يتم تخزين 30، وإلا يتم تخزين القيمة المدخلة
        record.tajweedScore = validatedScore > 30 ? 30 : validatedScore;
        break;
      case 'tilawah': // درجة التلاوة (الحد الأقصى 20)
        // إذا كانت القيمة > 20 يتم تخزين 20، وإلا يتم تخزين القيمة المدخلة
        record.tilawahScore = validatedScore > 20 ? 20 : validatedScore;
        break;
    }
    examRecords.refresh(); // تحديث الواجهة فوراً لعرض القيمة الصحيحة (المصححة)
  }

  Future<void> saveExamData() async {
    // دالة لحفظ جميع الدرجات المدخلة في قاعدة البيانات
    if (_circleId == null || _examinerId == null) {
      // التأكد من توفر البيانات الأساسية للحفظ
      Get.snackbar(
        'error'.tr,
        'no_circle_assigned'.tr,
      ); // تنبيه المختبر بضرورة وجود حلقة مسندة
      return; // التوقف عن الحفظ
    }

    try {
      // محاولة إجراء عمليات الحفظ في السيرفر
      Get.dialog(
        // إظهار نافذة انتظار تمنع التفاعل حتى اكتمال الحفظ
        const Center(
          child: CircularProgressIndicator(),
        ), // وضع مؤشر تحميل في وسط النافذة
        barrierDismissible:
            false, // منع إغلاق النافذة بالضغط خارجها لضمان استقرار العملية
      );

      // تجهيز قائمة البيانات بصيغة JSON مع إضافة السنة الحالية لضمان دقة الأرشفة
      final currentYear = DateTime.now().year;
      final List<Map<String, dynamic>> upsertData = examRecords.map((r) {
        var json = r.toJson(_circleId!, _teacherId ?? '', _examinerId!);
        json['year'] = currentYear; // التأكد من إرفاق السنة الحالية في كل سجل
        return json;
      }).toList();

      // حذف السجلات القديمة لنفس الحلقة والسنة لضمان عدم تكرار البيانات وتحديثها بشكل نظيف
      await _supabase
          .from('final_exams')
          .delete()
          .eq('circle_id', _circleId!)
          .eq('year', currentYear);

      if (upsertData.isNotEmpty) {
        // إذا كانت هناك بيانات مدخلة للطلاب
        // إدراج السجلات الجديدة دفعة واحدة في قاعدة البيانات
        await _supabase.from('final_exams').insert(upsertData);
      }

      if (Get.isDialogOpen!) {
        Get.back(); // إغلاق نافذة الانتظار بعد نجاح العملية
      }

      Get.snackbar(
        // إظهار رسالة نجاح واضحة للمستخدم
        'success'.tr,
        'save_exam_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // في حال حدوث أي خطأ تقني أثناء الحفظ (انترنت، صلاحيات، الخ)
      if (Get.isDialogOpen!) Get.back(); // إغلاق نافذة الانتظار إذا كانت مفتوحة
      Get.snackbar(
        'error'.tr,
        'error_saving_data'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
