import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../common/routes.dart';
import '../../../auth/presentation/provider/auth_viewmodel.dart';
import '../../../../mobile/pages/home_page.dart'; // RustDesk's original HomePage
import '../../../auth/presentation/pages/password_login_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // A flag to track if the initial privacy check is complete.
  bool _privacyCheckCompleted = false;

  @override
  void initState() {
    super.initState();
    // Start the initialization process as soon as the widget is created.
    _initializeApp();
  }

  /// Handles the entire app startup logic: privacy check and initial login status check.
  Future<void> _initializeApp() async {
    // 1. Check if the user has previously agreed to the privacy policy.
    final prefs = await SharedPreferences.getInstance();
    final bool hasAgreed = prefs.getBool('has_agreed_privacy') ?? false;

    if (!hasAgreed) {
      // If not, show the privacy dialog.
      // We use `addPostFrameCallback` to ensure the dialog is shown after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final bool? agreed = await _showPrivacyDialog();
        if (agreed == true) {
          // If they agree, save the preference and then proceed to check login status.
          await prefs.setBool('has_agreed_privacy', true);
          _completeInitialization();
        } else {
          // If they disagree, exit the app.
          SystemNavigator.pop();
        }
      });
    } else {
      // If they have already agreed, proceed directly.
      _completeInitialization();
    }
  }

  /// Finalizes initialization by checking login state and updating the UI.
  void _completeInitialization() {
    if (mounted) {
      // Tell the AuthViewModel to check the initial login state from storage.
      context.read<AuthViewModel>().checkInitialLoginState();
      // Mark the privacy check as complete to switch from the loading screen.
      setState(() {
        _privacyCheckCompleted = true;
      });
    }
  }

  /// Displays the modal dialog for the privacy policy and user agreement.
  Future<bool?> _showPrivacyDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must make a choice.
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '服务协议与隐私政策授权信息',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(text: '感谢您使用本应用\n为了更好地保障您的个人权益，请认真阅读'),
                    TextSpan(
                      text: '《用户协议》',
                      style: const TextStyle(color: Colors.cyan),
                      recognizer: TapGestureRecognizer()..onTap = () { /* TODO: Show User Agreement */ },
                    ),
                    const TextSpan(text: '和'),
                    TextSpan(
                      text: '《隐私政策》',
                      style: const TextStyle(color: Colors.cyan),
                      recognizer: TapGestureRecognizer()..onTap = () { /* TODO: Show Privacy Policy */ },
                    ),
                    const TextSpan(text: '的全部内容。点击“同意“即表示您已阅读并同意全部条款。若选择不同意，将无法使用我们的产品和服务，并退出应用。'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // "Agree" Button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('同意', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              // "Disagree" Button
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('不同意并退出APP', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // While the privacy check is in progress, show a loading indicator.
    if (!_privacyCheckCompleted) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // After the privacy check, use a Consumer to reactively switch between
    // the authenticated and unauthenticated states.
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (authViewModel.isLoggedIn) {
          // If the user is logged in, show the original HomePage from RustDesk.
          return HomePage();
        } else {
          // If the user is not logged in, show the authentication flow.
          // We use a Navigator to manage the auth pages (login, register, etc.).
          return Navigator(
            key: const ValueKey('AuthNavigator'), // A key helps Flutter distinguish this navigator
            initialRoute: AppRoutes.login, // The entry point for the auth flow
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        }
      },
    );
  }
}