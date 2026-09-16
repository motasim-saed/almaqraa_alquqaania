import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:al_maqraa/Auth/routing/auth_route.dart';
import 'package:al_maqraa/core/services/background_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Admin/routing/admin_route.dart';
import '../../Teacher/routing/teacher_route.dart';
import '../../Student/routing/student_route.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/connectivity_service.dart';

class AuthController extends GetxController {
  final BiometricService _biometricService = BiometricService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isLoginPasswordHidden = true.obs;
  var isLoading = false.obs;
  var isBiometricSupported = false.obs;
  var isBiometricEnabled = false.obs;

  final registerEmailController = TextEditingController();
  final registerUniqueCodeController = TextEditingController();

  final resetPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  var isResetPasswordHidden = true.obs;
  var isConfirmPasswordHidden = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedEmail(); // تحميل البريد المحفوظ إن وجد
    checkBiometricSupport();
  }

  Future<void> _loadSavedEmail() async {
    final credentials = await _biometricService.getCredentials();
    if (credentials != null && credentials['email'] != null) {
      emailController.text = credentials['email']!;
    }
  }

  Future<void> checkBiometricSupport() async {
    isBiometricSupported.value = await _biometricService.canAuthenticate();
    isBiometricEnabled.value = await _biometricService.isBiometricEnabled();
    final credentials = await _biometricService.getCredentials();
    if (credentials == null) {
      isBiometricEnabled.value = false;
    }
    update();
  }

  void toggleLoginPasswordVisibility() =>
      isLoginPasswordHidden.value = !isLoginPasswordHidden.value;
  void toggleResetPasswordVisibility() =>
      isResetPasswordHidden.value = !isResetPasswordHidden.value;
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;

  bool _isPlatformAllowed(String role) {
    final lowRole = role.toLowerCase();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      if (lowRole == 'admin') {
        _showResultDialog('admin_only_on_desktop'.tr, false);
        return false;
      }
    } else if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      if (lowRole != 'admin' && lowRole != 'coordinator' && lowRole != 'super_admin' && lowRole != 'management') {
        _showResultDialog('mobile_only_account'.tr, false);
        return false;
      }
    }
    return true;
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      _showResultDialog('valid_email_error'.tr, false);
      return;
    }
    if (password.isEmpty) {
      _showResultDialog('valid_password_error'.tr, false);
      return;
    }

    isLoading.value = true;

    // فحص الاتصال الفوري للتأكد من حالة الشبكة
    bool isConnected = true;
    try {
      final connectivity = Get.find<ConnectivityService>();
      isConnected = connectivity.isConnected.value;
    } catch (e) {
      isConnected = true;
    }

    if (!isConnected) {
      await _tryOfflineLoginFallback(email, password);
      isLoading.value = false;
      return;
    }

    try {
      String resolvedEmail = email;
      // محاولة حل البريد إذا كان المدخل رقماً أكاديمياً
      if (!resolvedEmail.contains('@')) {
        try {
          final lookup = await Supabase.instance.client
              .from('profiles')
              .select('email')
              .or('academic_number.eq.$resolvedEmail,email.eq.$resolvedEmail')
              .maybeSingle();
          if (lookup != null && lookup['email'] != null) {
            resolvedEmail = lookup['email'];
          }
        } catch (e) {
          // إذا فشل البحث بسبب الشبكة، سنحاول الدخول بالأوفلاين مباشرة
          if (_isNetworkError(e)) {
            await _tryOfflineLoginFallback(email, password);
            return;
          }
        }
      }

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: resolvedEmail,
        password: password,
      );

      if (response.user == null) throw 'login_failed'.tr;

      String role = 'student';
      // 1. البحث في جدول المدراء
      final adminData = await Supabase.instance.client
          .from('admins')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (adminData != null) {
        role = 'admin';
      } else {
        // 2. البحث في جدول البروفايلات (للمنسقين والطلاب والمعلمين)
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .maybeSingle();
            
        if (profile != null) {
          role = profile['role']?.toString() ?? 'student';
        } else {
          // إذا لم يوجد في أي جدول، نقوم بتسجيل الخروج وإظهار رسالة خطأ
          await Supabase.instance.client.auth.signOut();
          throw 'لا يوجد سجل بيانات لهذا المستخدم. يرجى التواصل مع الإدارة.';
        }
      }

      if (!_isPlatformAllowed(role)) {
        await Supabase.instance.client.auth.signOut();
        isLoading.value = false;
        return;
      }

      // حفظ البيانات للدخول مستقبلاً (حتى بدون إنترنت)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role.toLowerCase());
      await prefs.setBool('isSetupComplete', true);

      // حفظ بيانات الاعتماد بشكل آمن لدعم الدخول بدون إنترنت (Offline Access) لمجموعة حسابات (آخر حسابين)
      await _biometricService.saveCredentials(
        email,
        password,
        role.toLowerCase(),
      );

      // بدء عملية المزامنة فور الدخول لتحديث البيانات المحلية
      try {
        final syncService = Get.find<BackgroundSyncService>();
        syncService.syncAll(silent: true);
      } catch (e) {
        // إذا لم تكن الخدمة مهيأة فلا مشكلة
      }

      _showResultDialog('login_success'.tr, true);
      Future.delayed(
        const Duration(seconds: 1),
        () => _redirectUser(role.toLowerCase()),
      );
    } on AuthException catch (e) {
      final errorMsg = _handleAuthError(e);
      if (errorMsg == 'network_error'.tr) {
        await _tryOfflineLoginFallback(email, password);
      } else {
        _showResultDialog(errorMsg, false);
      }
    } catch (e) {
      if (_isNetworkError(e)) {
        await _tryOfflineLoginFallback(email, password);
      } else {
        _showResultDialog(e.toString(), false);
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool _isNetworkError(dynamic e) {
    final str = e.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('clientexception') ||
        str.contains('handshakeexception') ||
        str.contains('connection terminated') ||
        str.contains('failed host lookup') ||
        str.contains('xmlhttprequest') ||
        str.contains('failed to connect') ||
        str.contains('network_error') ||
        str.contains('errno');
  }

  String _handleAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'invalid_credentials'.tr;
    }
    if (msg.contains('network') ||
        msg.contains('host lookup') ||
        msg.contains('handshake') ||
        msg.contains('connection') ||
        msg.contains('socket')) {
      return 'network_error'.tr;
    }
    if (msg.contains('user not found')) return 'user_not_found'.tr;
    if (msg.contains('too many requests')) return 'too_many_requests'.tr;
    if (msg.contains('invalid email')) return 'valid_email_error'.tr;
    return e.message;
  }

  void _showResultDialog(String message, bool isSuccess) {
    Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.redAccent,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (Get.isDialogOpen!) Get.back();
    });
  }

  Future<void> loginWithBiometrics() async {
    if (!isBiometricEnabled.value) return;

    final authenticated = await _biometricService.authenticate();
    if (!authenticated) return;

    final credentials = await _biometricService.getCredentials();
    if (credentials == null) {
      _showResultDialog('failed_retrieve_credentials'.tr, false);
      return;
    }

    emailController.text = credentials['email']!;
    passwordController.text = credentials['password']!;
    await login();
  }

  Future<void> _tryOfflineLoginFallback(
    String enteredEmail,
    String enteredPassword,
  ) async {
    // محاولة استرجاع الحساب من القائمة المحلية (تدعم آخر حسابين)
    final matchedAccount = await _biometricService.findAccount(
      enteredEmail,
      enteredPassword,
    );

    if (matchedAccount != null) {
      final String? role = matchedAccount['role'];
      if (role != null) {
        if (!_isPlatformAllowed(role)) return;

        // حفظ الدور الحالي في التفضيلات لضمان اتساق الواجهات
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', role.toLowerCase());

        _showResultDialog('offline_mode'.tr, true);
        _redirectUser(role);
        return;
      }
    }

    // إذا لم توجد بيانات أو لم تتطابق
    _showResultDialog('no_internet_msg'.tr, false);
  }

  void _redirectUser(String role) {
    switch (role) {
      case 'admin':
        Get.offAllNamed(AdminRoutes.adminHome);
        break;
      case 'teacher':
        Get.offAllNamed(TeacherRoutes.homepage);
        break;
      case 'student':
        Get.offAllNamed(StudentRoutes.studenthomepage);
        break;
      case 'coordinator':
        Get.offAllNamed('/coordinator/home');
        break;
      case 'examiner':
        Get.offAllNamed('/examiner_home');
        break;
      default:
        Get.offAllNamed(StudentRoutes.studenthomepage);
    }
  }

  Future<void> verifyUniqueCode() async {
    final input = registerEmailController.text.trim();
    final code = registerUniqueCodeController.text.trim();
    if (input.isEmpty || code.isEmpty) {
      _showResultDialog('enter_required_data'.tr, false);
      return;
    }
    isLoading.value = true;
    try {
      var response = await Supabase.instance.client
          .from('profiles')
          .select()
          .or('email.eq.$input,academic_number.eq.$input')
          .maybeSingle();
      response ??= await Supabase.instance.client
          .from('registration_requests')
          .select()
          .eq('email', input)
          .maybeSingle();

      // التاكد من حسابات الادمن في الويندوز او بشكل عام
      response ??= await Supabase.instance.client
          .from('admins')
          .select()
          .eq('email', input)
          .maybeSingle();

      if (response == null) {
        if (!input.contains('@')) {
          _showResultDialog('first_time_activation_email_required'.tr, false);
        } else {
          _showResultDialog('user_not_found'.tr, false);
        }
        return;
      }

      final dbCode =
          response['private_code']?.toString() ??
          response['special_code']?.toString();
      if (dbCode != code) {
        _showResultDialog('invalid_code'.tr, false);
        return;
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: response['email'],
        password: code,
      );

      resetPasswordController.clear();
      confirmPasswordController.clear();

      Get.toNamed(
        '/reset_password',
        arguments: {'email': response['email'], 'recordId': response['id']},
      );
    } on PostgrestException catch (e) {
      _showResultDialog(
        'حدث خطأ في قاعدة البيانات، يرجى المحاولة لاحقاً',
        false,
      );
    } catch (e) {
      _showResultDialog(
        _isNetworkError(e) ? 'network_error'.tr : 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً',
        false,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyFirstTimeUser() async {
    registerEmailController.text = emailController.text;
    registerUniqueCodeController.text = passwordController.text;
    await verifyUniqueCode();
  }

  Future<void> setNewPassword(String newPassword) async {
    final password = newPassword.trim();
    if (password.length < 6) {
      _showResultDialog('password_length_error'.tr, false);
      return;
    }
    isLoading.value = true;
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSetupComplete', true);
      _showResultDialog('password_updated_success'.tr, true);

      // تفريغ الحقول للأمان
      resetPasswordController.clear();
      confirmPasswordController.clear();
      passwordController.clear(); // مسح حقل كلمة السر الخاص بتسجيل الدخول

      Get.offAllNamed(AuthRoutes.login);
    } on AuthException catch (e) {
      if (e.code == 'same_password' || e.message.contains('different')) {
        _showResultDialog('كلمة المرور الجديدة مطابقة للكود الحالي. يرجى اختيار كلمة مرور مختلفة تماماً عن كود التفعيل.', false);
      } else {
        _showResultDialog(e.message, false);
      }
    } catch (e) {
      _showResultDialog(e.toString(), false);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> launchRegistrationWebsite() async {
    final Uri url = Uri.parse('https://almaqraalquraniahalalamiah.onrender.com/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showResultDialog('cannot_open_url'.tr, false);
    }
  }

  Future<void> forgotPassword(String email) async {
    if (email.isEmpty) {
      _showResultDialog('valid_email_error'.tr, false);
      return;
    }

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse(
          'https://almaqraalquraniahalalamiah.onrender.com/management/api/forgot-password/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // إغلاق نافذة الإدخال قبل إظهار نافذة النجاح
        if (Get.isDialogOpen!) Get.back();

        // إظهار رسالة النجاح مع البريد المشفر كما طلب المستخدم
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('success'.tr),
            content: Text(data['message'] ?? 'new_number_ben_email'.tr),
            actions: [
              TextButton(
                onPressed: () {
                  if (Get.isDialogOpen!) Get.back(); // إغلاق الدايالوج الحالي
                  Get.toNamed('/first_login'); // التوجه لشاشة التفعيل
                  emailController.text = email;
                },
                child: Text('ok'.tr),
              ),
            ],
          ),
        );
      } else {
        // إغلاق نافذة الإدخال قبل إظهار الخطأ ليكون المشهد أنظف، أو يمكن تركها
        if (Get.isDialogOpen!) Get.back();
        _showResultDialog(data['message'] ?? 'make_sure_account'.tr, false);
      }
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      _showResultDialog('network_error'.tr, false);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    registerEmailController.dispose();
    registerUniqueCodeController.dispose();
    resetPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
