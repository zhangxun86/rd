import 'package:flutter/foundation.dart';
import 'package:tobias/tobias.dart';
import 'package:fluwx/fluwx.dart'; // This import should expose WeChatPay
// If the above doesn't work, you might need a more specific import, but let's stick to this first.

import '../../data/models/wechat_pay_info_model.dart';
import '../../../../di_container.dart'; // Import to get the global fluwx instance

/// A service to handle native payment SDK calls.
class PaymentService {

  /// Calls the Alipay SDK to initiate a payment.
  Future<Map> payWithAlipay(String orderString) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final tobiasInstance = Tobias();
        final paymentResult = await tobiasInstance.pay(orderString);
        debugPrint("Alipay Raw Result: $paymentResult");
        return paymentResult;
      } catch (e) {
        debugPrint("Alipay Error: $e");
        return {'resultStatus': '-1', 'memo': '支付发生异常: $e'};
      }
    } else {
      debugPrint("Alipay is only supported on this platform.");
      return {'resultStatus': '-2', 'memo': '当前平台不支持支付宝'};
    }
  }

  /// Calls the WeChat SDK to initiate a payment using the API from the source code.
  Future<void> payWithWeChat(WeChatPayInfoModel payInfo) async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        // --- CORRECT fluwx PAY CALL FOR YOUR VERSION ---
        // Use the top-level `pay` function and the `Payment` class.
        await fluwx.pay(
          which: Payment(
            appId: payInfo.appId,
            partnerId: payInfo.partnerId,
            prepayId: payInfo.prepayId,
            packageValue: payInfo.package, // The parameter is `packageValue` in `Payment` class
            nonceStr: payInfo.nonceStr,
            timestamp: payInfo.timeStamp,
            sign: payInfo.sign,
          ),
        );
        // --- END ---
      } catch (e) {
        debugPrint("WeChat Pay Error: $e");
        throw Exception("Failed to initiate WeChat Pay: $e");
      }
    } else {
      throw Exception("WeChat Pay is only supported on Android/iOS.");
    }
  }
}