import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import 'package:get_storage/get_storage.dart'; // استيراد مكتبة GetStorage للتخزين المحلي البسيط
import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم الواجهات والألوان
import '../../models/admin_models.dart'; // استيراد نماذج بيانات الأدمن (المعلمين، الحلقات، إلخ)
import '../../models/yearly_record_model.dart'; // استيراد نموذج السجل السنوي لدرجات الطلاب
import '../../repository/admin_repository.dart'; // استيراد الواجهة البرمجية للمستودع
import '../../repository/supabase_admin_repository.dart'; // استيراد تنفيذ المستودع باستخدام Supabase

// نموذج يمثل قالب الشهادة وإعدادات التصميم الخاصة به
class CertificateTemplate {
  final String id; // المعرف الفريد للقالب
  String adminTitle; // العنوان الذي يظهر للأدمن في لوحة التحكم فقط
  String title; // عنوان الشهادة (مثلاً: شهادة تقدير)
  Gender gender; // الجنس المستهدف من القالب (بنين/بنات/الكل)
  int minGrade; // الحد الأدنى للدرجة المطلوبة للحصول على هذه الشهادة
  int maxGrade; // الحد الأقصى للدرجة المشمولة في هذا القالب
  Color primaryColor; // اللون الأساسي المعتمد في تصميم القالب
  String? backgroundImagePath; // مسار صورة الخلفية للشهادة (إذا وجد)
  
  // المواقع الديناميكية للعناصر على الشهادة (قيم نسبية من 0.0 إلى 1.0 لتناسب جميع أحجام الشاشات)
  double nameX; // الموقع الأفقي لاسم الطالب
  double nameY; // الموقع الرأسي لاسم الطالب
  double gradeX; // الموقع الأفقي للدرجة أو التقدير
  double gradeY; // الموقع الرأسي للدرجة أو التقدير
  double nameFontSize; // حجم خط اسم الطالب
  double gradeFontSize; // حجم خط الدرجة
  Color nameColor; // لون خط اسم الطالب
  Color gradeColor; // لون خط الدرجة

  // مشيد الكلاس (Constructor) لتهيئة بيانات القالب
  CertificateTemplate({
    required this.id,
    required this.adminTitle,
    this.title = '',
    required this.gender,
    this.minGrade = 90,
    this.maxGrade = 100,
    required this.primaryColor,
    this.backgroundImagePath,
    this.nameX = 0.5,
    this.nameY = 0.45,
    this.gradeX = 0.5,
    this.gradeY = 0.55,
    this.nameFontSize = 35.0,
    this.gradeFontSize = 28.0,
    this.nameColor = Colors.black,
    this.gradeColor = Colors.indigo,
  });

  // تحويل كائن القالب إلى خريطة JSON لحفظه محلياً
  Map<String, dynamic> toJson() => {
    'id': id,
    'adminTitle': adminTitle,
    'title': title,
    'gender': gender.index,
    'minGrade': minGrade,
    'maxGrade': maxGrade,
    'primaryColor': primaryColor.toARGB32(),
    'backgroundImagePath': backgroundImagePath,
    'nameX': nameX, 'nameY': nameY,
    'gradeX': gradeX, 'gradeY': gradeY,
    'nfs': nameFontSize, 'gfs': gradeFontSize,
    'nc': nameColor.toARGB32(), 'gc': gradeColor.toARGB32(),
  };

  // إنشاء كائن قالب من بيانات JSON عند استرجاعه من التخزين
  factory CertificateTemplate.fromJson(Map<String, dynamic> json) => CertificateTemplate(
    id: json['id'],
    adminTitle: json['adminTitle'] ?? '',
    title: json['title'] ?? '',
    gender: Gender.values[json['gender'] ?? 0],
    minGrade: json['minGrade'] ?? 90,
    maxGrade: json['maxGrade'] ?? 100,
    primaryColor: Color(json['primaryColor'] ?? Colors.indigo.toARGB32()),
    backgroundImagePath: json['backgroundImagePath'],
    nameX: json['nameX'] ?? 0.5, nameY: json['nameY'] ?? 0.45,
    gradeX: json['gradeX'] ?? 0.5, gradeY: json['gradeY'] ?? 0.55,
    nameFontSize: json['nfs'] ?? 35.0, gradeFontSize: json['gfs'] ?? 28.0,
    nameColor: Color(json['nc'] ?? Colors.black.toARGB32()),
    gradeColor: Color(json['gc'] ?? Colors.indigo.toARGB32()),
  );
}

