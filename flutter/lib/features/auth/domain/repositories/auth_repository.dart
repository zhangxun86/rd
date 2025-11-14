import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/auth_response_model.dart';
import '../../data/models/register_request_model.dart';

abstract class AuthRepository {
  Future<Result<AuthResponseModel, ApiException>> register(RegisterRequestModel request);
  Future<Result<AuthResponseModel, ApiException>> login({required String mobile, required String code});
  Future<Result<AuthResponseModel, ApiException>> loginWithPassword({required String mobile, required String pwd});
  Future<Result<void, ApiException>> resetPassword({required String mobile, required String code, required String pwd});

  Future<String?> getToken();
  Future<void> logout();

  Future<Result<void, ApiException>> requestSmsCode({
    required String mobile,
    required String aliCaptchaParam,
    required String type,
  });

  // --- Methods for verification ---
  Future<String?> getTokenFromFFI();
  Future<String?> getUserInfoFromFFI();
}