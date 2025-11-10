import 'package:dio/dio.dart';
import 'package:flutter_hbb/services/device_info_service.dart'; // 导入您的服务
import 'package:get_it/get_it.dart';

/// The concrete implementation of a common parameters interceptor for this app.
class AppCommonParamsInterceptor extends Interceptor {
  // Lazy load the service to avoid potential initialization order issues.
  DeviceInfoService get _deviceInfoService => GetIt.instance<DeviceInfoService>();

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final commonParams = await _deviceInfoService.getCommonParameters();

    // Remove null token to avoid sending empty 'token=' query parameter
    commonParams.removeWhere((key, value) => value == null);

    // Merge common params with existing query parameters
    options.queryParameters.addAll(commonParams);

    super.onRequest(options, handler);
  }
}