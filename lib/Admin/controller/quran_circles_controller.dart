import 'dart:convert'; // استيراد مكتبة التحويل لـ JSON | Import JSON conversion library
// import 'package:al_maqraa/core/controllers/global_batch_controller.dart'; // استيراد متحكم الدفعات العالمي | Import global batch controller
import 'package:flutter/material.dart'; // استيراد حزمة واجهات فلاتر | Import Flutter material package
import 'package:http/http.dart'
    as http; // استيراد حزمة HTTP لطلبات الشبكة | Import HTTP package for network requests
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والتنقل | Import GetX for state management and navigation
import '../../../core/utils/app_constants.dart'; // استيراد الثوابت الخاصة بالتطبيق | Import app constants
import '../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالأدمن | Import admin data models
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة سوبابيز للتعامل مع قاعدة البيانات | Import Supabase for DB interactions
import '../repository/supabase_admin_repository.dart'; // استيراد مستودع بيانات سوبابيز للأدمن | Import Supabase admin repository
import 'accepted/accepted_students_controller.dart'; // استيراد متحكم الطلاب المقبولين | Import accepted students controller
import '../../../core/services/cache_service.dart'; // استيراد خدمة التخزين المؤقت للبيانات | Import cache service

class QuranCirclesController extends GetxController {
  // تعريف فئة متحكم حلقات القرآن | Quran Circles Controller class definition
  final SupabaseClient _supabase = Supabase
      .instance
      .client; // تهيئة عميل سوبابيز | Initialize Supabase client
  final _adminRepo =
      SupabaseAdminRepository(); // تهيئة مستودع الأدمن | Initialize admin repository
  final CacheService _cacheService =
      Get.find<
        CacheService
      >(); // الوصول لخدمة التخزين المؤقت المسجلة | Access registered cache service

  final quranCircles = <QuranCircleModel>[]
      .obs; // قائمة حلقات القرآن (مراقبة لتحديث الواجهة) | Observable list of Quran circles
  final isLoading =
      false.obs; // متغير مراقب لمتابعة حالة التحميل | Observable loading state
  var searchQuery = ''
      .obs; // نص البحث (مراقب) لتصفية الحلقات | Observable search query for filtering circles
  var selectedGenderFilter = Gender
      .all
      .obs; // فلتر الجنس المختار (ذكر/أنثى/الكل) | Selected gender filter (male/female/all)

  // الوصول للمتحكم العام للدفعات بشكل آمن | Safe access to the global batch controller

  // دالة لتحديث قائمة الطلاب المقبولين في شاشاتهم | Function to refresh students list in their screens
  void _refreshStudents() {
    if (Get.isRegistered<AcceptedStudentsController>()) {
      // التأكد من تسجيل المتحكم في الذاكرة | Check if controller is registered
      Get.find<AcceptedStudentsController>()
          .fetchAcceptedStudents(); // استدعاء جلب البيانات المحدثة | Call fetch updated data
    }
  }

  // الحصول على عدد حلقات الذكور | Get count of male circles
  int get maleCirclesCount =>
      quranCircles.where((c) => c.gender == Gender.male).length;
  // الحصول على عدد حلقات الإناث | Get count of female circles
  int get femaleCirclesCount =>
      quranCircles.where((c) => c.gender == Gender.female).length;
  // إجمالي عدد الحلقات | Total count of circles
  int get totalCirclesCount => quranCircles.length;

  // قائمة بمعرفات المعلمين المعينين حالياً | List of currently assigned teacher IDs
  List<String> get assignedTeacherIds => quranCircles
      .map(
        (c) => c.teacherId,
      ) // استخراج معرف المعلم من كل حلقة | Extract teacher ID from each circle
      .where(
        (id) => id.isNotEmpty,
      ) // استبعاد المعرفات الفارغة | Filter out empty IDs
      .toList(); // تحويل النتائج إلى قائمة | Convert results to a list

  @override
  void onInit() {
    // دالة تُستدعى عند تهيئة المتحكم | Function called on controller initialization
    super.onInit(); // استدعاء دالة التهيئة للأب | Call super class onInit
    // تحسين أداء الخيط الرئيسي: عرض الكاش فوراً (خفيف ومتزامن)
    // وتأجيل جلب الشبكة الثقيل لما بعد أول إطار عبر onReady
    _loadFromCache(); // Load cached data instantly for first frame
  }

  @override
  void onReady() {
    super.onReady();
    // تأجيل طلب الشبكة خارج بناء الواجهة لتجنب Skipped frames
    Future.microtask(() => fetchQuranCircles());
  }

