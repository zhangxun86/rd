import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../common/app_urls.dart';
import '../provider/auth_viewmodel.dart';
import '../../../../common/routes.dart';
import 'captcha_page.dart';
import '../../domain/services/captcha_service.dart';
// 确保这个路径指向您的 OneClickLoginManager 文件
import '../../../../core/services/one_click_login_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- 状态变量 ---
  final _mobileController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false; // 登录页默认勾选

  late final AuthViewModel _viewModel;
  late final FocusNode _codeFocusNode;

  // --- 核心修复：使用 StreamSubscription ---
  StreamSubscription<AuthEvent>? _authEventSubscription;

  // 倒计时状态
  Timer? _timer;
  int _countdownSeconds = 60;
  bool _isCountingDown = false;

  // UI防抖
  DateTime _lastSnackBarTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _codeFocusNode = FocusNode();
    _viewModel = context.read<AuthViewModel>();

    // --- 核心修复：订阅 ViewModel 的事件流 ---
    _authEventSubscription = _viewModel.authEvents.listen(_handleAuthEvent);

    // 初始化一键登录 SDK
    //OneClickLoginManager.init();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _timer?.cancel();

    // --- 核心修复：取消订阅，防止内存泄漏 ---
    _authEventSubscription?.cancel();

    super.dispose();
  }

  /// 处理来自 ViewModel 的流事件
  void _handleAuthEvent(AuthEvent event) {
    if (!mounted) return;

    // UI层物理防抖 (防止 SnackBar 刷屏)
    final now = DateTime.now();
    if (now.difference(_lastSnackBarTime) < const Duration(milliseconds: 500)) {
      return;
    }

    // --- 登录成功 (验证码登录 或 一键登录) ---
    if (event == AuthEvent.loginWithCodeSuccess ||
        event == AuthEvent.oneClickLoginSuccess) {
      _lastSnackBarTime = now;
      // 跳转主页
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }

    // --- 登录失败 ---
    else if (event == AuthEvent.loginWithCodeError ||
        event == AuthEvent.oneClickLoginError) {
      _lastSnackBarTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_viewModel.errorMessage ?? '登录失败'),
        backgroundColor: Colors.red,
      ));
    }

    // --- 验证码发送成功 ---
    else if (event == AuthEvent.smsCodeRequestSuccess) {
      _lastSnackBarTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('短信验证码已发送！'),
        backgroundColor: Colors.green,
      ));
      _startCountdown(); // 启动倒计时
      _codeFocusNode.requestFocus(); // 自动聚焦
    }

    // --- 验证码发送失败 ---
    else if (event == AuthEvent.smsCodeRequestError) {
      _lastSnackBarTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_viewModel.smsErrorMessage ?? '获取验证码失败'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _startCountdown() {
    if (_isCountingDown) return;

    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
        });
      }
    });
  }

  Future<void> _onGetVerificationCode() async {
    if (_isCountingDown || _viewModel.isSendingSms) return;

    FocusScope.of(context).unfocus();
    if (_mobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先输入手机号码')));
      return;
    }

    // 弹出验证码页面
    final captchaResult = await Navigator.of(context).push<String?>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const CaptchaPage(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );

    if (captchaResult != null && captchaResult.isNotEmpty) {
      // 调用 ViewModel 请求短信 (ViewModel 会发送事件)
      await _viewModel.requestSmsCode(
        mobile: _mobileController.text.trim(),
        aliCaptchaParam: captchaResult,
        type: 'login', // 指定类型为登录
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('滑动验证已取消'),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  void _onLogin() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先阅读并同意用户协议和隐私政策')));
      return;
    }
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      // 调用验证码登录
      _viewModel.login(
        mobile: _mobileController.text.trim(),
        code: _codeController.text.trim(),
      );
    }
  }

  // --- 一键登录逻辑 ---
  void _onOneClickLogin() {
    /*if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先阅读并同意用户协议和隐私政策')));
      return;
    }*/

    OneClickLoginManager.login(
      onSuccess: (token, verifyId) {
        // SDK 成功后，调用 ViewModel 进行后端验证
        _viewModel.loginWithOneClick(umToken: token, umVerifyId: verifyId);
      },
      onFailure: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('一键登录失败: $msg，请使用验证码登录'),
          backgroundColor: Colors.orange,
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 监听状态 (loading, etc.)
    return Consumer<AuthViewModel>(
        builder: (context, viewModel, child) {
          final isLoading = viewModel.state == AuthState.loading;

          return Scaffold(
            appBar: AppBar(
              title: const Text('验证码登录', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: const BackButton(color: Colors.black),
              foregroundColor: Colors.black,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.passwordLogin);
                  },
                  child: Text('密码登录', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ),
                const SizedBox(width: 8),
              ],
            ),
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      _buildTextField(controller: _mobileController, labelText: '手机号码', hintText: '请输入手机号码', keyboardType: TextInputType.phone),
                      const SizedBox(height: 20),
                      _buildCodeField(viewModel),
                      const SizedBox(height: 30),
                      _buildAgreementRow(),
                      const SizedBox(height: 30),

                      // --- 登录按钮 ---
                      ElevatedButton(
                        onPressed: isLoading ? null : _onLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF87ADFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),

                      // --- 一键登录按钮 ---
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: isLoading ? null : _onOneClickLogin,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF87ADFF)),
                          foregroundColor: const Color(0xFF87ADFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('本机号码一键登录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),

                      // --- 去注册跳转 ---
                      const SizedBox(height: 24),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: '没有账号？ ',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            children: [
                              TextSpan(
                                text: '去注册',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).pushReplacementNamed(AppRoutes.register);
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String labelText, required String hintText, bool isPassword = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.normal),
        floatingLabelStyle: const TextStyle(color: Colors.blueAccent),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '此项不能为空';
        return null;
      },
    );
  }

  Widget _buildCodeField(AuthViewModel viewModel) {
    final isSendingSms = viewModel.isSendingSms;
    return TextFormField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      focusNode: _codeFocusNode,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
      decoration: InputDecoration(
        labelText: '验证码',
        labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.normal),
        floatingLabelStyle: const TextStyle(color: Colors.blueAccent),
        hintText: '请输入验证码',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        suffixIcon: isSendingSms
            ? const Padding(
          padding: EdgeInsets.all(14.0),
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
        )
            : (_isCountingDown
            ? Container(
          width: 80,
          alignment: Alignment.center,
          padding: const EdgeInsets.only(right: 12.0),
          child: Text(
            '${_countdownSeconds}s',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        )
            : TextButton(
          onPressed: _onGetVerificationCode,
          child: const Text('获取验证码', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        )
        ),
      ),
      validator: (value) => (value == null || value.isEmpty) ? '此项不能为空' : null,
    );
  }

  Widget _buildAgreementRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: Colors.blueAccent,
            checkColor: Colors.white,
            side: MaterialStateBorderSide.resolveWith((states) {
              if (states.contains(MaterialState.selected)) return const BorderSide(color: Colors.blueAccent, width: 2.0);
              return BorderSide(color: Colors.grey.shade400, width: 2.0);
            }),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '我已阅读并同意 ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              children: [
                TextSpan(text: '《用户协议》', style: const TextStyle(color: Colors.blueAccent), recognizer: TapGestureRecognizer()..onTap = () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.webview,
                    arguments: {'title': '用户协议', 'url': AppUrls.userAgreement},
                  );
                }),
                const TextSpan(text: ' 和 '),
                TextSpan(text: '《隐私政策》', style: const TextStyle(color: Colors.blueAccent), recognizer: TapGestureRecognizer()..onTap = () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.webview,
                    arguments: {'title': '隐私政策', 'url': AppUrls.privacyPolicy},
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}