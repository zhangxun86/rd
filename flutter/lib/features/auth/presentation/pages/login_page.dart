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

  Timer? _timer;
  int _countdownSeconds = 60;
  bool _isCountingDown = false;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<AuthViewModel>();
    _viewModel.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    _viewModel.removeListener(_onAuthStateChanged);
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
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        setState(() => _isCountingDown = false);
      }
    });
  }

  void _onAuthStateChanged() {
    if (!mounted) return;

    if (_viewModel.event == AuthEvent.loginSuccess) {
      _viewModel.consumeEvent();
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else if (_viewModel.event == AuthEvent.loginError) {
      _viewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_viewModel.errorMessage ?? '登录失败'),
        backgroundColor: Colors.red,
      ));
    }
    else if (_viewModel.event == AuthEvent.smsCodeRequestSuccess) {
      _viewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('短信验证码已发送！'),
        backgroundColor: Colors.green,
      ));
      _startCountdown();
    } else if (_viewModel.event == AuthEvent.smsCodeRequestError) {
      _viewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_viewModel.smsErrorMessage ?? '获取验证码失败'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _onGetVerificationCode() async {
    if (_isCountingDown) return;

    final captchaService = CaptchaService(context);
    await captchaService.requestSmsCodeForMobile(
      _mobileController.text.trim(),
      type: 'login',
    );
  }

  void _onLogin() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先阅读并同意用户协议和隐私政策')));
      return;
    }
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthViewModel>().login(
        mobile: _mobileController.text.trim(),
        code: _codeController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    // This button already navigates to the register page.
                    Navigator.of(context).pushReplacementNamed(AppRoutes.register);
                  },
                  child: Text('账号注册', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
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
                      _buildCodeField(),
                      const SizedBox(height: 30),
                      _buildAgreementRow(),
                      const SizedBox(height: 30),
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

                      // --- START: ADDED WIDGET ---
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
                                  decoration: TextDecoration.underline, // Optional: add underline to look more like a link
                                ),
                                // Use a TapGestureRecognizer to make the text clickable
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Navigate to the register page
                                    Navigator.of(context).pushReplacementNamed(AppRoutes.register);
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // --- END: ADDED WIDGET ---
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

  Widget _buildCodeField() {
    return Selector<AuthViewModel, bool>(
      selector: (_, viewModel) => viewModel.isSendingSms,
      builder: (context, isSendingSms, _) {
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
                '$_countdownSeconds s',
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
      },
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