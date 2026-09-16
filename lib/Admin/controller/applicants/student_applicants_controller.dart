import 'dart:convert'; // استيراد مكتبة تحويل البيانات
import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر للألوان والواجهات
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والتنقل
import 'package:http/http.dart' as http; // استيراد مكتبة HTTP للتعامل مع API
import '../../models/admin_models.dart'; // استيراد نماذج بيانات الطلاب والمعلمين
import '../../repository/admin_repository.dart'; // استيراد واجهة مستودع بيانات الإدارة
import '../../repository/supabase_admin_repository.dart'; // استيراد تنفيذ المستودع باستخدام Supabase
import '../../../core/utils/app_constants.dart'; // استيراد الثوابت للوصول للرابط الأساسي والمفتاح

// كلاس التحكم في طلبات انضمام الطلاب الجدد (المتقدمين)
class StudentApplicantsController extends GetxController {
  final AdminRepository _repository = SupabaseAdminRepository();
  final String djangoBaseUrl = AppConstants.djangoApiBaseUrl;

  var studentApplicants = <StudentModel>[].obs;
  var isLoading = false.obs;
  var isProcessing = false.obs; // متغير لمتابعة حالة معالجة الطلب (قبول/رفض)

  var maleDistributionFilter = 'all'.obs;
  var femaleDistributionFilter = 'all'.obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchApplicants();
  }

  // جلب قائمة المتقدمين
  Future<void> fetchApplicants() async {
    isLoading.value = true;
    try {
      studentApplicants.assignAll(
        await _repository.getStudents(status: 'pending'),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // دالة قبول الطالب
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
        fetchApplicants(); // تحديث القائمة بعد النجاح
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

  // دالة رفض الطالب
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

  // دالة إظهار الرسالة في منتصف الشاشة (خضراء للنجاح وحمراء للفشل)
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
      barrierDismissible: false, // لا يمكن إغلاقها بالضغط خارجها لضمان رؤيتها
    );

    // إغلاق الرسالة تلقائياً بعد ثانيتين ثم العودة لشاشة الطلاب
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.isDialogOpen!) Get.back(); // إغلاق رسالة التنبيه الخضراء/الحمراء
      if (isSuccess) {
        if (Get.isDialogOpen!) Get.back(); // إغلاق شاشة تفاصيل المتقدم للرجوع للقائمة الرئيسية
      }
    });
  }

  Future<void> refreshData() => fetchApplicants();

  int get maleCount => studentApplicants.where((s) => s.gender == Gender.male).length;
  int get femaleCount => studentApplicants.where((s) => s.gender == Gender.female).length;
}
