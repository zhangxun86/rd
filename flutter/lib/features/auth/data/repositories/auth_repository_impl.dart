import 'dart:convert';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart'; // Required for RxString
import '../../../../common.dart';
import '../../../../common/hbbs/hbbs.dart'; // Required for ServerConfig
import '../../../../common/widgets/setting_widgets.dart'; // Required for setServerConfig
import '../../../../models/user_model.dart'; // Required for UserModel static methods
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';
import '../models/register_request_model.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:flutter_hbb/models/platform_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  /// A private helper method to save authentication data and configure server settings.
  Future<void> _saveAuthData(AuthResponseModel response) async {
    // 1. Save your custom API token
    await _localDataSource.saveToken(response.token);

    // 2. Save RustDesk's access_token to FFI storage
    if (response.hxTokenInfo != null) {
      await bind.mainSetLocalOption(key: 'access_token', value: response.hxTokenInfo!.accessToken);
    }

    // 3. Save user_info to FFI storage
    if (response.user != null) {
      await bind.mainSetLocalOption(
        key: 'user_info',
        value: jsonEncode(response.user!.toJson()),
      );
    } else {
      await bind.mainSetLocalOption(key: 'user_info', value: '');
    }

    // 4. Apply server config from config_data
    if (response.hxTokenInfo != null && response.hxTokenInfo!.configData.isNotEmpty) {
      try {
        final serverConfig = ServerConfig.decode(response.hxTokenInfo!.configData);

        // --- FIX: Pass shouldLogout: false ---
        await setServerConfig(
          null,
          [RxString(''), RxString(''), RxString('')],
          serverConfig,
          shouldLogout: false, // Prevent auto-logout on config update
        );
        // --- END FIX ---

      } catch (e) {
        print("Error applying server configuration from login: $e");
      }
    }

    // 5. Actively refresh the in-memory FFI state models
    try {
      gFFI.userModel.refreshCurrentUser();
      await UserModel.updateOtherModels();
      print("FFI in-memory models refreshed successfully after auth.");
    } catch (e) {
      print("Error refreshing FFI models after auth: $e");
    }
  }

  @override
  Future<Result<AuthResponseModel, ApiException>> register(RegisterRequestModel request) async {
    try {
      final response = await _remoteDataSource.register(request);
      await _saveAuthData(response);
      return Success(response);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Registration failed.', requestOptions: e.requestOptions));
    } catch (e) {
      return Failure(ApiException(message: 'Registration error: $e', requestOptions: RequestOptions(path: 'local_error')));
    }
  }

  @override
  Future<Result<AuthResponseModel, ApiException>> login({
    required String mobile,
    required String code,
  }) async {
    try {
      final response = await _remoteDataSource.login(mobile: mobile, code: code);
      await _saveAuthData(response);
      return Success(response);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Login failed.', requestOptions: e.requestOptions));
    } catch (e) {
      return Failure(ApiException(message: 'Login error: $e', requestOptions: RequestOptions(path: 'local_error')));
    }
  }

  @override
  Future<Result<AuthResponseModel, ApiException>> loginWithPassword({
    required String mobile,
    required String pwd,
  }) async {
    try {
      final response = await _remoteDataSource.loginWithPassword(mobile: mobile, pwd: pwd);
      await _saveAuthData(response);
      return Success(response);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Login failed.', requestOptions: e.requestOptions));
    } catch (e) {
      return Failure(ApiException(message: 'Login error: $e', requestOptions: RequestOptions(path: 'local_error')));
    }
  }

  @override
  Future<String?> getToken() {
    return _localDataSource.getToken();
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clearAuthData();
    await bind.mainSetLocalOption(key: 'access_token', value: '');
    await bind.mainSetLocalOption(key: 'user_info', value: '');
    // Pass shouldLogout: true (default) here as we ARE logging out.
    await setServerConfig(null, [RxString(''), RxString(''), RxString('')], ServerConfig());
  }

  @override
  Future<Result<void, ApiException>> requestSmsCode({
    required String mobile,
    required String aliCaptchaParam,
    required String type,
  }) async {
    try {
      final Map<String, dynamic> webViewMessage = jsonDecode(aliCaptchaParam);
      final String nestedDataString = webViewMessage['data'] as String;
      final String aliVerification = nestedDataString;

      final captchaCheckResponse = await _remoteDataSource.checkCaptcha(aliVerification);

      if (captchaCheckResponse.captchaVerifyResult && captchaCheckResponse.captchaVerifyKey.isNotEmpty) {
        await _remoteDataSource.sendSmsCode(
          mobile: mobile,
          captchaVerification: captchaCheckResponse.captchaVerifyKey,
          type: type,
        );
        return const Success(null);
      } else {
        return Failure(ApiException(
          message: '滑动验证预校验失败，请重试',
          requestOptions: RequestOptions(path: '/aliVerifyIntelligentCaptcha/check'),
        ));
      }
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: '获取验证码网络错误', requestOptions: e.requestOptions));
    } catch (e) {
      return Failure(ApiException(message: '处理验证参数时出错: $e', requestOptions: RequestOptions(path: 'local_parsing')));
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
      return const Success(null);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Password reset failed.', requestOptions: e.requestOptions));
    } catch (e) {
      return Failure(ApiException(message: 'Reset error: $e', requestOptions: RequestOptions(path: 'local_error')));
    }
  }

  @override
  Future<String?> getTokenFromFFI() async {
    final token = await bind.mainGetLocalOption(key: 'access_token');
    return token.isEmpty ? null : token;
  }

  @override
  Future<String?> getUserInfoFromFFI() async {
    final userInfo = await bind.mainGetLocalOption(key: 'user_info');
    return userInfo.isEmpty ? null : userInfo;
  }

  @override
  Future<Result<void, ApiException>> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      await logout();
      return const Success(null);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Failed to delete account', requestOptions: e.requestOptions));
    } catch (e) {
      return Failure(ApiException(message: 'Delete account error: $e', requestOptions: RequestOptions(path: 'local_error')));
    }
  }

  @override
  Future<Result<AuthResponseModel, ApiException>> loginWithOneClick({
    required String umToken,
    required String umVerifyId,
  }) async {
    try {
      final response = await _remoteDataSource.loginWithOneClick(
        umToken: umToken,
        umVerifyId: umVerifyId,
      );

      // Reuse the logic to save auth data (token, user_info, config) locally.
      await _saveAuthData(response);

      return Success(response);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'One-click login failed.', requestOptions: e.requestOptions));
    }
  }
}