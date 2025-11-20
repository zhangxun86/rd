import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_viewmodel.dart';
import '../../../../common/routes.dart';
import 'captcha_page.dart';
import '../../domain/services/captcha_service.dart';
import '../../../profile/presentation/provider/profile_viewmodel.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AuthViewModel _authViewModel;
  late final FocusNode _codeFocusNode;

  Timer? _timer;
  int _countdownSeconds = 60;
  bool _isCountingDown = false;

  @override
  void initState() {
    super.initState();
    _codeFocusNode = FocusNode();
    _authViewModel = context.read<AuthViewModel>();
    _authViewModel.addListener(_onAuthStateChanged);

    // Auto-fill mobile from ProfileViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileViewModel = context.read<ProfileViewModel>();
      if (profileViewModel.userProfile != null) {
        _mobileController.text = profileViewModel.userProfile!.mobile;
      } else {
        profileViewModel.fetchUserProfile();
      }
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _timer?.cancel();
    _authViewModel.removeListener(_onAuthStateChanged);
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

  void _onAuthStateChanged() {
    if (!mounted) return;

    if (_authViewModel.event == AuthEvent.resetPasswordSuccess) {
      _authViewModel.consumeEvent();

      // --- START: MODIFICATION ---
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('密码修改成功！'),
        backgroundColor: Colors.green,
      ));

      // Close the page after a short delay, WITHOUT logging out
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // Simply pop the current page to return to SettingsPage
          Navigator.of(context).pop();
        }
      });
      // --- END: MODIFICATION ---

    } else if (_authViewModel.event == AuthEvent.resetPasswordError) {
      _authViewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_authViewModel.errorMessage ?? '修改失败'),
        backgroundColor: Colors.red,
      ));
    }
    else if (_authViewModel.event == AuthEvent.smsCodeRequestSuccess) {
      _authViewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('短信验证码已发送！'),
        backgroundColor: Colors.green,
      ));
      _startCountdown();
      _codeFocusNode.requestFocus();
    } else if (_authViewModel.event == AuthEvent.smsCodeRequestError) {
      _authViewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_authViewModel.smsErrorMessage ?? '获取验证码失败'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _onGetVerificationCode() async {
    if (_isCountingDown) return;

    if (_mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在获取手机号，请稍候...')));
      context.read<ProfileViewModel>().fetchUserProfile();
      return;
    }

    final captchaService = CaptchaService(context);
    // Use 'reset_pwd' type as the interface logic is the same
    await captchaService.requestSmsCodeForMobile(
      _mobileController.text.trim(),
      type: 'reset_pwd',
    );
  }

  void _onConfirm() {
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
    return Consumer2<AuthViewModel, ProfileViewModel>(
        builder: (context, authViewModel, profileViewModel, child) {
          final isLoading = authViewModel.state == AuthState.loading;

          // Update mobile text field if profile loaded
          if (profileViewModel.userProfile != null && _mobileController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _mobileController.text = profileViewModel.userProfile!.mobile;
              }
            });
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('修改密码'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
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
                      _buildTextField(
                        controller: _mobileController,
                        labelText: '手机号码',
                        hintText: profileViewModel.state == ProfileState.loading ? '加载中...' : '手机号码',
                        readOnly: true,
                        enabled: false,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                          controller: _passwordController,
                          labelText: '密码',
                          hintText: '请输入新密码',
                          isPassword: true
                      ),
                      const SizedBox(height: 20),
                      _buildCodeField(authViewModel),
                      const SizedBox(height: 50),
                      ElevatedButton(
                        onPressed: isLoading ? null : _onConfirm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('确定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    bool isPassword = false,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      readOnly: readOnly,
      enabled: enabled,
      style: TextStyle(color: enabled ? Colors.black : Colors.grey.shade700, fontWeight: FontWeight.normal),
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

  Widget _buildCodeField(AuthViewModel authViewModel) {
    final isSendingSms = authViewModel.isSendingSms;
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
        suffixIcon: _buildSuffixIcon(isSendingSms),
      ),
      validator: (value) => (value == null || value.isEmpty) ? '此项不能为空' : null,
    );
  }

  Widget _buildSuffixIcon(bool isSendingSms) {
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