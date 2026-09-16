// import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/admin_models.dart';
import '../../repository/admin_repository.dart';
import '../../repository/supabase_admin_repository.dart';
import '../../../core/services/file_export_service.dart';
import '../../screen/widgets/export_columns_dialog.dart';
import '../../screen/widgets/user_selector_dialog.dart';
import '../../../core/services/cache_service.dart'; // استيراد خدمة التخزين المؤقت
import '../../../core/controllers/global_batch_controller.dart'; // استيراد متحكم الدفعات

class AcceptedTeachersController extends GetxController {
  final AdminRepository _repository = SupabaseAdminRepository();
  final CacheService _cacheService = Get.find<CacheService>();

  var acceptedTeachers = <TeacherModel>[].obs;
  var quranCircles = <QuranCircleModel>[].obs;
  var isLoading = false.obs;

  var maleSponsorshipFilter = 'all'.obs;
  var femaleSponsorshipFilter = 'all'.obs;
  var maleDistributionFilter = 'all'.obs;
  var femaleDistributionFilter = 'all'.obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  /// دالة جلب البيانات مع دعم التخزين المحلي أولاً
  Future<void> fetchData() async {
    // 1. محاولة تحميل البيانات من الكاش لعرضها فوراً للمستخدم
    _loadFromCache();

    if (acceptedTeachers.isEmpty) {
      isLoading.value = true;
    }
    try {
      // 2. جلب البيانات الحديثة من السيرفر
      final circles = await _repository.getQuranCircles();
      final teachers = await _repository.getTeachers(status: 'accepted');

      // 3. تحديث القوائم الحية
      quranCircles.assignAll(circles);
      acceptedTeachers.assignAll(teachers);

      // 4. حفظ النسخة الجديدة في الكاش
      _saveToCache(teachers, circles);
    } catch (e) {
      // في حالة فشل الإنترنت، يستمر التطبيق في عرض بيانات الكاش
    } finally {
      isLoading.value = false;
    }
  }

  void _loadFromCache() {
    final cachedTeachers = _cacheService.getData('accepted_teachers');
    final cachedCircles = _cacheService.getData('quran_circles');

    if (cachedTeachers != null) {
      acceptedTeachers.assignAll(
        (cachedTeachers as List).map((e) => TeacherModel.fromJson(e)).toList(),
      );
    }
    if (cachedCircles != null) {
      quranCircles.assignAll(
        (cachedCircles as List)
            .map((e) => QuranCircleModel.fromJson(e))
            .toList(),
      );
    }
  }

  void _saveToCache(
    List<TeacherModel> teachers,
    List<QuranCircleModel> circles,
  ) {
    _cacheService.saveData(
      'accepted_teachers',
      teachers.map((e) => e.toJson()).toList(),
    );
    _cacheService.saveData(
      'quran_circles',
      circles.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> refreshData() => fetchData();

  bool isTeacherDistributed(String teacherId) {
    if (quranCircles.isEmpty) return false;
    return quranCircles.any((circle) {
      return circle.teacherId == teacherId ||
          circle.teacherIds.contains(teacherId);
    });
  }

  int get maleCount =>
      acceptedTeachers.where((t) => t.gender == Gender.male).length;
  int get femaleCount =>
      acceptedTeachers.where((t) => t.gender == Gender.female).length;

  List<TeacherModel> filteredTeachersList(Gender gender) {
    final sponsorshipFilter = gender == Gender.male
        ? maleSponsorshipFilter.value
        : femaleSponsorshipFilter.value;
    final distributionFilter = gender == Gender.male
        ? maleDistributionFilter.value
        : femaleDistributionFilter.value;

    int? globalBatch;
    if (Get.isRegistered<GlobalBatchController>()) {
      globalBatch = Get.find<GlobalBatchController>().selectedBatch.value;
    }

    return acceptedTeachers.where((t) {
      if (t.gender != gender) return false;
      bool sponsorshipMatch =
          sponsorshipFilter == 'all' ||
          (sponsorshipFilter == 'needed' && !t.canCoverBalance) ||
          (sponsorshipFilter == 'not_needed' && t.canCoverBalance);
      bool distributedStatus = isTeacherDistributed(t.id);
      bool distributionMatch =
          distributionFilter == 'all' ||
          (distributionFilter == 'distributed' && distributedStatus) ||
          (distributionFilter == 'not_distributed' && !distributedStatus);
      bool searchMatch =
          searchQuery.value.isEmpty ||
          t.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          t.academicNumber.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );
      bool batchMatch = globalBatch == null || t.batchNumber == globalBatch;

      return sponsorshipMatch && distributionMatch && searchMatch && batchMatch;
    }).toList();
  }

  void removeUser(String id) async {
    bool success = await _repository.deleteTeacher(id);
    if (success) {
      fetchData();
    }
  }

  void updateSponsorship(
    TeacherModel teacher, {
    required bool needsSponsorship,
    double? amount,
    String? package,
  }) async {
    bool success = await _repository.updateTeacherSponsorship(
      teacher.id,
      !needsSponsorship,
      amount: amount,
      package: package,
    );
    if (success) {
      Get.snackbar('success'.tr, 'sponsorship_status_updated'.tr);
      fetchData();
    }
  }

  void updateBatch(String id, int batchNumber) async {
    bool success = await _repository.updateUserBatch(id, batchNumber);
    if (success) {
      fetchData();
    }
  }

  void exportTeachers(Gender gender) async {
    final exportBaseList = filteredTeachersList(gender);
    if (exportBaseList.isEmpty) {
      Get.snackbar('alert'.tr, 'no_data_for_export'.tr);
      return;
    }

    final List<String>? selectedUserIds = await Get.dialog<List<String>>(
      UserSelectorDialog(
        users: exportBaseList,
        title: 'select_teachers_to_export'.tr,
      ),
    );
    if (selectedUserIds == null || selectedUserIds.isEmpty) return;

    final columns = {
      'name': 'col_name'.tr,
      'email': 'col_email'.tr,
      'academic_number': 'col_academic_number'.tr,
      'specialization': 'col_specialization'.tr,
      'gender': 'col_gender'.tr,
      'can_cover_balance': 'col_needs_sponsorship'.tr,
      'sponsorship_amount': 'col_sponsorship_amount'.tr,
      'package_type': 'col_package_type'.tr,
      'phone': 'col_phone'.tr,
    };

    final selectedKeys = await Get.dialog<List<String>>(
      ExportColumnsDialog(
        availableColumns: columns,
        title: 'select_columns'.tr,
      ),
    );

    if (selectedKeys != null) {
      final exportList = exportBaseList
          .where((t) => selectedUserIds.contains(t.id))
          .toList();
      await FileExportService.exportTeachersToExcel(
        exportList,
        selectedColumns: selectedKeys,
      );
      Get.snackbar('export'.tr, 'export_accepted_teachers_success'.tr);
    }
  }
}
