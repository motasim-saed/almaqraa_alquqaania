import 'package:al_maqraa/Admin/screen/holidays_and_leaves/holiday_management_screen.dart';
import 'package:al_maqraa/Admin/screen/holidays_and_leaves/student_leave_management_screen.dart';
import 'package:al_maqraa/Admin/screen/settings/admin_maintenance_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/admin_models.dart';
import '../screen/home/admin_home_screen.dart';
import '../screen/applicants/teacher_applicants_screen.dart';
import '../screen/applicants/student_applicants_screen.dart';
import '../screen/accepted/accepted_teachers_screen.dart';
import '../screen/accepted/accepted_students_screen.dart';
import '../screen/settings/admin_settings_screen.dart';
import '../screen/quran_circles/quran_circles_screen.dart';
import '../screen/reports/halaqa_reports_screen.dart';
import 'reports/halaqa_reports_controller.dart';
import 'home/admin_home_controller.dart';
import 'applicants/applicants_controller.dart';
import 'quran_circles_controller.dart';
import 'accepted/accepted_teachers_controller.dart';
import 'accepted/accepted_students_controller.dart';
import 'certificates/certificates_controller.dart';
import '../screen/exam_committee/exam_committee_screen.dart';
import '../screen/certificates/certificates_main_screen.dart';
import '../screen/notifications/admin_send_notification_screen.dart';
import '../screen/notifications/admin_sent_notifications_screen.dart';
import 'holiday_controller.dart';
import 'settings/admin_manage_users_controller.dart';
import '../screen/settings/admin_manage_users_screen.dart';
import '../screen/financial_support/admin_financial_support_screen.dart';
import 'financial_support_controller.dart';
import 'settings/admin_settings_controller.dart';

class AdminLayoutController extends GetxController {
  final _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;

  var isSearching = false.obs;
  final TextEditingController searchController = TextEditingController();

  var quranCirclesGenderFilter = Gender.all.obs;
  var isRefreshing = false.obs;

  // تهيئة المتحكمات الضرورية عند بدء تشغيل اللاي أوت
  @override
  void onInit() {
    super.onInit();
    // التأكد من وجود متحكم الإعدادات والصيانة
    if (!Get.isRegistered<AdminSettingsController>()) {
      Get.put(AdminSettingsController(), permanent: true);
    }
  }

  List<Widget> get screens => [
    const AdminHomeScreen(),
    const TeacherApplicantsScreen(),
    const StudentApplicantsScreen(),
    const QuranCirclesScreen(),
    const AcceptedTeachersScreen(gender: Gender.male),
    const AcceptedStudentsScreen(gender: Gender.male),
    const HalaqaReportsScreen(),
    const AdminSettingsScreen(),
    const ExamCommitteeScreen(),
    const CertificatesMainScreen(),
    const AdminSendNotificationScreen(),
    const HolidayManagementScreen(),
    const StudentLeaveManagementScreen(),
    const AcceptedTeachersScreen(gender: Gender.female),
    const AcceptedStudentsScreen(gender: Gender.female),
    const AdminSentNotificationsScreen(),
    const AdminManageUsersScreen(),
    AdminFinancialSupportScreen(),
    const AdminMaintenanceScreen(), // index 18
  ];

  void changeIndex(int index) {
    _currentIndex.value = index;
    isSearching.value = false;
    searchController.clear();
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchController.clear();
      updateSearchQuery('');
    }
  }

  void updateSearchQuery(String query) {
    final controller = _getActiveController();
    if (controller != null) {
      try {
        controller.searchQuery.value = query;
      } catch (e) {}
    }
  }

  Future<void> refreshCurrentScreen() async {
    if (isRefreshing.value) return;
    
    isRefreshing.value = true;
    try {
      await Future.wait([
        if (Get.isRegistered<AdminHomeController>()) Get.find<AdminHomeController>().refreshData(),
        if (Get.isRegistered<ApplicantsController>()) Get.find<ApplicantsController>().refreshData(),
        if (Get.isRegistered<AcceptedTeachersController>()) Get.find<AcceptedTeachersController>().refreshData(),
        if (Get.isRegistered<AcceptedStudentsController>()) Get.find<AcceptedStudentsController>().refreshData(),
        if (Get.isRegistered<QuranCirclesController>()) Get.find<QuranCirclesController>().refreshData(),
        if (Get.isRegistered<HalaqaReportsController>()) Get.find<HalaqaReportsController>().refreshData(),
        if (Get.isRegistered<AdminSettingsController>()) Get.find<AdminSettingsController>().refreshData(),
      ]);
    } catch (e) {} finally {
      isRefreshing.value = false;
    }
  }

  dynamic _getActiveController() {
    switch (currentIndex) {
      case 0: return Get.find<AdminHomeController>();
      case 1:
      case 2: return Get.find<ApplicantsController>();
      case 3:
      case 8: return Get.find<QuranCirclesController>();
      case 4:
      case 13: return Get.find<AcceptedTeachersController>();
      case 5:
      case 14: return Get.find<AcceptedStudentsController>();
      case 6: return Get.find<HalaqaReportsController>();
      case 9: return Get.find<CertificatesController>();
      case 11: return Get.find<HolidayController>();
      case 16: return Get.find<AdminManageUsersController>();
      case 17: return Get.find<FinancialSupportController>();
      case 18: return Get.find<AdminSettingsController>();
      default: return null;
    }
  }

  String get screenCount {
    final controller = _getActiveController();
    if (controller == null) return '';
    try {
      switch (currentIndex) {
        case 1: return controller.teacherApplicants.length.toString();
        case 2: return controller.studentApplicants.length.toString();
        case 3:
        case 8: return controller.quranCircles.length.toString();
        case 4: return controller.maleCount.toString();
        case 13: return controller.femaleCount.toString();
        case 5: return controller.maleCount.toString();
        case 14: return controller.femaleCount.toString();
        case 6: return controller.quranCircles.length.toString();
        case 11: return controller.holidays.length.toString();
        default: return '';
      }
    } catch (e) { return ''; }
  }

  String get screenTitle {
    switch (currentIndex) {
      case 0: return 'home'.tr;
      case 1: return 'teacher_applicants'.tr;
      case 2: return 'student_applicants'.tr;
      case 3: return 'quran_circles'.tr;
      case 4: return 'male_teachers'.tr;
      case 5: return 'male_students'.tr;
      case 6: return 'reports'.tr;
      case 7: return 'settings'.tr;
      case 8: return 'exam_committee'.tr;
      case 9: return 'certificates'.tr;
      case 10: return 'send_notification'.tr;
      case 11: return 'holiday_management'.tr;
      case 12: return 'grant_leave_title'.tr;
      case 13: return 'female_teachers'.tr;
      case 14: return 'female_students'.tr;
      case 15: return 'sent_notifications'.tr;
      case 16: return 'manage_management_users'.tr;
      case 17: return 'financial_support_mgmt'.tr;
      case 18: return 'صيانة النظام والتخزين';
      default: return '';
    }
  }
}
