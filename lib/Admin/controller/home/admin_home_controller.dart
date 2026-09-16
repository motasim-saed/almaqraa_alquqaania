import 'package:get/get.dart';
import '../../models/dashboard_stats_model.dart';
import '../applicants/applicants_controller.dart';
import '../accepted/accepted_teachers_controller.dart';
import '../accepted/accepted_students_controller.dart';
import '../quran_circles_controller.dart';
import '../holiday_controller.dart';

class AdminHomeController extends GetxController {
  var isLoading = false.obs; // للتحميل الأول (الشاشة كاملة)
  var isRefreshing = false.obs; // لعملية التحديث (أيقونة صغيرة)
  var searchQuery = ''.obs;

  final applicantsCtrl = Get.put(ApplicantsController(), permanent: true);
  final accTeachersCtrl = Get.put(AcceptedTeachersController(), permanent: true);
  final accStudentsCtrl = Get.put(AcceptedStudentsController(), permanent: true);
  final circlesCtrl = Get.put(QuranCirclesController(), permanent: true);
  final holidayCtrl = Get.put(HolidayController(), permanent: true);

  DashboardStatsModel get stats {
    return DashboardStatsModel(
      teacherApplicants: applicantsCtrl.teacherApplicants.length,
      studentApplicants: applicantsCtrl.studentApplicants.length,
      acceptedTeachers: accTeachersCtrl.acceptedTeachers.length,
      acceptedStudents: accStudentsCtrl.acceptedStudents.length,
      unreadTeacherChats: 0,
      unreadStudentChats: 0,
      totalCircles: circlesCtrl.quranCircles.length,
    );
  }

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    // منع تكرار التحديث إذا كان جارياً بالفعل
    if (isRefreshing.value) return;

    bool hasLocalData = applicantsCtrl.teacherApplicants.isNotEmpty ||
        accTeachersCtrl.acceptedTeachers.isNotEmpty ||
        circlesCtrl.quranCircles.isNotEmpty;

    if (!hasLocalData) {
      isLoading.value = true;
    }
    
    isRefreshing.value = true;

    try {
      // استخدام Future.wait مع معالجة الأخطاء لكل طلب لضمان عدم توقف البقية
      await Future.wait([
        applicantsCtrl.fetchApplicants().catchError((e) => print("Error fetching applicants: $e")),
        accTeachersCtrl.fetchData().catchError((e) => print("Error fetching teachers: $e")),
        accStudentsCtrl.fetchAcceptedStudents().catchError((e) => print("Error fetching students: $e")),
        circlesCtrl.fetchQuranCircles().catchError((e) => print("Error fetching circles: $e")),
        holidayCtrl.fetchHolidays().catchError((e) => print("Error fetching holidays: $e")),
      ]);
    } catch (e) {
      // print("Global refresh error: $e");
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }
}
