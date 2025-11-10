import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/pages/captcha_page.dart';
import '../../presentation/provider/auth_viewmodel.dart';

/// A reusable service to handle the entire "get SMS code" flow,
/// including showing the captcha and making the API calls via the ViewModel.
class CaptchaService {
  final BuildContext context;
  CaptchaService(this.context);

  /// Shows the captcha and requests the SMS code for a specific purpose (type).
  ///
  /// The [mobile] number to send the code to.
  /// The [type] of the request, e.g., 'reg', 'login', 'reset_pwd'.
  ///
  /// Returns `true` on success, `false` on failure or cancellation.
  Future<bool> requestSmsCodeForMobile(
      String mobile, {
        required String type, // <-- Add the 'type' parameter
      }) async {
    if (mobile.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先输入手机号码')));
      }
      return false;
    }

    // 1. Show the captcha page and await the result.
    final aliCaptchaParam = await Navigator.of(context).push<String?>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const CaptchaPage(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );

    // 2. Handle the captcha result.
    if (aliCaptchaParam == null || aliCaptchaParam.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('滑动验证已取消'),
          backgroundColor: Colors.orange,
        ));
      }
      return false;
    }

    // 3. Call the ViewModel to execute the API flow, passing the 'type'.
    if (context.mounted) {
      final success = await context.read<AuthViewModel>().requestSmsCode(
        mobile: mobile,
        aliCaptchaParam: aliCaptchaParam,
        type: type, // <-- Pass the type to the ViewModel
      );
      return success;
    }

    // If context is no longer mounted, return false.
    return false;
  }
}