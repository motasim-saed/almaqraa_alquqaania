
import 'package:get/get.dart';
import '../pages/login/login_screen.dart';
import '../pages/first_login_screen.dart';
import '../pages/forgot_password/reset_password.dart';
import '../binding/auth_binding.dart';

class AuthRoutes {
  static const String login = '/login';
  static const String verifyIdentity = '/verify_identity';
  static const String resetPassword = '/reset_password';

  static final List<GetPage> routes = [
    GetPage(name: login, page: () => LoginScreen(), binding: AuthBinding()),
    GetPage(
      name: '/first_login',
      page: () => FirstLoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: resetPassword,
      page: () => ResetPassword(),
      binding: AuthBinding(),
    ),
  ];
}
