import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/auth_response_model.dart';
import '../../data/models/register_request_model.dart';

abstract class AuthRepository {
  /// Registers a user.
  Future<Result<AuthResponseModel, ApiException>> register(RegisterRequestModel request);

  /// Gets the auth token from local storage.
  Future<String?> getToken();

  /// Clears auth data from local storage.
  Future<void> logout();

  /// Handles the entire "get SMS code" flow, including captcha verification.
  Future<Result<void, ApiException>> requestSmsCode({
    required String mobile,
    required String aliCaptchaParam,
    required String type, // <-- Add this parameter
  });

  Future<Result<AuthResponseModel, ApiException>> login({
    required String mobile,
    required String code,
  });
}