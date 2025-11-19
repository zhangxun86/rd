import 'package:dio/dio.dart';
import '../models/vip_info_model.dart';
import '../models/wechat_pay_info_model.dart'; // Import is needed, although not used directly

class VipRemoteDataSource {
  final Dio _dio;
  VipRemoteDataSource(this._dio);

  /// Fetches the list of VIP packages.
  Future<VipInfoModel> getVipList(int type) async {
    try {
      final response = await _dio.get(
        '/user/lt/vip_list',
        queryParameters: {'type': type},
        // Token and other common params are added by interceptors.
      );
      // The ApiInterceptor unwraps the 'data' field.
      return VipInfoModel.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  /// Initiates a VIP purchase and returns the payment data from the server.
  ///
  /// The return type is `dynamic` because the backend returns a `String` for Alipay
  /// and a `Map<String, dynamic>` (JSON object) for WeChat Pay.
  Future<dynamic> buyVip({
    required int packageId,
    required int payType,
  }) async {
    try {
      final response = await _dio.post(
        '/user/lt/vip_auto_buy',
        queryParameters: {
          'id': packageId.toString(),
          'pay_type': payType.toString(),
          // Token and other common params are added by interceptors.
        },
      );
      // The ApiInterceptor unwraps the 'data' field. We return the content
      // of 'data' directly, which can be of any type.
      return response.data;
    } on DioException {
      rethrow;
    }
  }

  Future<String> fetchServerConfig() async {
    try {
      // ApiInterceptor will add the token automatically.
      final response = await _dio.get('/r_desk_config_data');

      // ApiInterceptor unboxes the 'data' field.
      // The response data is Map: {"config_data": "..."}
      final Map<String, dynamic> data = response.data;
      return data['config_data'] as String? ?? '';
    } on DioException {
      rethrow;
    }
  }

}