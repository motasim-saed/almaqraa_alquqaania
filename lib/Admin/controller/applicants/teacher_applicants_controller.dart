import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../models/admin_models.dart';
import '../../repository/admin_repository.dart';
import '../../repository/supabase_admin_repository.dart';
import '../../../core/utils/app_constants.dart';

class TeacherApplicantsController extends GetxController {
  final AdminRepository _repository = SupabaseAdminRepository();
  final String djangoBaseUrl = AppConstants.djangoApiBaseUrl;

  var teacherApplicants = <TeacherModel>[].obs;
  var isLoading = false.obs;
  var isProcessing = false.obs;

  var maleSponsorshipFilter = 'all'.obs;
  var femaleSponsorshipFilter = 'all'.obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchApplicants();
  }

  Future<void> fetchApplicants() async {
    isLoading.value = true;
    try {
      teacherApplicants.assignAll(
        await _repository.getTeachers(status: 'pending'),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // دالة قبول المعلم
  Future<bool> approveApplicant(String id) async {
    isProcessing.value = true;
    try {
      final url = Uri.parse("$djangoBaseUrl/management/approve/$id/?format=json");
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'X-API-KEY': AppConstants.djangoApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _showMessage(data['message'] ?? 'approved_successfully'.tr, true);
        fetchApplicants();
        return true;
      } else {
        final data = json.decode(response.body);
        _showMessage(data['message'] ?? 'approval_failed'.tr, false);
        return false;
      }
    } catch (e) {
      _showMessage('django_connection_error'.tr, false);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  // دالة رفض المعلم
  Future<bool> rejectApplicant(String id, String reason) async {
    isProcessing.value = true;
    try {
      final url = Uri.parse("$djangoBaseUrl/management/reject/$id/?format=json");
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
        final data = json.decode(response.body);
        _showMessage(data['message'] ?? 'rejected_successfully'.tr, true);
        fetchApplicants();
        return true;
      } else {
        final data = json.decode(response.body);
        _showMessage(data['message'] ?? 'rejection_failed'.tr, false);
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
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
        if (Get.isDialogOpen!) Get.back(); // إغلاق تفاصيل المتقدم
      }
    });
  }

  Future<void> refreshData() => fetchApplicants();

  int get maleCount => teacherApplicants.where((t) => t.gender == Gender.male).length;
  int get femaleCount => teacherApplicants.where((t) => t.gender == Gender.female).length;
}
