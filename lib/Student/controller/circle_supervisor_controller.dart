import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Admin/models/admin_models.dart';
import '../../Student/models/student_models.dart';
import '../../core/services/cache_service.dart';

/// متحكم خاص بالطالب المشرف لمتابعة زملاء حلقته ومراجعة إنجازاتهم
class CircleSupervisorController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final CacheService _cacheService = Get.find<CacheService>();
  final GetStorage _storage = GetStorage();

  final students = <StudentModel>[].obs;
  final filteredStudents = <StudentModel>[].obs;
  final isLoading = false.obs;
  final isSupervisor = false.obs;
  final circleName = ''.obs;
  final circleId = ''.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkSupervisorStatusAndLoad();
  }

  /// التحقق من صلاحية الإشراف وجلب بيانات الحلقة
  Future<void> checkSupervisorStatusAndLoad() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    isLoading.value = true;
    try {
      // 1. جلب حلقة الطالب
      final circleMemberRes = await supabase
          .from('circle_members')
          .select('circle_id, circles(id, name, supervisor_id)')
          .eq('student_id', currentUserId)
          .maybeSingle();

      if (circleMemberRes != null && circleMemberRes['circles'] != null) {
        final circle = circleMemberRes['circles'];
        circleId.value = circle['id']?.toString() ?? '';
        circleName.value = circle['name']?.toString() ?? '';
        final supervisorId = circle['supervisor_id']?.toString() ??
            _storage.read('circle_supervisor_${circleId.value}');

        final hasLocalSup = _storage.read('is_supervisor_$currentUserId') == true;
        isSupervisor.value = (supervisorId == currentUserId) || hasLocalSup;
      } else {
        final hasLocalSup = _storage.read('is_supervisor_$currentUserId') == true;
        isSupervisor.value = hasLocalSup;
      }

      if (isSupervisor.value) {
        await fetchCircleStudents();
      }
    } catch (e) {
      // debugPrint('Error checking supervisor status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب طلاب الحلقة الحالية فقط
  Future<void> fetchCircleStudents() async {
    if (circleId.value.isEmpty) return;

    try {
      final currentUserId = supabase.auth.currentUser?.id;
      final cacheKey = 'circle_students_supervisor_${circleId.value}';

      final result = await _cacheService.fetchWithCache(
        cacheKey: cacheKey,
        onData: (serverData) {
          if (serverData != null && serverData is List) {
            final list = serverData.map((data) {
              final Map<String, dynamic> dataMap = Map<String, dynamic>.from(data as Map);
              final Map<String, dynamic> studentData = dataMap['students'] != null
                  ? Map<String, dynamic>.from(dataMap['students'] as Map)
                  : {};
              final combinedData = {
                ...dataMap,
                ...studentData,
                'circle_name': circleName.value,
                'circle_id': circleId.value,
              };
              return StudentModel.fromJson(combinedData);
            }).toList();
            students.assignAll(list);
            applyFilter();
          }
        },
        fetchFromServer: () async {
          // جلب أعضاء الحلقة
          final membersResponse = await supabase
              .from('circle_members')
              .select('student_id')
              .eq('circle_id', circleId.value);

          if (membersResponse.isEmpty) return [];

          final studentIds = (membersResponse as List)
              .map((m) => m['student_id'].toString())
              .where((id) => id != currentUserId) // استثناء الطالب المشرف نفسه من القائمة
              .toList();

          if (studentIds.isEmpty) return [];

          return await supabase
              .from('profiles')
              .select('*, students(*)').filter('id', 'in', studentIds);
        },
      );

      if (result != null && result is List) {
        final currentUserId = supabase.auth.currentUser?.id;
        final list = result
            .map((data) {
              final Map<String, dynamic> dataMap = Map<String, dynamic>.from(data as Map);
              final Map<String, dynamic> studentData = dataMap['students'] != null
                  ? Map<String, dynamic>.from(dataMap['students'] as Map)
                  : {};
              final combinedData = {
                ...dataMap,
                ...studentData,
                'circle_name': circleName.value,
                'circle_id': circleId.value,
              };
              return StudentModel.fromJson(combinedData);
            })
            .where((s) => s.id != currentUserId)
            .toList();

        students.assignAll(list);
        applyFilter();
      }
    } catch (e) {
      // debugPrint('Error fetching circle students: $e');
    }
  }

  void search(String query) {
    searchQuery.value = query;
    applyFilter();
  }

  void applyFilter() {
    if (searchQuery.value.trim().isEmpty) {
      filteredStudents.assignAll(students);
    } else {
      final q = searchQuery.value.toLowerCase().trim();
      filteredStudents.assignAll(
        students.where((s) => s.name.toLowerCase().contains(q) || s.level.toLowerCase().contains(q)),
      );
    }
  }

  /// تحديث واعتماد/رفض إنجاز الطالب
  Future<bool> updateStudentDailyRecord({
    required DailyRecordModel record,
    required String status,
    required String notes,
  }) async {
    try {
      await supabase
          .from('daily_records')
          .update({
            'status': status,
            'notes': notes,
          })
          .eq('id', record.id);

      await _cacheService.removeData('student_details_full_${record.studentId}');
      return true;
    } catch (e) {
      // debugPrint('Error updating daily record: $e');
      return false;
    }
  }
}
