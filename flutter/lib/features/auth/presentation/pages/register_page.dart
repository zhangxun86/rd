import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_viewmodel.dart';
import '../../../../common/routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;

  late final AuthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<AuthViewModel>();
    _viewModel.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _viewModel.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (_viewModel.event == AuthEvent.registrationSuccess) {
      _viewModel.consumeEvent();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } else if (_viewModel.event == AuthEvent.registrationError) {
      _viewModel.consumeEvent();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel.errorMessage ?? 'An unknown error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
        builder: (context, viewModel, child) {
          final isLoading = viewModel.state == AuthState.loading;

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
                      _buildCodeField(),
                      const SizedBox(height: 30),
                      _buildAgreementRow(),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: isLoading ? null : _onRegister,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: isLoading
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
    );
  }

  void _onRegister() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先阅读并同意用户协议和隐私政策')));
      return;
    }
    // Hide keyboard
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthViewModel>().register(
        mobile: _mobileController.text.trim(),
        code: _codeController.text.trim(),
        pwd: _passwordController.text.trim(),
      );
    }
  }

  Widget _buildTextField({required TextEditingController controller, required String labelText, required String hintText, bool isPassword = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal), // Input text color
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.normal), // Unfocused label color
        floatingLabelStyle: const TextStyle(color: Colors.blueAccent), // Focused (floating) label color
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

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal), // Input text color
      decoration: InputDecoration(
        labelText: '验证码',
        labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.normal), // Unfocused label color
        floatingLabelStyle: const TextStyle(color: Colors.blueAccent), // Focused (floating) label color
        hintText: '请输入验证码',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        suffixIcon: TextButton(
          onPressed: () { /* TODO: Implement get code logic */ },
          child: const Text('获取验证码', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
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
            activeColor: Colors.blueAccent, // Color when checked
            checkColor: Colors.white, // Color of the check mark
            side: MaterialStateBorderSide.resolveWith(
                  (states) {
                // Border color when UNCHECKED
                if (states.contains(MaterialState.selected)) {
                  return const BorderSide(color: Colors.blueAccent, width: 2.0);
                }
                return BorderSide(color: Colors.grey.shade400, width: 2.0);
              },
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '我已阅读并同意 ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              children: [
                TextSpan(text: '《用户协议》', style: const TextStyle(color: Colors.blueAccent), recognizer: TapGestureRecognizer()..onTap = () {/* TODO: Navigate to user agreement */}),
                const TextSpan(text: ' 和 '),
                TextSpan(text: '《隐私政策》', style: const TextStyle(color: Colors.blueAccent), recognizer: TapGestureRecognizer()..onTap = () {/* TODO: Navigate to privacy policy */}),
              ],
            ),
          ),
        ),
      ],
    );
  }
}