  // جلب حلقات القرآن من السيرفر مع دعم التخزين المؤقت | Fetch Quran circles from server with cache support
  // يعمل بشكل آسيوي بالكامل بعيداً عن الخيط الرئيسي (لا توجد عمليات متزامنة ثقيلة)
  Future<void> fetchQuranCircles() async {
    if (quranCircles.isEmpty) {
      _loadFromCache(); // تحميل الكاش فقط إذا كانت القائمة فارغة (تم تحميلها مسبقاً في onInit)
      if (quranCircles.isEmpty) {
        isLoading.value = true; // بدء حالة التحميل فقط إذا لم يكن هناك كاش
      }
    }
    try {
      // محاولة جلب البيانات من المستودع | Try fetching data from repository
      final circles = await _adminRepo
          .getQuranCircles(); // طلب قائمة الحلقات | Request circles list
      quranCircles.value =
          circles; // تحديث القائمة المراقبة بالبيانات الجديدة | Update observable list with new data
      _saveToCache(
        circles,
      ); // حفظ البيانات الجديدة في التخزين المؤقت | Save new data to cache
    } catch (e) {
      // في حالة حدوث خطأ أثناء الجلب | In case of error during fetching
      Get.snackbar(
        'error'.tr,
        'error_fetching_circles'.tr,
      ); // إظهار رسالة خطأ للمستخدم | Show error snackbar to user
    } finally {
      // في نهاية العملية سواء نجحت أو فشلت | At the end of operation
      isLoading.value = false; // إيقاف حالة التحميل | Stop loading state
    }
  }

  // دالة تحميل البيانات من الذاكرة المحلية (الكاش) | Function to load data from local storage (cache)
  void _loadFromCache() {
    try {
      // محاولة القراءة من الكاش | Try reading from cache
      final cachedData = _cacheService.getData(
        'admin_quran_circles',
      ); // الحصول على البيانات بمفتاح معين | Get data by key
      if (cachedData != null && cachedData is List) {
        // التأكد من وجود البيانات وصحة نوعها | Ensure data exists and is a list
        quranCircles.assignAll(
          // تحويل البيانات من JSON وتعيينها للقائمة | Convert data from JSON and assign to list
          cachedData.map((e) => QuranCircleModel.fromJson(e)).toList(),
        );
      }
    } catch (e) {
      // في حالة حدوث خطأ في التحميل من الكاش | In case of error loading from cache
      Get.snackbar(
        'error'.tr,
        'error_loading_cache'.tr,
      ); // إظهار تنبيه بالخطأ | Show error snackbar
    }
  }

