import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_viewmodel.dart';
import '../../../../common/routes.dart';

class PasswordLoginPage extends StatefulWidget {
  const PasswordLoginPage({super.key});
  @override
  _PasswordLoginPageState createState() => _PasswordLoginPageState();
}

class _PasswordLoginPageState extends State<PasswordLoginPage> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = true; // 默认勾选，保持与验证码登录页一致

  late final AuthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<AuthViewModel>();
    // 注册监听器，这是处理错误提示的关键
    _viewModel.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    // 移除监听器
    _viewModel.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  // --- 核心修复：添加状态监听 ---
  void _onAuthStateChanged() {
    if (!mounted) return;

    // 处理登录成功
    if (_viewModel.event == AuthEvent.loginSuccess) {
      _viewModel.consumeEvent();
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
    // 处理登录失败 (接口报错会走到这里)
    else if (_viewModel.event == AuthEvent.loginError) {
      _viewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_viewModel.errorMessage ?? '登录失败'),
        backgroundColor: Colors.red,
      ));
    }
  }
  // --- 修复结束 ---

  void _onLogin() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先阅读并同意用户协议和隐私政策')));
      return;
    }
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      // 调用密码登录方法
      context.read<AuthViewModel>().loginWithPassword(
        mobile: _mobileController.text.trim(),
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
              title: const Text('账号密码登录', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: const BackButton(color: Colors.black),
              foregroundColor: Colors.black,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                  child: Text('验证码登录', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
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
                      _buildTextField(controller: _passwordController, labelText: '密码', hintText: '请输入密码', isPassword: true),
                      _buildForgotPassword(),
                      const SizedBox(height: 10),
                      _buildAgreementRow(),
                      const SizedBox(height: 30),

                      // --- Button Style Updated to match LoginPage ---
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
                      // -----------------------------------------------
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
        },
        child: Text('忘记密码?', style: TextStyle(color: Colors.grey.shade600)),
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