// المتحكم المسؤول عن إدارة منطق الشهادات وتصميم النماذج
class CertificatesController extends GetxController {
  final AdminRepository repository = SupabaseAdminRepository(); // نسخة من مستودع البيانات
  final _storage = GetStorage(); // أداة التخزين المحلي لإعدادات النماذج
  final String _storageKey = 'certificate_templates'; // مفتاح الحفظ في التخزين المحلي

  // قوائم مراقبة لتحديث الواجهة تلقائياً
  final RxList<QuranCircleModel> quranCircles = <QuranCircleModel>[].obs; // قائمة الحلقات القرآنية
  final RxBool isLoading = false.obs; // حالة التحميل (True عند جلب بيانات)

  // متغيرات الفلترة في تبويب إصدار الشهادات
  var selectedGenderFilter = Gender.male.obs; // فلتر الجنس المختار (بنين/بنات)
  var searchQuery = ''.obs; // نص البحث عن حلقة معينة

  // قائمة نماذج الشهادات المتاحة والمحفوظة
  final RxList<CertificateTemplate> templates = <CertificateTemplate>[].obs;

  // إضافة قالب شهادة جديد بناءً على الجنس المستهدف
  void addTemplate(Gender gender) {
    final newId = 'template_${DateTime.now().millisecondsSinceEpoch}'; // توليد معرف فريد يعتمد على الوقت
    templates.add(
      CertificateTemplate(
        id: newId,
        adminTitle: gender == Gender.male ? 'new_male_template'.tr : 'new_female_template'.tr,
        title: '',
        gender: gender,
        primaryColor: gender == Gender.male ? Colors.indigo : Colors.pink,
      ),
    );
    _saveTemplates(); // حفظ التغييرات في التخزين المحلي
  }

  // حذف قالب شهادة من القائمة
  void removeTemplate(String id) {
    templates.removeWhere((t) => t.id == id); // إزالة القالب الذي يطابق المعرف
    _saveTemplates(); // تحديث التخزين المحلي
  }

  @override
  void onInit() {
    super.onInit();
    _loadTemplates(); // تحميل النماذج المحفوظة عند بدء التشغيل
    fetchQuranCircles(); // جلب قائمة الحلقات من السيرفر
  }

  // تحميل نماذج الشهادات من التخزين المحلي (GetStorage)
  void _loadTemplates() {
    final stored = _storage.read<List>(_storageKey); // قراءة البيانات المخزنة
    if (stored != null) {
      // تحويل البيانات النصية إلى قائمة من كائنات CertificateTemplate
      templates.assignAll(stored.map((e) => CertificateTemplate.fromJson(Map<String, dynamic>.from(e))).toList());
    } else {
      // إضافة قوالب افتراضية (بنين وبنات) في حال كان التطبيق يفتح لأول مرة
      templates.assignAll([
        CertificateTemplate(
          id: 'template_male',
          adminTitle: 'boys_template'.tr,
          title: 'boys_template'.tr,
          gender: Gender.male,
          primaryColor: Colors.indigo,
          minGrade: 90,
          maxGrade: 100,
        ),
        CertificateTemplate(
          id: 'template_female',
          adminTitle: 'girls_template'.tr,
          title: 'girls_template'.tr,
          gender: Gender.female,
          primaryColor: Colors.pink,
          minGrade: 90,
          maxGrade: 100,
        ),
      ]);
    }
  }

