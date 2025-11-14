import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../common/routes.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const String _privacyAgreedKey = 'has_agreed_privacy';

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the context is available for dialogs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrivacyAndNavigate();
    });
  }

  Future<void> _checkPrivacyAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasAgreed = prefs.getBool(_privacyAgreedKey) ?? false;

    if (!hasAgreed) {
      // If the user hasn't agreed, show the privacy dialog.
      final bool? agreed = await _showPrivacyDialog();
      if (agreed == true) {
        // If they agree, save the preference and proceed.
        await prefs.setBool(_privacyAgreedKey, true);
        _checkLoginStatusAndNavigate();
      } else {
        // If they disagree, exit the app.
        SystemNavigator.pop();
      }
    } else {
      // If they have already agreed, proceed directly.
      _checkLoginStatusAndNavigate();
    }
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    // Use context.read as we are in a callback.
    final authRepository = context.read<AuthRepository>();
    final token = await authRepository.getToken();

    if (mounted) {
      if (token != null && token.isNotEmpty) {
        // User is logged in, go to home page.
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        // User is not logged in, go to login page.
        Navigator.of(context).pushReplacementNamed(AppRoutes.passwordLogin);
      }
    }
  }

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
                    const TextSpan(text: '感谢您使用畅信\n为了更好地保障您的个人权益，请认真阅读'),
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
                    const TextSpan(text: '的全部内容，为向你提供特定服务和功能，在使用过程中我们可能会获取您的设备信息、位置信息、存储权限等个人信息。点击“同意“即表示您已阅读并同意全部条款。若选择不同意，将无法使用我们的产品和服务，并退出应用。'),
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
    // The splash page can be a simple loading indicator or a branded screen.
    return const Scaffold(
      body: Center(
        // You can put your app logo here
        child: CircularProgressIndicator(),
      ),
    );
  }
}