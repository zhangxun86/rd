import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/auth_response_model.dart';
import '../../data/models/register_request_model.dart';

abstract class AuthRepository {
  Future<Result<AuthResponseModel, ApiException>> register(RegisterRequestModel request);
  Future<String?> getToken();
  Future<void> logout();
}