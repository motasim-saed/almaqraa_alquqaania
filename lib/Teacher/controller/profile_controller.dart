import 'package:flutter/material.dart'; 
import 'package:get/get.dart'; 
import 'package:get_storage/get_storage.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; 
// ignore: library_prefixes
import 'package:al_maqraa/core/controllers/profile_controller.dart' as CoreProfile; 

class TeacherProfileController extends GetxController { 
  final SupabaseClient _supabase = Supabase.instance.client; 
  final GetStorage _storage = GetStorage(); 

  final nameController = TextEditingController(); 
  final emailController = TextEditingController(); 
  final phoneController = TextEditingController(); 
  final academicNumberController = TextEditingController(); 
  final hifzLevelController = TextEditingController(); 
  final teacherNameController = TextEditingController(); 
  final circleNameController = TextEditingController(); 
  final batchNumberController = TextEditingController(); 
  final sponsorshipAmountController = TextEditingController(); 
  final packageTypeController = TextEditingController(); 

  final formKey = GlobalKey<FormState>(); 
  
  bool isLoading = false; 
  bool needsSponsorship = false; 
  RxString role = ''.obs; 
  RxString avatarUrl = ''.obs; 
  RxString backgroundUrl = ''.obs; 


  @override
  void onInit() { 
    super.onInit(); 
    _loadProfileFromCache(); 
    _refreshProfileFromServer(); 
  } 

  void _loadProfileFromCache() {
    final cachedData = _storage.read('teacher_profile_data'); 
    if (cachedData != null) { 
      _mapDataToControllers(cachedData); 
      update(); 
    }
  }

