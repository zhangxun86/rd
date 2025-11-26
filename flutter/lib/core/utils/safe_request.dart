import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import 'package:get_it/get_it.dart';

// 1. 导入必要的业务文件
import '../../../../main.dart'; // 获取 globalKey
import '../../../../common/routes.dart'; // 获取路由
import '../../common.dart';
import '../../features/auth/domain/repositories/auth_repository.dart'; // 获取 AuthRepository

class SafeRequest {
  // 防止多次跳转的锁
  static bool _isRedirecting = false;

  static Future<T?> run<T>(Future<Result<T, ApiException>> request, {bool showToastOnError = true}) async {
    try {
      final result = await request;

      if (result is Success<T, ApiException>) {
        return result.value;
      }
      else if (result is Failure<T, ApiException>) {
        final error = result.exception;

        // --- 核心修改：在这里直接处理 8001 ---
        if (error.code == 8001) {
          print("🚨 SafeRequest: 捕获到 8001，正在执行强制登出跳转...");
          await _handleUnauthorized();
          return null; // 返回 null，中断业务逻辑
        }
        // -----------------------------------

        if (showToastOnError) {
          // 这里的 showToast 替换为您项目中实际的 toast 方法，例如 BotToast.showText
          print("Request Failed: ${error.message}");
          // BotToast.showText(text: error.message);
        }

        return null;
      }
    } catch (e) {
      print("SafeRequest: Unexpected error $e");
    }
    return null;
  }

  /// 处理未授权/Token过期的逻辑
  static Future<void> _handleUnauthorized() async {
    if (_isRedirecting) return;
    _isRedirecting = true;

    try {
      // 1. 清除本地数据
      if (GetIt.I.isRegistered<AuthRepository>()) {
        await GetIt.I<AuthRepository>().logout();
      }

      // 2. 执行跳转
      final context = globalKey.currentContext;
      if (context != null && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
              (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("登录已过期，请重新登录"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        print("❌ SafeRequest: 无法跳转，Context 为空");
      }
    } catch (e) {
      print("❌ SafeRequest: 跳转异常 $e");
    } finally {
      // 延迟重置锁
      await Future.delayed(const Duration(seconds: 2));
      _isRedirecting = false;
    }
  }
}