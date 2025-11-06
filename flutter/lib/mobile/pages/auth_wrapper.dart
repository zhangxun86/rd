// lib/mobile/pages/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_hbb/mobile/pages/home_page.dart';
import 'package:flutter_hbb/mobile/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 我们可以创建一个简单的服务来全局存储 token
// 这样在应用的任何地方都能访问到，比如 gFFI 的 API 调用中
class AuthService {
  static String? token;
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // 使用 FutureBuilder 可以优雅地处理异步检查
  late Future<String?> _checkTokenFuture;

  @override
  void initState() {
    super.initState();
    _checkTokenFuture = _getToken();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  void _onLoginSuccess(String token) {
    _saveToken(token).then((_) {
      // 登录成功后，保存 token 并刷新 UI
      setState(() {
        AuthService.token = token;
        _checkTokenFuture = Future.value(token);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _checkTokenFuture,
      builder: (context, snapshot) {
        // 正在检查 Token
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 检查完毕，如果 Token 存在且不为空
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          AuthService.token = snapshot.data; // 更新全局 token
          return HomePage(); // 显示主页
        } else {
          // Token 不存在，显示登录页
          return LoginPage(onLoginSuccess: _onLoginSuccess);
        }
      },
    );
  }
}