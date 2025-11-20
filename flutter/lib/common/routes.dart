import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/pages/webview_page.dart';
import 'package:flutter_hbb/mobile/pages/settings_page.dart';
import '../features/auth/presentation/pages/change_password_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/password_login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/feedback/presentation/pages/feedback_page.dart';
import '../features/profile/presentation/pages/about_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/vip/presentation/pages/vip_page.dart';
import '../mobile/pages/home_page.dart';


class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String passwordLogin = '/password-login';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String feedback = '/feedback';
  static const String vip = '/vip';
  static const String setting = '/setting';
  static const String webview = '/webview';
  static const String about = '/about';
  static const String changePassword = '/change-password';


  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    debugPrint("🔀 路由跳转请求: ${settings.name}");

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
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
      case profile: // <-- 3. Add case for new route
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case feedback:
        return MaterialPageRoute(builder: (_) => const FeedbackPage());
      case vip: // <-- 3. 添加处理新路由的 case
        return MaterialPageRoute(builder: (_) => const VipPage());
      case setting: // <-- 3. 添加处理新路由的 case
        return MaterialPageRoute(builder: (_) => SettingsPage());
      case about:
        return MaterialPageRoute(builder: (_) => const AboutPage());
      case changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordPage());
      case webview:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => WebViewPage(
            url: args['url']!,
            title: args['title'] ?? '详情',
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("路由错误")),
          body: Center(
            child: Text("错误：找不到路由 '${settings.name}'"),
          ),
        ));
    }
  }
}
