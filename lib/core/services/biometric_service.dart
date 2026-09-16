import 'dart:convert';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class BiometricService {
  static const String _biometricEnabledKey = 'isBiometricEnabled';
  static const String _savedAccountsKey = 'saved_accounts_list';

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> isDeviceSupported() async {
    return await _auth.isDeviceSupported();
  }

  Future<bool> canAuthenticate() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasEnrolledBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics = await _auth
          .getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      if (!await hasEnrolledBiometrics()) return false;
      return await _auth.authenticate(
        localizedReason: 'biometric_reason'.tr,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// حفظ بيانات الحساب (البريد، كلمة المرور، الدور) لدعم الدخول بدون إنترنت
  /// يحفظ آخر حسابين فقط ويقوم بتحديث ترتيبهم تلقائياً
  Future<void> saveCredentials(
    String email,
    String password,
    String role,
  ) async {
    try {
      List<Map<String, dynamic>> accounts = await _getSavedAccountsList();

      // إزالة الحساب إذا كان موجوداً مسبقاً لمنع التكرار وتحديثه للواجهة
      accounts.removeWhere((acc) => acc['email'] == email);

      // إضافة الحساب الجديد في بداية القائمة
      accounts.insert(0, {
        'email': email,
        'password': password,
        'role': role,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // الاحتفاظ بآخر حسابين فقط كما طلب المستخدم
      if (accounts.length > 2) {
        accounts = accounts.sublist(0, 2);
      }

      await _secureStorage.write(
        key: _savedAccountsKey,
        value: jsonEncode(accounts),
      );

      // للمحافظة على التوافق مع الكود القديم الذي قد يعتمد على المفاتيح الفردية
      await _secureStorage.write(key: 'bio_email', value: email);
      await _secureStorage.write(key: 'bio_password', value: password);
    } catch (e) {
      // تجاهل أخطاء التخزين
    }
  }

  /// البحث عن حساب محلي يطابق البيانات المدخلة
  Future<Map<String, String>?> findAccount(
    String email,
    String password,
  ) async {
    try {
      List<Map<String, dynamic>> accounts = await _getSavedAccountsList();

      for (var acc in accounts) {
        if (acc['email'] == email && acc['password'] == password) {
          return {
            'email': acc['email'].toString(),
            'password': acc['password'].toString(),
            'role': acc['role']?.toString() ?? 'student',
          };
        }
      }
    } catch (e) {
      // خطأ في القراءة
    }
    return null;
  }

  /// استرجاع آخر حساب تم استخدامه (للتعبئة التلقائية مثلاً)
  Future<Map<String, String>?> getCredentials() async {
    try {
      List<Map<String, dynamic>> accounts = await _getSavedAccountsList();
      if (accounts.isNotEmpty) {
        return {
          'email': accounts[0]['email'].toString(),
          'password': accounts[0]['password'].toString(),
          'role': accounts[0]['role']?.toString() ?? 'student',
        };
      }

      // محاولة استرجاع من النظام القديم إذا كانت القائمة فارغة
      final oldEmail = await _secureStorage.read(key: 'bio_email');
      final oldPassword = await _secureStorage.read(key: 'bio_password');
      if (oldEmail != null && oldPassword != null) {
        return {'email': oldEmail, 'password': oldPassword};
      }
    } catch (e) {
      // خطأ
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getSavedAccountsList() async {
    try {
      final jsonStr = await _secureStorage.read(key: _savedAccountsKey);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      // في حالة وجود خطأ في JSON نقوم بتصفير البيانات
      await _secureStorage.delete(key: _savedAccountsKey);
    }
    return [];
  }

  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _savedAccountsKey);
    await _secureStorage.delete(key: 'bio_email');
    await _secureStorage.delete(key: 'bio_password');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
  }
}
