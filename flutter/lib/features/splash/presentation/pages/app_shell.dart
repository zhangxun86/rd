import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common/app_urls.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../common/routes.dart';
import '../../../auth/presentation/provider/auth_viewmodel.dart';
import '../../../../mobile/pages/home_page.dart';
import '../../../auth/presentation/pages/password_login_page.dart';

import '../../../../di_container.dart';
import '../../../vip/domain/repositories/vip_repository.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
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
          await _completeInitialization();
        } else {
          SystemNavigator.pop();
        }
      });
    } else {
      print("🔍 [AppShell] 用户已同意隐私协议");
      await _completeInitialization();
    }
  }

  Future<void> _completeInitialization() async {
    if (!mounted) return;

    print("🔍 [AppShell] 正在检查登录状态...");
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.checkInitialLoginState();
    print("🔍 [AppShell] 登录状态: ${authViewModel.isLoggedIn}");

    if (authViewModel.isLoggedIn) {
      print("🚀 [AppShell] 用户已登录，开始调用 /r_desk_config_data 更新配置...");
      try {
        if (getIt.isRegistered<VipRepository>()) {
          final vipRepository = getIt<VipRepository>();
          await vipRepository.fetchAndApplyServerConfig();
          print("✅ [AppShell] 服务器配置更新成功！");
        } else {
          print("❌ [AppShell] 错误：VipRepository 未注册");
        }
      } catch (e) {
        print("❌ [AppShell] 服务器配置更新失败: $e");
      }
    } else {
      print("⚠️ [AppShell] 用户未登录，跳过配置更新");
    }

    if (mounted) {
      setState(() {
        _privacyCheckCompleted = true;
      });
      print("✅ [AppShell] 初始化流程结束，显示 UI");
    }
  }

  /// 显示隐私协议弹窗 (根据图片样式重写)
  Future<bool?> _showPrivacyDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 用户必须做出选择
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // 确保背景是纯白
          surfaceTintColor: Colors.white, // 去除 Material 3 的默认底色
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 圆角弹窗
          titlePadding: const EdgeInsets.only(top: 24, bottom: 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.all(24), // 按钮区域的内边距

          // 1. 标题
          title: const Text(
            '服务协议和隐私政策',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87
            ),
          ),

          // 2. 内容文本
          content: SingleChildScrollView(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                    color: Color(0xFF333333), // 深灰色字体
                    fontSize: 14,
                    height: 1.6 // 增加行高，提升可读性
                ),
                children: [
                  const TextSpan(text: '感谢您对本公司的支持!本公司非常重视您的个人信息和隐私保护，为了更好的保障您的个人权益,请在使用我们的产品前,请务必审慎阅读'),
                  TextSpan(
                    text: '《用户协议》',
                    style: const TextStyle(color: Color(0xFF3B7CFF), fontWeight: FontWeight.w500), // 蓝色链接
                    recognizer: TapGestureRecognizer()..onTap = () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.webview,
                        arguments: {'title': '用户协议', 'url': AppUrls.userAgreement},
                      );
                    },
                  ),
                  const TextSpan(text: ' 和 '),
                  TextSpan(
                    text: '《隐私政策》',
                    style: const TextStyle(color: Color(0xFF3B7CFF), fontWeight: FontWeight.w500), // 蓝色链接
                    recognizer: TapGestureRecognizer()..onTap = () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.webview,
                        arguments: {'title': '隐私政策', 'url': AppUrls.privacyPolicy},
                      );
                    },
                  ),
                  const TextSpan(text: ' 内的所有条款,您点击“同意”的行为即表示您已阅读完毕并同意以上协议的全部内容。如您同意以上协议内容,请点击“同意”,开始使用我们的产品和服务。'),
                ],
              ),
            ),
          ),

          // 3. 底部按钮区域
          actions: [
            Row(
              children: [
                // 左侧按钮：我在想想
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF0F0F0), // 浅灰色背景
                      foregroundColor: const Color(0xFF666666), // 深灰色文字
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25), // 胶囊形状
                      ),
                    ),
                    child: const Text(
                      '我再想想',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 16), // 两个按钮之间的间距

                // 右侧按钮：同意并继续
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B7CFF), // 蓝色背景
                      foregroundColor: Colors.white, // 白色文字
                      elevation: 0, // 去除阴影
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25), // 胶囊形状
                      ),
                    ),
                    child: const Text(
                      '同意并继续',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_privacyCheckCompleted) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
              // 确保 assets/images/vip_bg.png 在 pubspec.yaml 中已定义
              image: AssetImage('assets/images/splash_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            // 使用 SafeArea 确保底部内容不被系统导航条遮挡
            child: Column(
              children: [
                // 使用 Spacer 占据上方空间，将内容推到底部
                const Spacer(),

                // --- 底部内容区域 ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 60.0), // 距离底部的一些间距
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App 图标
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18), // 稍微减小圆角
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 80, // 稍微调小尺寸适应底部布局
                          height: 80,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.app_shortcut,
                              size: 80,
                              color: Colors.blueAccent
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                    ],
                  ),
                ),
              ],
            ),
          ),
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