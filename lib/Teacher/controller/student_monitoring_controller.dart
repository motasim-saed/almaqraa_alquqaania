import 'dart:async';
import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال للواجهات والسمات
import 'package:get/get.dart'; // استيراد GetX لإدارة الحالة والترجمة
import 'package:get_storage/get_storage.dart';
import '../../Admin/repository/admin_repository.dart'; // واجهة مستودع الإدارة
import '../../Admin/repository/supabase_admin_repository.dart'; // تطبيق مستودع سوبابيس
import '../../Admin/models/admin_models.dart'; // نماذج الخطط السنوية والشهرية
import '../../Student/models/student_models.dart'; // نموذج بيانات الطالب والسجلات اليومية
import 'package:supabase_flutter/supabase_flutter.dart'; // حزمة التعامل مع قاعدة بيانات سوبابيس
import '../../core/services/cache_service.dart'; // خدمة التخزين المحلي (الكاش)
import '../../core/services/connectivity_service.dart';

/// متحكم مراقبة الطلاب: مسؤول عن جلب بيانات الطلاب وخططهم وسجلاتهم اليومية للمعلم
class StudentMonitoringController extends GetxController { // تعريف الفئة كمتحكم GetX
  final AdminRepository _repository = SupabaseAdminRepository(); // كائن الوصول للبيانات من المستودع
  final CacheService _cacheService = Get.find<CacheService>(); // كائن خدمة الكاش المسجلة في التطبيق
  final GetStorage _storage = GetStorage();

  var students = <StudentModel>[].obs; // قائمة الطلاب المراقبة (تحدث الواجهة تلقائياً)
  var isLoading = false.obs; // متغير لمراقبة حالة تحميل قائمة الطلاب الرئيسية

  var selectedStudentAnnualPlans = <AnnualPlanModel>[].obs; // قائمة الخطط السنوية للطالب المختار
  var selectedStudentMonthlyPlans = <MonthlyPlanModel>[].obs; // قائمة الخطط الشهرية للطالب المختار
  var selectedStudentDailyRecords = <DailyRecordModel>[].obs; // قائمة السجلات اليومية (التخزين المحلي للسجلات)
  var isDetailLoading = false.obs; // متغير لمراقبة حالة تحميل تفاصيل الطالب
  var isUpdatingRecord = false.obs; // متغير لمراقبة عملية تحديث السجلات ومنع التكرار

  StreamSubscription? _connectivitySub;

  @override // إعادة تعريف دالة البدء
  void onInit() { // تُستدعى عند بدء عمل المتحكم
    super.onInit(); // استدعاء دالة البدء للأب
    fetchStudents(); // البدء بجلب قائمة الطلاب المنضمين للمعلم
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    if (Get.isRegistered<ConnectivityService>()) {
      _connectivitySub = Get.find<ConnectivityService>().isConnected.listen((connected) {
        if (connected) {
          _syncPendingSupervisorUpdates();
          fetchStudents();
        }
      });
    }
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }

  Future<void> _syncPendingSupervisorUpdates() async {
    try {
      final keys = _storage.getKeys();
      for (var key in keys) {
        if (key.toString().startsWith('pending_supervisor_')) {
          final circleId = key.toString().replaceFirst('pending_supervisor_', '');
          final targetStudentId = _storage.read(key)?.toString();
          if (targetStudentId != null && targetStudentId.isNotEmpty) {
            await Supabase.instance.client
                .from('circles')
                .update({'supervisor_id': targetStudentId})
                .eq('id', circleId);
          } else {
            await Supabase.instance.client
                .from('circles')
                .update({'supervisor_id': null})
                .eq('id', circleId);
          }
          _storage.remove(key);
        }
      }
    } catch (_) {}
  }

