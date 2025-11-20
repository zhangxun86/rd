import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_viewmodel.dart';
import '../../../../common/routes.dart';
import 'captcha_page.dart';
import '../../domain/services/captcha_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AuthViewModel _viewModel;
  late final FocusNode _codeFocusNode;
  StreamSubscription<AuthEvent>? _authEventSubscription;

  Timer? _timer;
  int _countdownSeconds = 60;
  bool _isCountingDown = false;

  @override
  void initState() {
    super.initState();
    _codeFocusNode = FocusNode();
    _viewModel = context.read<AuthViewModel>();
    _authEventSubscription = _viewModel.authEvents.listen(_handleAuthEvent);
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _timer?.cancel();
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
        if (_countdownSeconds > 1) {
          _countdownSeconds--;
        } else {
          _isCountingDown = false;
          timer.cancel();
        }
      });
    });
  }

  void _handleAuthEvent(AuthEvent event) {
    if (!mounted) return;

    if (ModalRoute.of(context)?.isCurrent != true) return;

    if (event == AuthEvent.resetPasswordSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('密码重置成功！正在返回登录页...'),
        backgroundColor: Colors.green,
      ));
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.of(context).pop();
      });

    } else if (event == AuthEvent.resetPasswordError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_viewModel.errorMessage ?? '重置密码失败'),
        backgroundColor: Colors.red,
      ));
    }
    else if (event == AuthEvent.smsCodeRequestSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('短信验证码已发送！'),
        backgroundColor: Colors.green,
      ));
      _startCountdown();
      _codeFocusNode.requestFocus();
    } else if (event == AuthEvent.smsCodeRequestError) {
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
      type: 'reset_pwd',
    );
  }

  void _onSetPassword() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthViewModel>().resetPassword(
        mobile: _mobileController.text.trim(),
        code: _codeController.text.trim(),
        pwd: _passwordController.text.trim(),
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
              title: const Text('忘记密码', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              backgroundColor: Colors.white,
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
                      const SizedBox(height: 60),
                      _buildTextField(controller: _mobileController, labelText: '手机号码', hintText: '请输入手机号码', keyboardType: TextInputType.phone),
                      const SizedBox(height: 20),
                      _buildTextField(controller: _passwordController, labelText: '新密码', hintText: '请输入6-30位新密码', isPassword: true),
                      const SizedBox(height: 20),
                      _buildCodeField(viewModel),
                      const SizedBox(height: 50),
                      ElevatedButton(
                        onPressed: isLoading ? null : _onSetPassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('设置密码', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        if (isPassword && (value.length < 6 || value.length > 30)) return '密码长度应为6-30位';
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
}