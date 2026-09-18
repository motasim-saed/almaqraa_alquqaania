import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والتنقل
import '../../models/admin_models.dart'; // استيراد نماذج بيانات الطلاب والمعلمين
import '../../repository/admin_repository.dart'; // استيراد واجهة مستودع بيانات الإدارة
import '../../repository/supabase_admin_repository.dart'; // استيراد تنفيذ المستودع باستخدام Supabase
import '../../../core/services/file_export_service.dart'; // استيراد خدمة تصدير الملفات (Excel)
import '../../screen/widgets/export_columns_dialog.dart'; // استيراد نافذة اختيار أعمدة التصدير
import '../../screen/widgets/user_selector_dialog.dart'; // استيراد نافذة اختيار المستخدمين للتصدير
import '../../../core/services/cache_service.dart'; // استيراد خدمة التخزين المؤقت
import '../../../core/controllers/global_batch_controller.dart'; // استيراد متحكم الدفعات

// كلاس التحكم في الطلاب المقبولين والنشطين في النظام
class AcceptedStudentsController extends GetxController {
  final AdminRepository _repository = SupabaseAdminRepository();
  final CacheService _cacheService = Get.find<CacheService>();

  var acceptedStudents = <StudentModel>[].obs;
  var isLoading = false.obs;

  var maleDistributionFilter = 'all'.obs;
  var femaleDistributionFilter = 'all'.obs;
  var maleCategoryFilter = 'all'.obs;
  var femaleCategoryFilter = 'all'.obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAcceptedStudents();
  }

  /// جلب كافة الطلاب المقبولين مع دعم التخزين المحلي أولاً
  Future<void> fetchAcceptedStudents() async {
    // 1. محاولة تحميل البيانات من الكاش لعرضها فوراً
    _loadFromCache();

    if (acceptedStudents.isEmpty) {
      isLoading.value = true;
    }
    try {
      // 2. جلب البيانات الحديثة من السيرفر
      final students = await _repository.getStudents(status: 'accepted');

      // 3. تحديث القائمة الحية
      acceptedStudents.assignAll(students);

      // 4. حفظ النسخة الجديدة في الكاش
      _saveToCache(students);
    } catch (e) {
      // في حالة فشل الإنترنت، يستمر التطبيق في عرض بيانات الكاش
    } finally {
      isLoading.value = false;
    }
  }

  void _loadFromCache() {
    final cachedData = _cacheService.getData('accepted_students');
    if (cachedData != null) {
      acceptedStudents.assignAll(
        (cachedData as List).map((e) => StudentModel.fromJson(e)).toList(),
      );
    }
  }

  void _saveToCache(List<StudentModel> students) {
    _cacheService.saveData(
      'accepted_students',
      students.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> refreshData() => fetchAcceptedStudents();

  int get maleCount =>
      acceptedStudents.where((s) => s.gender == Gender.male).length;
  int get femaleCount =>
      acceptedStudents.where((s) => s.gender == Gender.female).length;

  int get maleDistributed => acceptedStudents
      .where((s) => s.gender == Gender.male && s.isDistributed)
      .length;
  int get femaleDistributed => acceptedStudents
      .where((s) => s.gender == Gender.female && s.isDistributed)
      .length;

  int get femaleNotDistributed => acceptedStudents
      .where((s) => s.gender == Gender.female && !s.isDistributed)
      .length;

  List<StudentModel> filteredStudentsList(Gender gender) {
    final distributionFilter = gender == Gender.male
        ? maleDistributionFilter.value
        : femaleDistributionFilter.value;
    final categoryFilter = gender == Gender.male
        ? maleCategoryFilter.value
        : femaleCategoryFilter.value;

    int? globalBatch;
    if (Get.isRegistered<GlobalBatchController>()) {
      globalBatch = Get.find<GlobalBatchController>().selectedBatch.value;
    }

    return acceptedStudents.where((s) {
      bool genderMatch = s.gender == gender;
      bool distributionMatch =
          distributionFilter == 'all' ||
          (distributionFilter == 'distributed' && s.isDistributed) ||
          (distributionFilter == 'not_distributed' && !s.isDistributed);
      bool categoryMatch =
          categoryFilter == 'all' || s.level == categoryFilter;
      bool searchMatch =
          searchQuery.value.isEmpty ||
          s.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          s.academicNumber.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );
      bool batchMatch = globalBatch == null || s.batchNumber == globalBatch;

      return genderMatch &&
          distributionMatch &&
          categoryMatch &&
          searchMatch &&
          batchMatch;
    }).toList();
  }

  void removeUser(String id) async {
    bool success = await _repository.deleteStudent(id);
    if (success) {
      fetchAcceptedStudents();
    }
  }

  void transferStudent(String studentId, String newCircleId) async {
    bool success = await _repository.transferStudent(studentId, newCircleId);
    if (success) {
      Get.snackbar('success'.tr, 'student_transferred_success'.tr);
      fetchAcceptedStudents();
    }
  }

  void updateBatch(String id, int batchNumber) async {
    bool success = await _repository.updateUserBatch(id, batchNumber);
    if (success) {
      fetchAcceptedStudents();
    }
  }

  void exportStudents(Gender gender) async {
    final exportBaseList = filteredStudentsList(gender);

    if (exportBaseList.isEmpty) {
      Get.snackbar('alert'.tr, 'no_data_for_export'.tr);
      return;
    }

    final List<String>? selectedUserIds = await Get.dialog<List<String>>(
      UserSelectorDialog(
        users: exportBaseList,
        title: 'select_students_to_export'.tr,
      ),
    );

    if (selectedUserIds == null || selectedUserIds.isEmpty) return;

    final columns = {
      'name': 'col_name'.tr,
      'email': 'col_email'.tr,
      'academic_number': 'col_academic_number'.tr,
      'level': 'col_level'.tr,
      'gender': 'col_gender'.tr,
      'is_distributed': 'col_is_distributed'.tr,
      'circle_name': 'col_circle_name'.tr,
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
          .where((s) => selectedUserIds.contains(s.id))
          .toList();

      await FileExportService.exportStudentsToExcel(
        exportList,
        selectedColumns: selectedKeys,
      );
      Get.snackbar('export'.tr, 'export_accepted_students_success'.tr);
    }
  }
}