  /// جلب قائمة الطلاب التابعين للمعلم الحالي مع نظام الكاش وتصحيح معالجة الأخطاء والتحديث الصامت
  Future<void> fetchStudents() async { // دالة غير متزامنة لجلب الطلاب
    if (students.isEmpty) {
      isLoading.value = true; // تفعيل مؤشر التحميل فقط إذا لم تكن هناك بيانات محلية
    }
    try { // محاولة تنفيذ العملية
      final currentTeacherId = Supabase.instance.client.auth.currentUser?.id; // الحصول على معرف المعلم الحالي
      if (currentTeacherId == null) return; // الخروج في حال عدم وجود مستخدم مسجل

      final result = await _cacheService.fetchWithCache( // استخدام خدمة الكاش لجلب البيانات
        cacheKey: 'teacher_students_monitoring_$currentTeacherId', // مفتاح فريد لتخزين قائمة طلاب المعلم
        onData: (serverData) {
          // التحديث الشفاف عند وصول البيانات الجديدة من السيرفر
          if (serverData != null && serverData is List) {
            students.value = serverData.map((data) {
              final Map<String, dynamic> dataMap = Map<String, dynamic>.from(data as Map); 
              final Map<String, dynamic> studentData = dataMap['students'] != null ? Map<String, dynamic>.from(dataMap['students'] as Map) : {}; 
              final sId = dataMap['id'].toString();
              final cId = dataMap['circle_id']?.toString();
              final isSup = dataMap['is_supervisor'] == true || _storage.read('is_supervisor_$sId') == true;
              final combinedData = {
                ...dataMap,
                ...studentData,
                'status': 'accepted',
                'is_supervisor': isSup,
                'circle_id': cId,
              }; 
              return StudentModel.fromJson(combinedData); 
            }).toList();
          }
        },
        fetchFromServer: () async { // وظيفة جلب البيانات من السيرفر في حال عدم وجود كاش
          // مزامنة أي تعديل معلق أولاً
          await _syncPendingSupervisorUpdates();

          // جلب الحلقات المرتبطة بالمعلم مع معرف المشرف
          final List<dynamic> circlesResponse = await Supabase.instance.client
              .from('circles')
              .select('id, name, supervisor_id')
              .eq('teacher_id', currentTeacherId); 
          if (circlesResponse.isEmpty) return []; // التحقق من وجود حلقات
          
          final List<String> circleIds = circlesResponse.map((row) => row['id'].toString()).toList(); // تحويل النتائج لقائمة معرفات نصوص

          Map<String, String> circleNames = {};
          Map<String, String?> circleSupervisors = {};
          for (var c in circlesResponse) {
            final cid = c['id'].toString();
            circleNames[cid] = c['name']?.toString() ?? '';
            circleSupervisors[cid] = c['supervisor_id']?.toString() ?? _storage.read('circle_supervisor_$cid');
          }

          // جلب الطلاب المنضمين لهذه الحلقات
          final List<dynamic> membersResponse = await Supabase.instance.client
              .from('circle_members')
              .select('student_id, circle_id')
              .filter('circle_id', 'in', circleIds); 
          if (membersResponse.isEmpty) return []; // التحقق من وجود أعضاء
          
          Map<String, String> studentCircleMap = {};
          final List<String> studentIds = [];
          for (var row in membersResponse) {
            final sid = row['student_id'].toString();
            final cid = row['circle_id'].toString();
            studentIds.add(sid);
            studentCircleMap[sid] = cid;
          }

          if (studentIds.isEmpty) return []; // التأكد من أن القائمة ليست فارغة
          // جلب الملفات الشخصية للطلاب
          final profilesResponse = await Supabase.instance.client.from('profiles').select('*, students(*)').filter('id', 'in', studentIds); 
          
          return (profilesResponse as List).map((row) {
            final dataMap = Map<String, dynamic>.from(row as Map);
            final sid = dataMap['id'].toString();
            final cid = studentCircleMap[sid];
            final supervisorId = cid != null ? circleSupervisors[cid] : null;
            final isSup = (supervisorId != null && supervisorId == sid) || _storage.read('is_supervisor_$sid') == true;

            dataMap['circle_id'] = cid;
            dataMap['circle_name'] = cid != null ? circleNames[cid] : null;
            dataMap['is_supervisor'] = isSup;
            return dataMap;
          }).toList();
        },
      );

      // تحميل بيانات الكاش الفوري
      if (result != null && result is List) { // التحقق من نجاح جلب البيانات
        students.value = result.map((data) { // تحويل البيانات الخام إلى نماذج StudentModel
          final Map<String, dynamic> dataMap = Map<String, dynamic>.from(data as Map); 
          final Map<String, dynamic> studentData = dataMap['students'] != null ? Map<String, dynamic>.from(dataMap['students'] as Map) : {}; 
          final sId = dataMap['id'].toString();
          final cId = dataMap['circle_id']?.toString();
          final isSup = dataMap['is_supervisor'] == true || _storage.read('is_supervisor_$sId') == true;
          final combinedData = {
            ...dataMap,
            ...studentData,
            'status': 'accepted',
            'is_supervisor': isSup,
            'circle_id': cId,
          }; 
          return StudentModel.fromJson(combinedData); 
        }).toList(); 
      }
    } catch (e) { // التعامل مع الأخطاء المفاجئة
      Get.snackbar('error'.tr, 'network_error'.tr, backgroundColor: Colors.redAccent, colorText: Colors.white); 
    } finally { 
      isLoading.value = false; // إيقاف مؤشر التحميل
    }
  }

