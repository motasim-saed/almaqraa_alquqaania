import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
// ignore: library_prefixes
import 'package:al_maqraa/core/controllers/profile_controller.dart' as CoreProfile;

class StudentProfileController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GetStorage _storage = GetStorage();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final academicNumberController = TextEditingController();
  final hifzLevelController = TextEditingController();
  final batchNumberController = TextEditingController();
  final teacherNameController = TextEditingController();
  final circleNameController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;

  RxString avatarUrl = ''.obs;
  RxString backgroundUrl = ''.obs;
  final gender = ''.obs; // To store and edit gender

  var selectedCategory = 'full_quran'.obs;

  final List<String> categoryKeys = [
    'beginner',
    '5_parts',
    '10_parts',
    '15_parts',
    '20_parts',
    '25_parts',
    'full_quran',
    'readings',
    'ijazas',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _loadFromCache();

    if (nameController.text.isEmpty) {
      isLoading.value = true;
      update();
    }
    try {
      emailController.text = user.email ?? '';

      // 1. Profiles Data
      try {
        final profile = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
        if (profile != null) {
          nameController.text = profile['full_name'] ?? '';
          phoneController.text = profile['phone'] ?? '';
          avatarUrl.value = profile['avatar_url'] ?? '';
          backgroundUrl.value = profile['background_url'] ?? '';
          academicNumberController.text = profile['academic_number']?.toString() ?? '';

          if (profile['batch_number'] != null) {
            batchNumberController.text = profile['batch_number'].toString();
          }
          if (profile['gender'] != null) {
            gender.value = profile['gender'];
          }

          if (profile['email'] != null && profile['email'].toString().isNotEmpty && !profile['email'].toString().startsWith('examiner_')) {
            emailController.text = profile['email'];
          }
        }
      } catch (e) {
        // debugPrint('Error loading profile: $e');
      }

      // 2. Student Data
      try {
        final studentData = await _supabase.from('students').select().eq('user_id', user.id).maybeSingle();
        if (studentData != null) {
          String level = studentData['hifz_level'] ?? 'full_quran';
          selectedCategory.value = categoryKeys.contains(level) ? level : 'full_quran';

          if (batchNumberController.text.isEmpty || batchNumberController.text == 'غير محدد') {
            batchNumberController.text = studentData['batch_number']?.toString() ?? 'غير محدد';
          }
        }
      } catch (e) {
        // debugPrint('Error loading student data: $e');
      }

      // 3. Circle Info
      try {
        final circleMember = await _supabase.from('circle_members').select('circles(name, teacher_id)').eq('student_id', user.id).maybeSingle();

        if (circleMember != null && circleMember['circles'] != null) {
          final circleData = circleMember['circles'];
          circleNameController.text = circleData['name'] ?? '';

          final teacherId = circleData['teacher_id'];
          if (teacherId != null) {
            final teacherProfile = await _supabase.from('profiles').select('full_name').eq('id', teacherId).maybeSingle();
            teacherNameController.text = teacherProfile?['full_name'] ?? '';
          }
        }
      } catch (e) {
        // debugPrint('Error loading circle info: $e');
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'loading_error'.tr, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
      _saveToCache();
      update();
    }
  }

  void _saveToCache() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    _storage.write('student_profile_${user.id}', {
      'name': nameController.text,
      'phone': phoneController.text,
      'avatarUrl': avatarUrl.value,
      'backgroundUrl': backgroundUrl.value,
      'academicNumber': academicNumberController.text,
      'batchNumber': batchNumberController.text,
      'hifzLevel': selectedCategory.value,
      'circleName': circleNameController.text,
      'teacherName': teacherNameController.text,
      'gender': gender.value,
    });
  }

  void _loadFromCache() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final cached = _storage.read('student_profile_${user.id}');
    if (cached != null) {
      nameController.text = cached['name'] ?? '';
      phoneController.text = cached['phone'] ?? '';
      avatarUrl.value = cached['avatarUrl'] ?? '';
      backgroundUrl.value = cached['backgroundUrl'] ?? '';
      academicNumberController.text = cached['academicNumber'] ?? '';
      batchNumberController.text = cached['batchNumber'] ?? '';
      selectedCategory.value = cached['hifzLevel'] ?? 'full_quran';
      circleNameController.text = cached['circleName'] ?? '';
      teacherNameController.text = cached['teacherName'] ?? '';
      if (cached['gender'] != null) {
        gender.value = cached['gender'];
      }
    }
  }


  void updateProfile() async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      update();
      try {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _supabase.from('profiles').update({
            'full_name': nameController.text.trim(),
            'phone': phoneController.text.trim(),
            if (gender.value.isNotEmpty) 'gender': gender.value,
          }).eq('id', user.id);

          await _supabase.from('students').upsert({
            'user_id': user.id,
            'hifz_level': selectedCategory.value,
          }, onConflict: 'user_id');

          Get.snackbar('success'.tr, 'profile_updated'.tr, backgroundColor: Colors.green, colorText: Colors.white);
          if (Get.isRegistered<CoreProfile.ProfileController>()) {
            Get.find<CoreProfile.ProfileController>().fetchProfile();
          }
          await _loadStudentProfile();
        }
      } catch (e) {
        Get.snackbar('error'.tr, 'save_failed'.tr, backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        isLoading.value = false;
        update();
      }
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    academicNumberController.dispose();
    hifzLevelController.dispose();
    batchNumberController.dispose();
    teacherNameController.dispose();
    circleNameController.dispose();
    super.onClose();
  }
}
