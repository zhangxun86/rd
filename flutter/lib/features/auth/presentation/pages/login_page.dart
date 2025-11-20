import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_viewmodel.dart';
import '../../../../common/routes.dart';
import 'captcha_page.dart';
import '../../domain/services/captcha_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _mobileController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = true;

  late final AuthViewModel _viewModel;
  late final FocusNode _codeFocusNode;

  StreamSubscription<AuthEvent>? _authEventSubscription;

  Timer? _timer;
  int _countdownSeconds = 60;
  bool _isCountingDown = false;

  // --- UI层防抖变量 ---
  DateTime _lastSnackBarTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _codeFocusNode = FocusNode();
    _viewModel = context.read<AuthViewModel>();

    // 确保先取消可能存在的订阅（虽然init里通常没有）
    _authEventSubscription?.cancel();
    _authEventSubscription = _viewModel.authEvents.listen(_handleAuthEvent);
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _timer?.cancel();
    // 必须取消订阅，否则会造成内存泄漏和重复监听
    _authEventSubscription?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (!mounted || _isCountingDown) return;
    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          timer.cancel();
          _isCountingDown = false;
        }
      });
    });
  }

  void _handleAuthEvent(AuthEvent event) {
    if (!mounted) return;

    // --- 1. 检查页面可见性 ---
    // 如果当前页面不在栈顶（例如已经跳到别的页面了），不处理事件
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrent) return;

    // --- 2. UI层物理防抖 ---
    // 强制限制 SnackBar 的弹出频率。如果距离上次弹出不到 500ms，直接忽略本次事件。
    final now = DateTime.now();
    if (now.difference(_lastSnackBarTime) < const Duration(milliseconds: 500)) {
      return;
    }

    // 处理登录成功
    if (event == AuthEvent.loginWithCodeSuccess) {
      // 记录时间，避免重复
      _lastSnackBarTime = now;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
    // 处理登录失败
    else if (event == AuthEvent.loginWithCodeError) {
      _lastSnackBarTime = now;
      // 使用 removeCurrentSnackBar 立即清除旧的，避免堆叠
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_viewModel.errorMessage ?? '登录失败'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2), // 设置较短的持续时间
      ));
    }
    // 处理验证码发送成功
    else if (event == AuthEvent.smsCodeRequestSuccess) {
      _lastSnackBarTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('短信验证码已发送！'),
        backgroundColor: Colors.green,
      ));
      _startCountdown();
      _codeFocusNode.requestFocus();
    }
    // 处理验证码发送失败
    else if (event == AuthEvent.smsCodeRequestError) {
      _lastSnackBarTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_viewModel.smsErrorMessage ?? '获取验证码失败'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _onGetVerificationCode() async {
    if (_isCountingDown) return;

    FocusScope.of(context).unfocus();
    if (_mobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先输入手机号码')));
      return;
    }

    final captchaResult = await Navigator.of(context).push<String?>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const CaptchaPage(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );

    if (captchaResult != null && captchaResult.isNotEmpty) {
      await _viewModel.requestSmsCode(
        mobile: _mobileController.text.trim(),
        aliCaptchaParam: captchaResult,
        type: 'login',
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
      _viewModel.login(
        mobile: _mobileController.text.trim(),
        code: _codeController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 监听加载状态，但不处理事件（事件由 Stream 处理）
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
                      ElevatedButton(
                        onPressed: isLoading ? null : _onLogin,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                            if (states.contains(MaterialState.disabled)) {
                              return const Color(0xFFB4CDF8);
                            }
                            return const Color(0xFF2979FF);
                          }),
                          foregroundColor: MaterialStateProperty.all(Colors.white),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                          elevation: MaterialStateProperty.all(0),
                          overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.2)),
                        ),
                        child: isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
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
        suffixIcon: _buildSuffixIcon(isSendingSms, viewModel),
      ),
      validator: (value) => (value == null || value.isEmpty) ? '此项不能为空' : null,
    );
  }

  Widget _buildSuffixIcon(bool isSendingSms, AuthViewModel viewModel) {
    if (isSendingSms) {
      return const Padding(
        padding: EdgeInsets.all(14.0),
        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    } else if (_isCountingDown) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          widthFactor: 1.0,
          child: Text(
            '${_countdownSeconds}s',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      return TextButton(
        onPressed: _onGetVerificationCode,
        child: const Text('获取验证码', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
      );
    }
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
                TextSpan(text: '《用户协议》', style: const TextStyle(color: Colors.blueAccent), recognizer: TapGestureRecognizer()..onTap = () {}),
                const TextSpan(text: ' 和 '),
                TextSpan(text: '《隐私政策》', style: const TextStyle(color: Colors.blueAccent), recognizer: TapGestureRecognizer()..onTap = () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }
}