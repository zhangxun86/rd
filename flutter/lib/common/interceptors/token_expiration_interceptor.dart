import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import 'package:get_it/get_it.dart';
import '../../common.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../common/routes.dart';

// ！！！关键点：必须导入 flutter_hbb 的 main.dart 来获取那个被绑定的 globalKey
// 如果您的 globalKey 定义在 common.dart，请改为导入 common.dart
import 'package:flutter_hbb/main.dart';

class TokenExpirationInterceptor extends Interceptor {
  // 静态变量防止多次并发跳转
  static bool _isRedirecting = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print("🚨 [TokenInterceptor] 捕获到 8001 错误！准备跳转...=======");
    // 1. 检查是否是 8001 错误
    if (err.error is ApiException) {
      final apiException = err.error as ApiException;
      if (apiException.code == 8001) {
        print("🚨 [TokenInterceptor] 捕获到 8001 错误！准备跳转...");
        _handleTokenExpiration();
      }
    }
    super.onError(err, handler);
  }

  Future<void> _handleTokenExpiration() async {
    if (_isRedirecting) {
      print("🚨 [TokenInterceptor] 正在跳转中，忽略重复触发");
      return;
    }
    _isRedirecting = true;

    try {
      // 2. 清除本地数据
      print("🚨 [TokenInterceptor] 正在清除本地 Token...");
      if (GetIt.I.isRegistered<AuthRepository>()) {
        await GetIt.I<AuthRepository>().logout();
      }

      // 3. 获取 Context
      // ！！！关键点：使用 flutter_hbb 定义的 globalKey ！！！
      final context = globalKey.currentContext;

      if (context == null) {
        print("❌ [TokenInterceptor] 致命错误：无法获取 Context！globalKey 未绑定或页面未加载。");
        // 尝试备用方案：如果项目使用了 GetX，可以尝试 Get.context
        // if (Get.context != null) { ... }
        return;
      }

      if (!context.mounted) {
        print("❌ [TokenInterceptor] 错误：Context 已卸载");
        return;
      }

      print("🚨 [TokenInterceptor] Context 获取成功，开始导航到登录页...");

      // 4. 执行强制跳转
      // 使用 pushNamedAndRemoveUntil 清空路由栈
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login, // 确保这个路由名称在 routes.dart 中定义正确
            (route) => false,
      );

      print("✅ [TokenInterceptor] 导航指令已发出");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("登录已过期，请重新登录"),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      print("❌ [TokenInterceptor] 跳转过程发生异常: $e");
    } finally {
      // 延迟重置跳转锁，防止短时间内重复弹窗
      await Future.delayed(const Duration(seconds: 2));
      _isRedirecting = false;
    }
  }
}