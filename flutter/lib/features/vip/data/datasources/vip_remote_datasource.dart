import 'package:dio/dio.dart';
import '../models/vip_info_model.dart';

class VipRemoteDataSource {
  final Dio _dio;
  VipRemoteDataSource(this._dio);

  Future<VipInfoModel> getVipList(int type) async {
    try {
      final response = await _dio.get(
        '/user/lt/vip_list',
        queryParameters: {'type': type},
        // Token and other common params are added by interceptors
      );
      // ApiInterceptor unwraps the 'data' field
      return VipInfoModel.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }
}