  Future<void> _refreshProfileFromServer() async {
    try {
      final user = _supabase.auth.currentUser; 
      if (user == null) return; 

      final profile = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();

      if (profile != null) {
        Map<String, dynamic> fullData = Map.from(profile); 
        fullData['email'] = profile['email'] ?? user.email; 
        
        // إذا كان البريد من الجلسة يبدأ بـ examiner_ فمن الأفضل استخدام البريد من البروفايل إن وجد
        if (user.email != null && user.email!.startsWith('examiner_')) {
          if (profile['email'] != null && profile['email'].toString().isNotEmpty) {
            fullData['email'] = profile['email'];
          }
        }

        if (profile['role'] == 'student') {
          final studentData = await _supabase.from('students').select('hifz_level').eq('user_id', user.id).maybeSingle();
          if (studentData != null) fullData['hifz_level'] = studentData['hifz_level'];
          
          final circleInfo = await _supabase.from('circle_members').select('circles!inner(name, teacher_id)').eq('student_id', user.id).maybeSingle();
          if (circleInfo != null && circleInfo['circles'] != null) {
            fullData['circle_name'] = circleInfo['circles']['name']; 
            final teacherId = circleInfo['circles']['teacher_id']; 
            if (teacherId != null) {
              final teacherProfile = await _supabase.from('profiles').select('full_name').eq('id', teacherId).maybeSingle();
              fullData['teacher_name'] = teacherProfile?['full_name']; 
            }
          }
        } 
        else if (profile['role'] == 'teacher') {
          final circleInfo = await _supabase.from('circles').select('name').eq('teacher_id', user.id).maybeSingle();
          if (circleInfo != null) fullData['circle_name'] = circleInfo['name'];
          
          final teacherData = await _supabase.from('teachers').select().eq('user_id', user.id).maybeSingle();
          if (teacherData != null) fullData.addAll(teacherData);
        }
        else if (profile['role'] == 'examiner') {
          final circleInfo = await _supabase.from('circles').select('name').eq('examiner_id', user.id).maybeSingle();
          if (circleInfo != null) fullData['circle_name'] = circleInfo['name'];
        }

        _storage.write('teacher_profile_data', fullData);
        _mapDataToControllers(fullData);
        update(); 
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_load_profile'.tr, backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }

  void _mapDataToControllers(Map<String, dynamic> data) {
    nameController.text = data['full_name'] ?? ''; 
    emailController.text = data['email'] ?? ''; 
    phoneController.text = data['phone'] ?? ''; 
    avatarUrl.value = data['avatar_url'] ?? ''; 
    backgroundUrl.value = data['background_url'] ?? ''; 
    role.value = data['role'] ?? ''; 
    academicNumberController.text = data['academic_number']?.toString() ?? 'not_available'.tr; 
    circleNameController.text = data['circle_name'] ?? ''; 
    teacherNameController.text = data['teacher_name'] ?? ''; 
    batchNumberController.text = data['batch_number']?.toString() ?? 'not_available'.tr; 
    
    if (role.value == 'student') {
      hifzLevelController.text = (data['hifz_level']?.toString() ?? 'not_available').tr; 
    } else if (role.value == 'teacher') {
      hifzLevelController.text = 'role_teacher'.tr; 
      needsSponsorship = !(data['can_cover_balance'] ?? true); 
      sponsorshipAmountController.text = data['sponsorship_amount']?.toString() ?? ''; 
      packageTypeController.text = (data['package_type']?.toString() ?? '').tr; 
    } else if (role.value == 'examiner') {
      hifzLevelController.text = 'role_examiner'.tr; 
    }
  }


  /// تعيين الحاجة لكفالة وحفظها فوراً في قاعدة البيانات
  Future<void> setNeedsSponsorship(bool value) async {
    needsSponsorship = value; 
    update(); 
    
    // الحفظ الفوري عند التغيير لضمان عدم ضياع البيانات
    try {
      final user = _supabase.auth.currentUser;
      if (user != null && role.value == 'teacher') {
        // تحديث جدول المعلمين بالحالة الجديدة
        await _supabase.from('teachers').upsert({
          'user_id': user.id,
          'can_cover_balance': !value, // إذا كان يحتاج كفالة فإنه لا يغطي الرصيد
        }, onConflict: 'user_id');
        
        // تحديث البيانات من السيرفر لمزامنة الكاش
        await _refreshProfileFromServer();
      }
    } catch (e) {
      // التراجع عن التغيير في حال فشل الاتصال بالسيرفر
      needsSponsorship = !value;
      update();
      Get.snackbar('error'.tr, 'failed_to_save'.tr, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void updateProfile() async {
    if (formKey.currentState!.validate()) { 
      isLoading = true; 
      update(); 
      try {
        final user = _supabase.auth.currentUser; 
        if (user != null) {
          await _supabase.from('profiles').update({
            'full_name': nameController.text.trim(),
            'phone': phoneController.text.trim(),
            if (emailController.text.isNotEmpty && role.value != 'examiner')
              'email': emailController.text.trim(),
          }).eq('id', user.id); 
          if (role.value == 'teacher') {
            await _supabase.from('teachers').upsert({
              'user_id': user.id, 
              'can_cover_balance': !needsSponsorship, 
              'sponsorship_amount': needsSponsorship ? double.tryParse(sponsorshipAmountController.text) : null, 
              'package_type': needsSponsorship ? packageTypeController.text : null
            }, onConflict: 'user_id'); 
          }
          await _refreshProfileFromServer(); 
          Get.snackbar('success'.tr, 'profile_updated'.tr, backgroundColor: Colors.green, colorText: Colors.white); 
          if (Get.isRegistered<CoreProfile.ProfileController>()) Get.find<CoreProfile.ProfileController>().fetchProfile(); 
        }
      } catch (e) {
        Get.snackbar('error'.tr, 'error_saving_data'.tr, backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        isLoading = false; 
        update(); 
      }
    }
  }

  Future<void> changePassword(String newPassword) async {
    isLoading = true; 
    update(); 
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      Get.snackbar('success'.tr, 'password_changed_success'.tr, backgroundColor: Colors.green, colorText: Colors.white); 
      Get.back(); 
    } catch (e) {
      Get.snackbar('error'.tr, 'password_change_failed'.tr, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading = false; 
      update(); 
    }
  }

  @override 
  void onClose() {
    nameController.dispose(); emailController.dispose(); phoneController.dispose(); 
    academicNumberController.dispose(); hifzLevelController.dispose(); 
    batchNumberController.dispose();
    teacherNameController.dispose(); circleNameController.dispose(); 
    sponsorshipAmountController.dispose(); packageTypeController.dispose(); 
    super.onClose(); 
  }
}
