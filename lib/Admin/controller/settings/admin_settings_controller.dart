// هذا الملف هو المتحكم (Controller) المسؤول عن إدارة إعدادات النظام من قبل المسؤول (Admin).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/system_setting_model.dart';
import '../../repository/admin_repository.dart';
import '../../repository/supabase_admin_repository.dart';

class AdminSettingsController extends GetxController {
  final AdminRepository _repository = SupabaseAdminRepository();

  var isLoading = false.obs;
  var isSaving = false.obs;
  var isCleaning = false.obs;

  // إحصائيات النظام التقنية
  var dbSize = '0 MB'.obs;
  var storageSize = '0 MB'.obs;
  var bandwidth = '0 MB'.obs;

  // شروط وإعدادات النظام
  var studentRegistrationEnabled = true.obs;
  var batchMode = 'student'.obs;
  var defaultBatchNumber = 1.obs;

  final TextEditingController batchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchSystemSettings();
    fetchUsageStats();
  }

  @override
  void onClose() {
    batchController.dispose();
    super.onClose();
  }

  Future<void> refreshData() async {
    await fetchSystemSettings();
    await fetchUsageStats();
  }

  Future<void> fetchSystemSettings() async {
    isLoading.value = true;
    try {
      final settings = await _repository.getSystemSettings();
      if (settings != null) {
        studentRegistrationEnabled.value = settings.studentRegistrationEnabled;
        batchMode.value = settings.batchMode;
        defaultBatchNumber.value = settings.defaultBatchNumber;
        batchController.text = settings.defaultBatchNumber.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUsageStats() async {
    try {
      final stats = await _repository.getUsageStats();
      dbSize.value = stats['db'] ?? '0 MB';
      storageSize.value = stats['storage'] ?? '0 MB';
      bandwidth.value = stats['bandwidth'] ?? 'يُراجع من لوحة Supabase';
    } catch (e) {
      dbSize.value = 'Error';
      storageSize.value = 'Error';
      bandwidth.value = 'Error';
    }
  }

  Future<void> clearAllMedia() async {
    Get.defaultDialog(
      title: "تنبيه هام",
      middleText: "هل أنت متأكد من حذف جميع ملفات الوسائط والصوتيات من التخزين؟ هذا الإجراء لا يمكن التراجع عنه.",
      textConfirm: "تأكيد الحذف",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        isCleaning.value = true;
        final success = await _repository.clearMedia();
        isCleaning.value = false;
        if (success) {
          Get.snackbar("نجاح", "تم حذف جميع ملفات الوسائط بنجاح", backgroundColor: Colors.green, colorText: Colors.white);
          fetchUsageStats();
        } else {
          Get.snackbar("خطأ", "فشل حذف الوسائط", backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }

  Future<void> clearAllPeriodRecords() async {
    Get.defaultDialog(
      title: "تأكيد تصفير السجلات والمحادثات",
      middleText: "سيتم حذف جميع رسائل الشات، والسجلات اليومية والشهرية، والاختبارات والاستئذانات لتوفير المساحة في قاعدة البيانات.\n\n✅ سيتم الحفاظ على حسابات الطلاب والمعلمين والحلقات والمناهج دون أي مساس.",
      textConfirm: "تأكيد التصفير",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Colors.deepOrange,
      onConfirm: () async {
        Get.back();
        isCleaning.value = true;
        final success = await _repository.clearAllPeriodRecords();
        isCleaning.value = false;
        if (success) {
          Get.snackbar("نجاح", "تم تفريغ كافة السجلات والمحادثات بنجاح", backgroundColor: Colors.green, colorText: Colors.white);
          fetchUsageStats();
        } else {
          Get.snackbar("خطأ", "فشل تفريغ السجلات", backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }

  Future<void> deleteDataByDate(String tableName, int year, {int? month}) async {
    isCleaning.value = true;
    try {
      final success = await _repository.deleteOldData(tableName, year, month: month);
      if (success) {
        Get.snackbar("نجاح", "تم حذف البيانات المحددة بنجاح", backgroundColor: Colors.green, colorText: Colors.white);
        fetchUsageStats();
      } else {
        Get.snackbar("خطأ", "فشل حذف البيانات", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } finally {
      isCleaning.value = false;
    }
  }

  Future<bool> saveSettings({bool showSnackbar = true}) async {
    isSaving.value = true;
    try {
      final newSettings = SystemSettingModel(
        studentRegistrationEnabled: studentRegistrationEnabled.value,
        batchMode: batchMode.value,
        defaultBatchNumber: defaultBatchNumber.value,
      );

      final success = await _repository.updateSystemSettings(newSettings);
      if (success) {
        if (showSnackbar) {
          Get.snackbar('success'.tr, 'settings_updated_success'.tr, backgroundColor: Colors.green, colorText: Colors.white);
        }
        return true;
      } else {
        if (showSnackbar) {
          Get.snackbar('error'.tr, 'settings_update_failed'.tr, backgroundColor: Colors.red, colorText: Colors.white);
        }
        return false;
      }
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleRegistration(bool val) async {
    final oldVal = studentRegistrationEnabled.value;
    studentRegistrationEnabled.value = val;
    final success = await saveSettings();
    if (!success) studentRegistrationEnabled.value = oldVal;
  }

  Future<void> setBatchMode(String? mode) async {
    if (mode != null) {
      final oldMode = batchMode.value;
      batchMode.value = mode;
      final success = await saveSettings();
      if (!success) batchMode.value = oldMode;
    }
  }
}
