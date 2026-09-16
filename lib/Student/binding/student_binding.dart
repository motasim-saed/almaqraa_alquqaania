import 'package:get/get.dart';
import '../controller/student_progress_controller.dart';
import '../controller/homepage_student_controller.dart';
import '../../core/controllers/profile_controller.dart';
import '../../Teacher/controller/settings_controller.dart';

class StudentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomepageStudentController());
    Get.lazyPut(() => StudentProgressController());
    Get.lazyPut(() => ProfileController());
    Get.lazyPut(() => SettingsController());
  }
}
