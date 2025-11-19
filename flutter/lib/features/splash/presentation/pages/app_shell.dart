import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../common/routes.dart';
import '../../../auth/presentation/provider/auth_viewmodel.dart';
import '../../../../mobile/pages/home_page.dart';
import '../../../auth/presentation/pages/password_login_page.dart';

// --- 新增：为了获取 VipRepository ---
import '../../../../di_container.dart';
import '../../../vip/domain/repositories/vip_repository.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // 标记初始化是否完成（隐私协议 + 登录检查 + 配置更新）
  bool _privacyCheckCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print("🔍 [AppShell] 正在初始化应用...");

    final prefs = await SharedPreferences.getInstance();
    final bool hasAgreed = prefs.getBool('has_agreed_privacy') ?? false;

    if (!hasAgreed) {
      print("🔍 [AppShell] 用户尚未同意隐私协议，显示弹窗");
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final bool? agreed = await _showPrivacyDialog();
        if (agreed == true) {
          await prefs.setBool('has_agreed_privacy', true);
          // 同意后，继续执行初始化
          await _completeInitialization();
        } else {
          SystemNavigator.pop();
        }
      });
    } else {
      print("🔍 [AppShell] 用户已同意隐私协议");
      // 已同意，直接执行初始化
      await _completeInitialization();
    }
  }

  /// 核心初始化逻辑：检查登录状态 -> (如果已登录) 更新服务器配置 -> 显示界面
  Future<void> _completeInitialization() async {
    if (!mounted) return;

    // 1. 检查登录状态
    print("🔍 [AppShell] 正在检查登录状态...");
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.checkInitialLoginState();
    print("🔍 [AppShell] 登录状态: ${authViewModel.isLoggedIn}");

    // 2. 如果已登录，尝试更新服务器配置 (/r_desk_config_data)
    if (authViewModel.isLoggedIn) {
      print("🚀 [AppShell] 用户已登录，开始调用 /r_desk_config_data 更新配置...");
      try {
        // 使用 getIt 获取 VipRepository 实例
        if (getIt.isRegistered<VipRepository>()) {
          final vipRepository = getIt<VipRepository>();
          await vipRepository.fetchAndApplyServerConfig();
          print("✅ [AppShell] 服务器配置更新成功！");
        } else {
          print("❌ [AppShell] 错误：VipRepository 未注册");
        }
      } catch (e) {
        // 捕获异常，防止因为网络问题导致进不去主页
        print("❌ [AppShell] 服务器配置更新失败: $e");
      }
    } else {
      print("⚠️ [AppShell] 用户未登录，跳过配置更新");
    }

    // 3. 标记完成，更新 UI
    if (mounted) {
      setState(() {
        _privacyCheckCompleted = true;
      });
      print("✅ [AppShell] 初始化流程结束，显示 UI");
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
    if (!_privacyCheckCompleted) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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