  // دالة حفظ القائمة الحالية في الكاش | Function to save current list to cache
  void _saveToCache(List<QuranCircleModel> circles) {
    try {
      // محاولة الحفظ في الكاش | Try saving to cache
      _cacheService.saveData(
        // حفظ البيانات بصيغة JSON | Save data in JSON format
        'admin_quran_circles',
        circles.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      // في حالة حدوث خطأ في الحفظ | In case of error saving
      Get.snackbar(
        'error'.tr,
        'error_saving_cache'.tr,
      ); // إظهار تنبيه بالخطأ | Show error snackbar
    }
  }

  // دالة لتحديث البيانات يدوياً | Function to manually refresh data
  Future<void> refreshData() async {
    await fetchQuranCircles(); // إعادة جلب حلقات القرآن | Re-fetch Quran circles
  }

  // دالة إضافة حلقة قرآن جديدة | Function to add a new Quran circle
  Future<void> addQuranCircle({
    required String name, // اسم الحلقة الجديدة | New circle name
    required List<TeacherModel>
    teachers, // المعلمون المراد تعيينهم | Teachers to assign
    required List<StudentModel>
    students, // الطلاب المراد إضافتهم | Students to add
    required int batchNumber, // رقم الدفعة الإلزامي | Required batch number
  }) async {
    isLoading.value = true; // بدء عملية التحميل | Start loading process
    try {
      // محاولة إضافة الحلقة | Try adding the circle
      final user = _supabase
          .auth
          .currentUser; // الحصول على بيانات المستخدم الحالي | Get current user data
      if (user == null) {
        // إذا لم يكن هناك مستخدم مسجل دخول | If no user is logged in
        Get.snackbar(
          'error'.tr,
          'user_not_logged_in'.tr,
        ); // إظهار تنبيه بضرورة تسجيل الدخول | Show login required snackbar
        return; // الخروج من الدالة | Exit function
      }

      final circleResponse =
          await _supabase // إرسال طلب إنشاء الحلقة لسوبابيز | Send circle creation request to Supabase
              .from('circles')
              .insert({
                'name': name, // اسم الحلقة | Circle name
                'teacher_id': teachers.isNotEmpty
                    ? teachers.first.id
                    : null, // معرف المعلم الأول إن وجد | First teacher ID if exists
                'created_by':
                    user.id, // معرف المنشئ (الأدمن) | Creator ID (Admin)
                'batch_number':
                    batchNumber, // رقم الدفعة الإلزامي | Required batch number
              })
              .select() // اختيار البيانات المدرجة لاسترجاع المعرف | Select inserted data to retrieve ID
              .single(); // توقع سجل واحد فقط | Expect a single record

      final String circleId = circleResponse['id']
          .toString(); // استخراج معرف الحلقة الجديد | Extract new circle ID

      if (students.isNotEmpty) {
        // إذا كانت قائمة الطلاب غير فارغة | If students list is not empty
        final members =
            students // تجهيز بيانات الأعضاء للإدراج | Prepare member data for insertion
                .map((s) => {'circle_id': circleId, 'student_id': s.id})
                .toList();

        await _supabase
            .from('circle_members')
            .insert(
              members,
            ); // إدراج الطلاب في جدول أعضاء الحلقات | Insert students into members table

        await _adminRepo.setStudentsDistributed(
          // تحديث حالة الطلاب كموزعين على حلقات | Update students status as distributed
          students.map((s) => s.id).toList(),
          true,
        );
      }

      await fetchQuranCircles(); // تحديث قائمة الحلقات في الواجهة | Update circles list in UI
      _refreshStudents(); // تحديث بيانات الطلاب في شاشاتهم | Refresh students data in their screens
      Get.back(); // العودة للشاشة السابقة | Go back to previous screen
      Get.snackbar(
        'success'.tr,
        'circle_added_success'.tr,
      ); // إظهار رسالة نجاح الإضافة | Show success snackbar
    } catch (e) {
      // في حالة الفشل | In case of failure
      Get.snackbar(
        'error'.tr,
        '${'failed_add_circle'.tr}: $e',
      ); // إظهار رسالة الخطأ | Show error message
    } finally {
      // النهاية | Finally
      isLoading.value = false; // إيقاف حالة التحميل | Stop loading state
    }
  }

  // دالة لحذف حلقة قرآن | Function to delete a Quran circle
  Future<void> deleteCircle(String id) async {
    try {
      // محاولة الحذف | Try deleting
      final circle = quranCircles.firstWhereOrNull(
        (c) => c.id == id,
      ); // العثور على بيانات الحلقة قبل الحذف | Find circle data before deletion
      if (circle != null && circle.studentIds.isNotEmpty) {
        // إذا كانت الحلقة تحتوي على طلاب | If circle has students
        await _adminRepo.setStudentsDistributed(
          circle.studentIds,
          false,
        ); // إعادة تعيين الطلاب كغير موزعين | Reset students status as not distributed
      }

      await _supabase
          .from('circles')
          .delete()
          .eq(
            'id',
            id,
          ); // حذف سجل الحلقة من قاعدة البيانات | Delete circle record from DB

      quranCircles.removeWhere(
        (c) => c.id == id,
      ); // إزالة الحلقة من القائمة المحلية | Remove circle from local list
      _refreshStudents(); // تحديث قائمة الطلاب | Refresh students list
      Get.snackbar(
        'success'.tr,
        'circle_deleted_success'.tr,
      ); // رسالة نجاح الحذف | Deletion success snackbar
    } catch (e) {
      // في حالة الفشل | In case of failure
      Get.snackbar(
        'error'.tr,
        '${'failed_delete_circle'.tr}: $e',
      ); // رسالة فشل الحذف | Deletion failure snackbar
    }
  }

  // دالة لتحديث بيانات حلقة موجودة | Function to update existing circle data
  Future<void> updateQuranCircle({
    required String
    circleId, // معرف الحلقة المطلوب تعديلها | ID of circle to modify
    required String name, // الاسم الجديد | New name
    required List<TeacherModel>
    teachers, // قائمة المعلمين المحدثة | Updated teachers list
    required List<StudentModel>
    students, // قائمة الطلاب المحدثة | Updated students list
    required int batchNumber, // رقم الدفعة المحدث | Updated batch number
  }) async {
    isLoading.value = true; // بدء التحميل | Start loading
    try {
      // محاولة التحديث | Try updating
      final oldCircle = quranCircles.firstWhereOrNull(
        (c) => c.id == circleId,
      ); // جلب بيانات الحلقة السابقة | Get previous circle data
      final oldStudentIds =
          oldCircle?.studentIds ??
          []; // معرفات الطلاب القدامى | Old student IDs
      final newStudentIds = students
          .map((s) => s.id)
          .toList(); // معرفات الطلاب الجدد | New student IDs

      final removedStudentIds =
          oldStudentIds // استخراج الطلاب الذين تم استبعادهم | Find students who were removed
              .where((id) => !newStudentIds.contains(id))
              .toList();

      final addedStudentIds =
          newStudentIds // استخراج الطلاب الذين تم إضافتهم حديثاً | Find students who were newly added
              .where((id) => !oldStudentIds.contains(id))
              .toList();

      await _supabase // تحديث بيانات الحلقة الأساسية في سوبابيز | Update basic circle data in Supabase
          .from('circles')
          .update({
            'name': name,
            'teacher_id': teachers.isNotEmpty ? teachers.first.id : null,
            'batch_number': batchNumber,
          })
          .eq('id', circleId);

      await _supabase
          .from('circle_members')
          .delete()
          .eq(
            'circle_id',
            circleId,
          ); // مسح جميع أعضاء الحلقة القدامى | Clear all old circle members

      if (students.isNotEmpty) {
        // إضافة قائمة الأعضاء المحدثة | Add updated members list
        final members = students
            .map((s) => {'circle_id': circleId, 'student_id': s.id})
            .toList();

        await _supabase.from('circle_members').insert(members);
      }

      if (removedStudentIds.isNotEmpty) {
        // تحديث حالة الطلاب المزالين كغير موزعين | Update removed students status as not distributed
        await _adminRepo.setStudentsDistributed(removedStudentIds, false);
      }
      if (addedStudentIds.isNotEmpty) {
        // تحديث حالة الطلاب الجدد كموزعين | Update new students status as distributed
        await _adminRepo.setStudentsDistributed(addedStudentIds, true);
      }

      await fetchQuranCircles(); // تحديث قائمة الحلقات | Update circles list
      _refreshStudents(); // تحديث شاشة الطلاب | Refresh students screen
      Get.back(); // العودة للخلف | Go back
      Get.snackbar(
        'success'.tr,
        'circle_updated_success'.tr,
      ); // رسالة نجاح التعديل | Update success snackbar
    } catch (e) {
      // في حالة الفشل | In case of failure
      Get.snackbar(
        'error'.tr,
        '${'failed_update_circle'.tr}: $e',
      ); // رسالة فشل التعديل | Update failure snackbar
    } finally {
      // النهاية | Finally
      isLoading.value = false; // إيقاف التحميل | Stop loading
    }
  }

  // دالة لتعيين مختبر لحلقة معينة عبر خادم جانغو | Function to assign an examiner to a circle via Django server
  Future<void> assignExaminer(String circleId, String? examinerId) async {
    isLoading.value = true; // بدء التحميل | Start loading
    try {
      // محاولة التعيين | Try assignment
      final String djangoBaseUrl = AppConstants
          .djangoApiBaseUrl; // الحصول على رابط الخادم من الثوابت | Get server URL from constants
      final String endpoint =
          examinerId ==
              null // تحديد المسار (تعيين أو إزالة) | Define endpoint (assign or remove)
          ? "remove_examiner/$circleId"
          : "assign_examiner/$circleId/$examinerId";

      final url = Uri.parse(
        "$djangoBaseUrl/management/$endpoint/?format=json",
      ); // تجهيز الرابط الكامل للطلب | Prepare full request URL

      final response = await http.post(
        // إرسال طلب POST للخادم | Send POST request to server
        url,
        headers: {
          'Accept':
              'application/json', // تحديد نوع البيانات المقبولة | Specify accepted data type
          'X-API-KEY':
              AppConstants.djangoApiKey, // إرسال مفتاح الأمان | Send API key
        },
      );

      final data = json.decode(
        response.body,
      ); // فك تشفير استجابة الخادم | Decode server response

      if (response.statusCode == 200) {
        // في حالة نجاح الطلب من جهة الخادم | If request was successful from server side
        Get.snackbar(
          // إظهار رسالة النجاح للمستخدم | Show success snackbar to user
          'success'.tr,
          data['message'] ??
              (examinerId == null
                  ? 'examiner_removed_success'.tr
                  : 'examiner_assigned_success'.tr),
          backgroundColor: Colors.green.withValues(
            // لون خلفية أخضر للنجاح | Green background for success
            alpha: 0.8,
          ),
          colorText: Colors.white, // لون النص أبيض | White text color
        );
        await fetchQuranCircles(); // تحديث البيانات محلياً | Update data locally
      } else {
        // في حالة وجود خطأ في الطلب من الخادم | If there's a server request error
        Get.snackbar(
          'error'.tr,
          data['message'] ?? 'process_failed'.tr,
          backgroundColor: Colors.red.withValues(
            alpha: 0.8,
          ), // لون أحمر للخطأ | Red background for error
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // في حالة حدوث خطأ برمجي أو في الاتصال | In case of coding or connection error
      Get.snackbar(
        'error'.tr,
        '${'error_during_assignment'.tr}: $e',
      ); // إظهار الخطأ | Show error
    } finally {
      // النهاية | Finally
      isLoading.value = false; // إيقاف التحميل | Stop loading
    }
  }
}