  // حفظ القائمة الحالية لنماذج الشهادات في التخزين المحلي
  void _saveTemplates() {
    _storage.write(_storageKey, templates.map((t) => t.toJson()).toList());
  }

  Future<void> refreshData() => fetchQuranCircles();

  // جلب كافة حلقات القرآن الكريم من قاعدة البيانات (Supabase)
  Future<void> fetchQuranCircles() async {
    try {
      isLoading.value = true; // بدء حالة التحميل
      final circles = await repository.getQuranCircles(); // طلب البيانات من المستودع
      quranCircles.assignAll(circles); // تحديث القائمة المراقبة بالبيانات الجديدة
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_load_circles'.tr); // عرض خطأ في حال فشل الجلب
    } finally {
      isLoading.value = false; // إنهاء حالة التحميل
    }
  }

  // الحصول على عدد حلقات البنين
  int get maleCirclesCount => quranCircles.where((c) => c.gender == Gender.male).length;
  // الحصول على عدد حلقات البنات
  int get femaleCirclesCount => quranCircles.where((c) => c.gender == Gender.female).length;

  // ذاكرة تخزين مؤقت (Cache) لسجلات الطلاب لكل حلقة لسرعة العرض وتوفير استهلاك البيانات
  final RxMap<String, List<YearlyRecord>> cachedRecords = <String, List<YearlyRecord>>{}.obs;

  // جلب سجلات الدرجات السنوية لطلاب حلقة معينة
  Future<void> fetchRecords({String? circleId}) async {
    try {
      if (circleId != null) {
        // إذا كانت البيانات موجودة مسبقاً في الذاكرة المؤقتة، لا نطلبها من السيرفر مرة أخرى
        if (cachedRecords.containsKey(circleId)) {
          return;
        }

        isLoading.value = true; // بدء التحميل
        final records = await repository.getCircleYearlyGrades(circleId); // جلب الدرجات
        cachedRecords[circleId] = records; // تخزينها في الذاكرة المؤقتة
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_load_students'.tr); // عرض خطأ
    } finally {
      isLoading.value = false; // إنهاء التحميل
    }
  }

  // تحديث إعدادات قالب معين وتعديل مظهره
  void updateTemplate(String id, {
    String? adminTitle,
    String? title,
    int? minGrade,
    int? maxGrade,
    double? nX, double? nY,
    double? gX, double? gY,
    double? nSize, double? gSize,
    Color? nColor, Color? gColor,
    String? bgPath,
  }) {
    final index = templates.indexWhere((t) => t.id == id); // البحث عن فهرس القالب
    if (index != -1) {
      final t = templates[index]; // الوصول للكائن المطلوب تعديله
      if (adminTitle != null) t.adminTitle = adminTitle; // تحديث العنوان الإداري
      if (title != null) t.title = title; // تحديث عنوان الشهادة
      if (minGrade != null) t.minGrade = minGrade; // تحديث الحد الأدنى للدرجة
      if (maxGrade != null) t.maxGrade = maxGrade; // تحديث الحد الأقصى للدرجة
      if (nX != null) t.nameX = nX; // تحديث موقع الاسم الأفقي
      if (nY != null) t.nameY = nY; // تحديث موقع الاسم الرأسي
      if (gX != null) t.gradeX = gX; // تحديث موقع الدرجة الأفقي
      if (gY != null) t.gradeY = gY; // تحديث موقع الدرجة الرأسي
      if (nSize != null) t.nameFontSize = nSize; // تحديث حجم خط الاسم
      if (gSize != null) t.gradeFontSize = gSize; // تحديث حجم خط الدرجة
      if (nColor != null) t.nameColor = nColor; // تحديث لون اسم الطالب
      if (gColor != null) t.gradeColor = gColor; // تحديث لون الدرجة
      if (bgPath != null) t.backgroundImagePath = bgPath; // تحديث مسار صورة الخلفية
      
      templates.refresh(); // إخطار الواجهة بحدوث تغيير لتحديث العرض
      _saveTemplates(); // حفظ التعديلات في التخزين المحلي بشكل دائم
    }
  }
}
