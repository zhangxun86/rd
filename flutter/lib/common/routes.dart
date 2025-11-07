import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/register_page.dart';

class AppRoutes {
  static const String register = '/register';
  static const String home = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage()); // Placeholder
      default:
        return MaterialPageRoute(builder: (_) => const RegisterPage()); // Default to register
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Welcome! Registration Successful!")),
    );
  }
}