  /// تعيين أو إلغاء تعيين الطالب كمشرف للحلقة
  Future<void> toggleCircleSupervisor(StudentModel student) async {
    final circleId = student.circleId;
    final newStatus = !student.isSupervisor;

    try {
      if (newStatus) {
        // تعيين الطالب كمشرف للحلقة
        if (circleId != null && circleId.isNotEmpty) {
          try {
            await Supabase.instance.client
                .from('circles')
                .update({'supervisor_id': student.id})
                .eq('id', circleId);
            _storage.remove('pending_supervisor_$circleId');
          } catch (e) {
            _storage.write('pending_supervisor_$circleId', student.id);
          }
          _storage.write('circle_supervisor_$circleId', student.id);
        }
        _storage.write('is_supervisor_${student.id}', true);

        // تحديث القائمة محلياً فوراً
        students.value = students.map((s) {
          if (s.circleId != null && s.circleId == circleId) {
            return s.copyWith(isSupervisor: s.id == student.id);
          } else if (s.id == student.id) {
            return s.copyWith(isSupervisor: true);
          }
          return s;
        }).toList();

        final currentTeacherId = Supabase.instance.client.auth.currentUser?.id;
        if (currentTeacherId != null) {
          _cacheService.removeData('teacher_students_monitoring_$currentTeacherId');
        }

        Get.snackbar(
          'نجاح',
          'تم تعيين الطالب ${student.name} مشرفاً على الحلقة بنجاح ⭐',
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // سحب صلاحية الإشراف
        if (circleId != null && circleId.isNotEmpty) {
          try {
            await Supabase.instance.client
                .from('circles')
                .update({'supervisor_id': null})
                .eq('id', circleId);
            _storage.remove('pending_supervisor_$circleId');
          } catch (e) {
            _storage.write('pending_supervisor_$circleId', '');
          }
          _storage.remove('circle_supervisor_$circleId');
        }
        _storage.remove('is_supervisor_${student.id}');

        // تحديث القائمة محلياً فوراً
        students.value = students.map((s) {
          if (s.id == student.id) {
            return s.copyWith(isSupervisor: false);
          }
          return s;
        }).toList();

        final currentTeacherId = Supabase.instance.client.auth.currentUser?.id;
        if (currentTeacherId != null) {
          _cacheService.removeData('teacher_students_monitoring_$currentTeacherId');
        }

        Get.snackbar(
          'تنبيه',
          'تم سحب صلاحية الإشراف من الطالب ${student.name}',
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'تعذر تحديث صلاحية الإشراف: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// جلب تفاصيل الطالب مع تخزين محلي كامل وتحديث صامت للواجهة
  Future<void> fetchStudentDetails(String studentId) async { 
    if (selectedStudentDailyRecords.isEmpty) {
      isDetailLoading.value = true; 
    }
    try { 
      final cacheKey = 'student_details_full_$studentId'; 
      final result = await _cacheService.fetchWithCache( 
        cacheKey: cacheKey, 
        onData: (serverData) {
          // التحديث الشابكات من السيرفر بصمت للواجهة
          if (serverData != null) {
            selectedStudentAnnualPlans.value = (serverData['annual'] as List).map((e) => AnnualPlanModel.fromJson(e)).toList(); 
            selectedStudentMonthlyPlans.value = (serverData['monthly'] as List).map((e) => MonthlyPlanModel.fromJson(e)).toList(); 
            selectedStudentDailyRecords.value = (serverData['daily'] as List).map((e) => DailyRecordModel.fromJson(e)).toList(); 
          }
        },
        fetchFromServer: () async { 
          final plans = await _repository.getStudentAnnualPlans(studentId); 
          final monthly = await _repository.getStudentMonthlyPlans(studentId); 
          final daily = await _repository.getStudentDailyRecords(studentId); 
          
          return { 
            'annual': plans.map((e) => e.toJson()).toList(), 
            'monthly': monthly.map((e) => e.toJson()).toList(), 
            'daily': daily.map((e) => e.toJson()).toList(), 
          };
        },
      );

      // تحميل بيانات الكاش الفوري
      if (result != null) { 
        selectedStudentAnnualPlans.value = (result['annual'] as List).map((e) => AnnualPlanModel.fromJson(e)).toList(); 
        selectedStudentMonthlyPlans.value = (result['monthly'] as List).map((e) => MonthlyPlanModel.fromJson(e)).toList(); 
        selectedStudentDailyRecords.value = (result['daily'] as List).map((e) => DailyRecordModel.fromJson(e)).toList(); 
      }
    } catch (e) { 
      Get.snackbar('error'.tr, 'failed_to_load_profile'.tr, backgroundColor: Colors.redAccent, colorText: Colors.white); 
    } finally { 
      isDetailLoading.value = false; 
    }
  }

  /// تحديث السجل اليومي: تم تحسينه ليغلق الحوار فوراً ويحدث الواجهة لحظياً (Instant UI Feedback)
  Future<void> updateDailyRecord(DailyRecordModel record, String notes, String status) async { 
    if (isUpdatingRecord.value) return; // منع النقرات المتكررة
    
    isUpdatingRecord.value = true; 
    
    // 1. إغلاق الحوار فوراً ليشعر المعلم بالسرعة
    if (Get.isDialogOpen ?? false) Get.back();

    // 2. تحديث السجل في القائمة المحلية فوراً (قبل السيرفر) لتحديث الواجهة لحظياً
    final index = selectedStudentDailyRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      // تحديث البيانات محلياً في القائمة المراقبة
      selectedStudentDailyRecords[index] = record.copyWith(teacherNotes: notes, status: status);
      selectedStudentDailyRecords.refresh(); // إجبار الواجهة على إعادة بناء هذا العنصر
    }

    try { 
      // 3. التنفيذ في قاعدة البيانات (في الخلفية)
      await Supabase.instance.client.from('daily_records').update({'notes': notes, 'status': status}).eq('id', record.id); 
      
      // 4. مسح الكاش المحلي لضمان جلب البيانات الصحيحة مستقبلاً
      await _cacheService.removeData('student_details_full_${record.studentId}'); 
      
      Get.snackbar('success'.tr, 'saved_successfully'.tr, backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM); 
    } catch (e) { 
      // في حال الفشل، عرض رسالة خطأ (ويمكن اختيارياً إعادة البيانات القديمة هنا)
      Get.snackbar('error'.tr, 'error_saving_data'.tr, backgroundColor: Colors.redAccent, colorText: Colors.white); 
    } finally {
      isUpdatingRecord.value = false; 
    }
  }

  /// حذف خطة سنوية للطالب مع مسح الكاش
  Future<void> deleteAnnualPlan(String studentId, String planId) async { 
    try { 
      await _repository.deleteAnnualPlan(planId); 
      await _cacheService.removeData('student_details_full_$studentId'); 
      await fetchStudentDetails(studentId); 
      Get.snackbar('success'.tr, 'plan_deleted_success'.tr, backgroundColor: Colors.green, colorText: Colors.white); 
    } catch (e) { 
      Get.snackbar('error'.tr, 'delete_failed'.tr, backgroundColor: Colors.redAccent, colorText: Colors.white); 
    }
  }

  /// حذف خطة شهرية للطالب مع مسح الكاش
  Future<void> deleteMonthlyPlan(String studentId, String planId) async { 
    try { 
      await _repository.deleteMonthlyPlan(planId); 
      await _cacheService.removeData('student_details_full_$studentId'); 
      await fetchStudentDetails(studentId); 
      Get.snackbar('success'.tr, 'plan_deleted_success'.tr, backgroundColor: Colors.green, colorText: Colors.white); 
    } catch (e) { 
      Get.snackbar('error'.tr, 'delete_failed'.tr, backgroundColor: Colors.redAccent, colorText: Colors.white); 
    }
  }
}
