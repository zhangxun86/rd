import 'dart:convert';
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
        message: 'An unknown Dio error occurred during registration.',
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

  @override
  Future<Result<void, ApiException>> requestSmsCode({
    required String mobile,
    required String aliCaptchaParam,
    required String type, // <-- Add this parameter
  }) async {
    try {
      // ... (aliVerification logic remains the same)
      //final String aliVerification = aliCaptchaParam;

      //final captchaCheckResponse = await _remoteDataSource.checkCaptcha(aliVerification);

      final Map<String, dynamic> webViewMessage = jsonDecode(aliCaptchaParam);

      // 2. Extract the 'data' field, which is another JSON string.
      final String nestedDataString = webViewMessage['data'] as String;

      // 3. This `nestedDataString` is the actual verification parameter we need to send.
      final String aliVerification = nestedDataString;

      // 4. Call the pre-verification API with the extracted parameter.
      final captchaCheckResponse = await _remoteDataSource.checkCaptcha(aliVerification);

      if (captchaCheckResponse.captchaVerifyResult && captchaCheckResponse.captchaVerifyKey.isNotEmpty) {
        // --- THIS IS THE FIX ---
        // Pass the `type` parameter to the data source.
        await _remoteDataSource.sendSmsCode(
          mobile: mobile,
          captchaVerification: captchaCheckResponse.captchaVerifyKey,
          type: type, // <-- Pass it here
        );
        // --- END OF FIX ---

        return const Success(null);
      } else {
        // If pre-verification fails, return a business error.
        return Failure(ApiException(
          message: '滑动验证预校验失败，请重试',
          requestOptions: RequestOptions(path: '/aliVerifyIntelligentCaptcha/check'),
        ));
      }

    } on DioException catch (e) {
      if (e.error is ApiException) {
        return Failure(e.error as ApiException);
      }
      return Failure(ApiException(
        message: '获取验证码时发生网络错误',
        requestOptions: e.requestOptions,
      ));
    } catch (e) {
      // This will catch errors from jsonDecode if the format is wrong.
      return Failure(ApiException(
        message: '处理验证参数时出错: ${e.toString()}',
        requestOptions: RequestOptions(path: 'local_parsing'),
      ));
    }
  }

  @override
  Future<Result<AuthResponseModel, ApiException>> login({
    required String mobile,
    required String code,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        mobile: mobile,
        code: code,
      );

      // Save the auth data to local storage upon successful login
      await _localDataSource.saveAuthData(response);

      return Success(response);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        return Failure(e.error as ApiException);
      }
      return Failure(ApiException(
        message: 'An unknown Dio error occurred during login.',
        requestOptions: e.requestOptions,
      ));
    }
  }

  @override
  Future<Result<AuthResponseModel, ApiException>> loginWithPassword({
    required String mobile,
    required String pwd,
  }) async {
    try {
      final response = await _remoteDataSource.loginWithPassword(
        mobile: mobile,
        pwd: pwd,
      );

      // Reuse the logic to save auth data locally
      await _localDataSource.saveAuthData(response);

      return Success(response);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        return Failure(e.error as ApiException);
      }
      return Failure(ApiException(
        message: 'An unknown Dio error occurred during password login.',
        requestOptions: e.requestOptions,
      ));
    }
  }

  @override
  Future<Result<void, ApiException>> resetPassword({
    required String mobile,
    required String code,
    required String pwd,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        mobile: mobile,
        code: code,
        pwd: pwd,
      );
      // On success, return a Success result with no data (void).
      return const Success(null);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        return Failure(e.error as ApiException);
      }
      return Failure(ApiException(
        message: 'An unknown Dio error occurred during password reset.',
        requestOptions: e.requestOptions,
      ));
    }
  }

}