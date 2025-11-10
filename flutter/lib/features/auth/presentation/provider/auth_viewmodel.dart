import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/register_request_model.dart'; // Assuming login also uses a model eventually
import '../../domain/repositories/auth_repository.dart';

enum AuthState { idle, loading, success, error }

enum AuthEvent {
  none,
  registrationSuccess,
  registrationError,
  smsCodeRequestSuccess,
  smsCodeRequestError,
  loginSuccess,
  loginError,
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  AuthViewModel(this._authRepository);

  AuthState _state = AuthState.idle;
  AuthState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isSendingSms = false;
  bool get isSendingSms => _isSendingSms;

  String? _smsErrorMessage;
  String? get smsErrorMessage => _smsErrorMessage;

  AuthEvent _event = AuthEvent.none;
  AuthEvent get event => _event;

  void consumeEvent() {
    _event = AuthEvent.none;
  }

  Future<void> register({
    required String mobile,
    required String code,
    required String pwd,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final requestModel = RegisterRequestModel(
      mobile: mobile,
      code: code,
      pwd: pwd,
      appChannelId: "1",
      appShopName: "huawei",
    );

    final result = await _authRepository.register(requestModel);

    if (result is Success) {
      _state = AuthState.success;
      _event = AuthEvent.registrationSuccess;
    } else if (result is Failure) {
      _state = AuthState.error;
      _event = AuthEvent.registrationError;

      final exception = (result as Failure).exception;
      if (exception is ApiException) {
        _errorMessage = exception.message;
        debugPrint(exception.toString());
      } else {
        _errorMessage = "An unexpected error occurred: ${exception.toString()}";
      }
    }
    notifyListeners();
  }

  Future<void> login({
    required String mobile,
    required String code,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.login(
      mobile: mobile,
      code: code,
    );

    if (result is Success) {
      _state = AuthState.success;
      _event = AuthEvent.loginSuccess;
    } else if (result is Failure) {
      _state = AuthState.error;
      _event = AuthEvent.loginError;

      // --- THIS IS THE FIX ---
      final exception = (result as Failure).exception;
      if (exception is ApiException) {
        // If it's our custom exception, we can safely access its message.
        _errorMessage = exception.message;
        debugPrint(exception.toString());
      } else {
        // For any other type of exception, use its toString() method.
        _errorMessage = "An unexpected error occurred during login: ${exception.toString()}";
      }
      // --- END OF FIX ---
    }
    notifyListeners();
  }

  Future<bool> requestSmsCode({
    required String mobile,
    required String aliCaptchaParam,
    required String type, // <-- Add this parameter
  }) async {
    _isSendingSms = true;
    _smsErrorMessage = null;
    notifyListeners();

    final result = await _authRepository.requestSmsCode(
      mobile: mobile,
      aliCaptchaParam: aliCaptchaParam,
      type: type, // <-- Pass it to the repository
    );

    _isSendingSms = false;

    if (result is Success) {
      _event = AuthEvent.smsCodeRequestSuccess;
      notifyListeners();
      return true;
    } else { // result is Failure
      _event = AuthEvent.smsCodeRequestError;

      final exception = (result as Failure).exception;
      if (exception is ApiException) {
        _smsErrorMessage = exception.message;
        debugPrint(exception.toString());
      } else {
        _smsErrorMessage = "Failed to get code: ${exception.toString()}";
      }

      notifyListeners();
      return false;
    }
  }
}