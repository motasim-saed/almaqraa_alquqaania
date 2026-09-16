import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../models/admin_models.dart';
import '../../repository/admin_repository.dart';
import '../../repository/supabase_admin_repository.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/controllers/global_batch_controller.dart';

class ApplicantsController extends GetxController {
  final AdminRepository _repository = SupabaseAdminRepository();
  final CacheService _cacheService = Get.find<CacheService>();
  final String djangoBaseUrl = AppConstants.djangoApiBaseUrl;

  var teacherApplicants = <TeacherModel>[].obs;
  var studentApplicants = <StudentModel>[].obs;
  var isLoading = false.obs;
  var isRefreshing = false.obs; // تمت إضافة هذا المتغير لدعم أيقونة التحديث في شاشة الويندوز
  var isProcessing = false.obs;
  var searchQuery = "".obs;

  @override
  void onInit() {
    super.onInit();
    fetchApplicants();
  }

  // دالة التحديث التي يتم استدعاؤها من خلال F5 أو زر التحديث
  Future<void> refreshData() async {
    isRefreshing.value = true;
    try {
      await fetchApplicants();
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> fetchApplicants() async {
    _loadFromCache(); // تحميل الكاش فوراً
    if (teacherApplicants.isEmpty && studentApplicants.isEmpty) {
      isLoading.value = true;
    }
    try {
      final teachers = await _repository.getTeachers(status: 'pending');
      final students = await _repository.getStudents(status: 'pending');
      teacherApplicants.assignAll(teachers);
      studentApplicants.assignAll(students);
      _saveToCache(); // حفظ البيانات الجديدة في الكاش
    } catch (e) {
      print("Error fetching applicants: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _loadFromCache() {
    final cachedTeachers = _cacheService.getData('teacher_applicants');
    final cachedStudents = _cacheService.getData('student_applicants');
    if (cachedTeachers != null) {
      teacherApplicants.assignAll(
        (cachedTeachers as List).map((e) => TeacherModel.fromJson(e)).toList(),
      );
    }
    if (cachedStudents != null) {
      studentApplicants.assignAll(
        (cachedStudents as List).map((e) => StudentModel.fromJson(e)).toList(),
      );
    }
  }

  void _saveToCache() {
    _cacheService.saveData(
      'teacher_applicants',
      teacherApplicants.map((e) => e.toJson()).toList(),
    );
    _cacheService.saveData(
      'student_applicants',
      studentApplicants.map((e) => e.toJson()).toList(),
    );
  }

  Future<bool> approveApplicant(String id) async {
    isProcessing.value = true;
    try {
      final url = Uri.parse(
        "$djangoBaseUrl/management/approve/$id/?format=json",
      );
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'X-API-KEY': AppConstants.djangoApiKey,
        },
      );

      if (response.statusCode == 200) {
        _showMessage('applicant_approved_success'.tr, true);
        fetchApplicants();
        return true;
      } else {
        _showMessage('approval_failed'.tr, false);
        return false;
      }
    } catch (e) {
      _showMessage('django_connection_error'.tr, false);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> rejectApplicant(String id, String reason) async {
    isProcessing.value = true;
    try {
      final url = Uri.parse(
        "$djangoBaseUrl/management/reject/$id/?format=json",
      );
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-API-KEY': AppConstants.djangoApiKey,
        },
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        _showMessage('applicant_rejected_success'.tr, true);
        fetchApplicants();
        return true;
      } else {
        _showMessage('rejection_failed'.tr, false);
        return false;
      }
    } catch (e) {
      _showMessage('django_connection_error'.tr, false);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  void _showMessage(String message, bool isSuccess) {
    Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (Get.isDialogOpen!) Get.back(); // إغلاق الرسالة
      if (isSuccess) {
        if (Get.isDialogOpen!) Get.back(); // إغلاق نافذة التفاصيل
      }
    });
  }

  int get teacherMaleCount {
    int? batch = Get.isRegistered<GlobalBatchController>() ? Get.find<GlobalBatchController>().selectedBatch.value : null;
    return teacherApplicants.where((t) => t.gender == Gender.male && (batch == null || t.batchNumber == batch)).length;
  }

  int get teacherFemaleCount {
    int? batch = Get.isRegistered<GlobalBatchController>() ? Get.find<GlobalBatchController>().selectedBatch.value : null;
    return teacherApplicants.where((t) => t.gender == Gender.female && (batch == null || t.batchNumber == batch)).length;
  }

  int get studentMaleCount {
    int? batch = Get.isRegistered<GlobalBatchController>() ? Get.find<GlobalBatchController>().selectedBatch.value : null;
    return studentApplicants.where((s) => s.gender == Gender.male && (batch == null || s.batchNumber == batch)).length;
  }

  int get studentFemaleCount {
    int? batch = Get.isRegistered<GlobalBatchController>() ? Get.find<GlobalBatchController>().selectedBatch.value : null;
    return studentApplicants.where((s) => s.gender == Gender.female && (batch == null || s.batchNumber == batch)).length;
  }

  List<TeacherModel> filteredTeacherApplicants(Gender gender) {
    int? batch = Get.isRegistered<GlobalBatchController>() ? Get.find<GlobalBatchController>().selectedBatch.value : null;
    return teacherApplicants.where((t) {
      bool genderMatch = t.gender == gender;
      bool batchMatch = batch == null || t.batchNumber == batch;
      bool searchMatch = searchQuery.value.isEmpty || t.name.toLowerCase().contains(searchQuery.value.toLowerCase()) || t.academicNumber.toLowerCase().contains(searchQuery.value.toLowerCase());
      return genderMatch && batchMatch && searchMatch;
    }).toList();
  }

  List<StudentModel> filteredStudentApplicants(Gender gender) {
    int? batch = Get.isRegistered<GlobalBatchController>() ? Get.find<GlobalBatchController>().selectedBatch.value : null;
    return studentApplicants.where((s) {
      bool genderMatch = s.gender == gender;
      bool batchMatch = batch == null || s.batchNumber == batch;
      bool searchMatch = searchQuery.value.isEmpty || s.name.toLowerCase().contains(searchQuery.value.toLowerCase()) || s.academicNumber.toLowerCase().contains(searchQuery.value.toLowerCase());
      return genderMatch && batchMatch && searchMatch;
    }).toList();
  }
}
