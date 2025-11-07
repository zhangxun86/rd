import 'package:dio/dio.dart';
import '../models/auth_response_model.dart';
import '../models/register_request_model.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSource(this._dio);

  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    try {
      final response = await _dio.post(
        '/user/reg',
        queryParameters: request.toJson(),
      );
      // The interceptor unwraps the 'data' field, so we can parse it directly.
      return AuthResponseModel.fromJson(response.data);
    } on DioException {
      // The ApiInterceptor has already wrapped the error, so we just rethrow.
      rethrow;
    }
  }
}