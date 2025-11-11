import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/password_login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../mobile/pages/home_page.dart';


class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String passwordLogin = '/password-login';
  static const String forgotPassword = '/forgot-password';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case passwordLogin:
        return MaterialPageRoute(builder: (_) => const PasswordLoginPage());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage()); // Default to login
    }
  }
}
