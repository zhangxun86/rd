import 'package:dio/dio.dart';
import '../models/connection_data_model.dart';
import '../models/user_profile_model.dart';

class ProfileRemoteDataSource {
  final Dio _dio;
  ProfileRemoteDataSource(this._dio);

  Future<UserProfileModel> getUserProfile() async {
    try {
      // The 'token' will be added automatically by our CommonParamsInterceptor.
      final response = await _dio.get('/user_id_info');

      // The ApiInterceptor will unbox the 'data' field.
      return UserProfileModel.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  Future<ConnectionDataModel> getConnectionData() async {
    try {
      // Token is added by the interceptor
      final response = await _dio.get('/r_desk_connection_data');
      return ConnectionDataModel.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }
}