import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_viewmodel.dart';
import '../../../../common/routes.dart';
import 'captcha_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- State variables ---
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;

  // Countdown timer state
  Timer? _timer;
  int _countdownSeconds = 60;
  bool _isCountingDown = false;

  @override
  void initState() {
    super.initState();
    // We can still listen for major events like successful registration for navigation.
    // The listen method is simplified to just use context.read.
    final viewModel = context.read<AuthViewModel>();
    viewModel.addListener(() {
      if (viewModel.event == AuthEvent.registrationSuccess) {
        viewModel.consumeEvent();
        if (mounted) Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else if (viewModel.event == AuthEvent.registrationError) {
        viewModel.consumeEvent();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(viewModel.errorMessage ?? '注册失败'),
            backgroundColor: Colors.red,
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    // We don't need to remove the listener if it's created inline with context.read,
    // but doing so is a good practice if the ViewModel outlives the page.
    // context.read<AuthViewModel>().removeListener(...);
    super.dispose();
  }

  void _startCountdown() {
    if (_isCountingDown) return;

    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 60;
    });

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

  Future<void> _onGetVerificationCode(AuthViewModel viewModel) async {
    if (_isCountingDown || viewModel.isSendingSms) return;

    FocusScope.of(context).unfocus();
    if (_mobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先输入手机号码')));
      return;
    }

    final captchaResult = await Navigator.of(context).push<String?>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => const CaptchaPage(),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );

    if (captchaResult != null && captchaResult.isNotEmpty) {
      // Call the ViewModel and await the boolean result.
      final success = await viewModel.requestSmsCode(
        mobile: _mobileController.text.trim(),
        aliCaptchaParam: captchaResult,
        type: 'reg',
      );

      // --- THE FIX ---
      // If the API call was successful, start the countdown and show success message directly.
      if (success && mounted) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('短信验证码已发送！'),
          backgroundColor: Colors.green,
        ));
      } else if (!success && mounted) {
        // If it failed, show the specific error message for the SMS request.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(viewModel.smsErrorMessage ?? '获取验证码失败'),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('滑动验证已取消'),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  void _onRegister(AuthViewModel viewModel) {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先阅读并同意用户协议和隐私政策')));
      return;
    }
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      viewModel.register(
        mobile: _mobileController.text.trim(),
        code: _codeController.text.trim(),
        pwd: _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use `context.watch` to rebuild when loading states change.
    final viewModel = context.watch<AuthViewModel>();
    final isRegistering = viewModel.state == AuthState.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号注册'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        foregroundColor: Colors.black,
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
                const SizedBox(height: 40),
                _buildTextField(controller: _mobileController, labelText: '手机号码', hintText: '请输入手机号码', keyboardType: TextInputType.phone),
                const SizedBox(height: 20),
                _buildTextField(controller: _passwordController, labelText: '密码', hintText: '请输入密码', isPassword: true),
                const SizedBox(height: 20),
                _buildCodeField(viewModel),
                const SizedBox(height: 30),
                _buildAgreementRow(),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isRegistering ? null : () => _onRegister(viewModel),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: isRegistering
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('注册并登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
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
        if (isPassword && (value.length < 6 || value.length > 30)) return '密码长度应为6-30位';
        return null;
      },
    );
  }

  Widget _buildCodeField(AuthViewModel viewModel) {
    // Use `context.watch` to only rebuild this widget when `isSendingSms` changes.
    final isSendingSms = context.watch<AuthViewModel>().isSendingSms;

    return TextFormField(
      controller: _codeController,
      keyboardType: TextInputType.number,
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
        onPressed: () => _onGetVerificationCode(viewModel),
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