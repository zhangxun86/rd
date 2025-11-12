import 'package:flutter/foundation.dart';
import 'package:tobias/tobias.dart';

/// A service to handle native payment SDK calls.
class PaymentService {
  /// Calls the Alipay SDK to initiate a payment.
  Future<Map> payWithAlipay(String orderString) async {
    // Check if the app is running on Android.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        // Get an instance of Tobias first.
        final tobiasInstance = Tobias();
        // Then call the pay method on the instance.
        final paymentResult = await tobiasInstance.pay(orderString);

        debugPrint("Alipay Raw Result: $paymentResult");
        return paymentResult;

      } catch (e) {
        debugPrint("Alipay Error: $e");
        return {'resultStatus': '-1', 'memo': '支付发生异常: $e'};
      }
    } else {
      debugPrint("Alipay is only supported on Android.");
      return {'resultStatus': '-2', 'memo': '当前平台不支持支付宝'};
    }
  }
}