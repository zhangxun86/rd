import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../common/routes.dart';
import '../../../../di_container.dart'; // 需要导入 getIt
import '../../../../mobile/pages/home_page.dart'; // 导入 RustDesk 的主页
import '../../../auth/presentation/pages/login_page.dart'; // 导入登录页
import '../../../auth/presentation/provider/auth_viewmodel.dart'; // 导入 AuthViewModel
import '../../../vip/domain/repositories/vip_repository.dart'; // 导入 VipRepository

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const String _privacyAgreedKey = 'has_agreed_privacy';

  // --- 1. 定义状态变量 ---
  // 这个变量控制是否显示加载圈。当隐私协议检查完成且登录状态检查完成后，设为 true。
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasAgreed = prefs.getBool(_privacyAgreedKey) ?? false;

    if (!hasAgreed) {
      final bool? agreed = await _showPrivacyDialog();
      if (agreed == true) {
        await prefs.setBool(_privacyAgreedKey, true);
        await _checkLoginAndConfig();
      } else {
        SystemNavigator.pop();
      }
    } else {
      await _checkLoginAndConfig();
    }
  }

  Future<void> _checkLoginAndConfig() async {
    if (!mounted) return;

    print("🔍 [SplashPage] 开始检查登录状态...");

    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.checkInitialLoginState();

    print("🔍 [SplashPage] 登录状态: ${authViewModel.isLoggedIn}");

    if (authViewModel.isLoggedIn) {
      print("🚀 [SplashPage] 用户已登录，正在更新服务器配置...");
      try {
        final vipRepository = getIt<VipRepository>();
        await vipRepository.fetchAndApplyServerConfig();
        print("✅ [SplashPage] 服务器配置更新成功");
      } catch (e) {
        print("❌ [SplashPage] 服务器配置更新失败 (不影响进入主页): $e");
      }
    } else {
      print("⚠️ [SplashPage] 用户未登录，跳过配置更新");
    }

    if (mounted) {
      setState(() {
        // --- 2. 这里使用正确的变量名 _isInitialized ---
        _isInitialized = true;
      });
    }
  }

  Future<bool?> _showPrivacyDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
                      recognizer: TapGestureRecognizer()..onTap = () { /* TODO */ },
                    ),
                    const TextSpan(text: '和'),
                    TextSpan(
                      text: '《隐私政策》',
                      style: const TextStyle(color: Colors.cyan),
                      recognizer: TapGestureRecognizer()..onTap = () { /* TODO */ },
                    ),
                    const TextSpan(text: '的全部内容。点击“同意“即表示您已阅读并同意全部条款。若选择不同意，将无法使用我们的产品和服务，并退出应用。'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
    // --- 3. 使用 _isInitialized 判断是否显示加载圈 ---
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (authViewModel.isLoggedIn) {
          return HomePage();
        } else {
          return Navigator(
            key: const ValueKey('AuthNavigator'),
            initialRoute: AppRoutes.login,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        }
      },
    );
  }
}