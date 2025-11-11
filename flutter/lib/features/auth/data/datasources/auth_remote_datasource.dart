import 'package:dio/dio.dart';
import '../models/auth_response_model.dart';
import '../models/captcha_verify_model.dart';
import '../models/register_request_model.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSource(this._dio);

  /// Handles user registration.
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    try {
      final response = await _dio.post(
        '/user/reg',
        queryParameters: request.toJson(),
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  /// 1. Verifies the slider captcha data with your backend.
  Future<CaptchaCheckResponse> checkCaptcha(String aliCaptchaVerification) async {
    try {
      final response = await _dio.post(
        '/aliVerifyIntelligentCaptcha/check',
        queryParameters: {
          'aliCaptchaVerification': aliCaptchaVerification,
        },
      );
      return CaptchaCheckResponse.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  /// 2. Sends the SMS verification code after captcha is pre-verified.
  Future<void> sendSmsCode({
    required String mobile,
    required String captchaVerification,
    required String type, // <-- Add this parameter
  }) async {
    try {
      await _dio.post(
        '/sms/send',
        queryParameters: {
          'mobile': mobile,
          'type': type, // <-- Use the passed-in type
          'aliCaptchaVerificationKey': captchaVerification,
          // Common parameters will be added by the interceptor
        },
      );
    } on DioException {
      rethrow;
    }
  }

  Future<AuthResponseModel> login({
    required String mobile,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/user/code/login',
        queryParameters: {
          'mobile': mobile,
          'code': code,
          // Common parameters will be added by the interceptor
        },
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  Future<AuthResponseModel> loginWithPassword({
    required String mobile,
    required String pwd,
  }) async {
    try {
      final response = await _dio.post(
        '/user/pwd/login',
        queryParameters: {
          'mobile': mobile,
          'pwd': pwd,
          // Common parameters will be added by the interceptor
        },
      );
      // We can reuse the AuthResponseModel as the response structure is the same
      return AuthResponseModel.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String mobile,
    required String code,
    required String pwd,
  }) async {
    try {
      // This API returns no specific data on success, so the return type is Future<void>.
      await _dio.post(
        '/user/pwd/reset',
        queryParameters: {
          'mobile': mobile,
          'code': code,
          'pwd': pwd,
          // Common parameters will be added by the interceptor.
        },
      );
    } on DioException {
      rethrow;
    }
  }
}