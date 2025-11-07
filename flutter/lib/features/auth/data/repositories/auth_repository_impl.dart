import 'package:flutter_network_kit/flutter_network_kit.dart';
import 'package:dio/dio.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';
import '../models/register_request_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<Result<AuthResponseModel, ApiException>> register(RegisterRequestModel request) async {
    try {
      final response = await _remoteDataSource.register(request);
      await _localDataSource.saveAuthData(response);
      return Success(response);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        return Failure(e.error as ApiException);
      }
      return Failure(ApiException(
        message: 'An unknown Dio error occurred.',
        requestOptions: e.requestOptions,
      ));
    }
  }

  @override
  Future<String?> getToken() {
    return _localDataSource.getToken();
  }

  @override
  Future<void> logout() {
    return _localDataSource.clearAuthData();
  }
}