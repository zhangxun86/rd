import 'package:dio/dio.dart';
import '../models/vip_info_model.dart';

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

  /// Initiates a VIP purchase and returns the raw order string for the payment SDK.
  Future<String> buyVip({
    required int packageId,
    required int payType,
  }) async {
    try {
      final response = await _dio.post(
        '/user/lt/vip_auto_buy',
        queryParameters: {
          'id': packageId.toString(), // The API expects a string.
          'pay_type': payType.toString(), // The API expects a string.
          // Token and other common params are added by interceptors.
        },
      );
      // The API is expected to return the raw order string directly in the 'data' field.
      return response.data as String;
    } on DioException {
      rethrow;
    }
  }
}