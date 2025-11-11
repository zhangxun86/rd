import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/register_request_model.dart';
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
  resetPasswordSuccess,
  resetPasswordError,
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

  /// Helper method to handle the result of any authentication attempt.
  /// This reduces code duplication and ensures consistent error handling.
  void _handleAuthResult(Result result,
      {required AuthEvent successEvent, required AuthEvent errorEvent}) {
    if (result is Success) {
      _state = AuthState.success;
      _event = successEvent;
    } else if (result is Failure) {
      _state = AuthState.error;
      _event = errorEvent;

      final exception = result.exception;
      if (exception is ApiException) {
        _errorMessage = exception.message;
        debugPrint(exception.toString());
      } else {
        _errorMessage = "An unexpected error occurred: ${exception.toString()}";
      }
    }
    notifyListeners();
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
    _handleAuthResult(
      result,
      successEvent: AuthEvent.registrationSuccess,
      errorEvent: AuthEvent.registrationError,
    );
  }

  /// Handles login with a verification code.
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

    _handleAuthResult(
      result,
      successEvent: AuthEvent.loginSuccess,
      errorEvent: AuthEvent.loginError,
    );
  }

  /// Handles login with a password.
  Future<void> loginWithPassword({
    required String mobile,
    required String pwd,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.loginWithPassword(
      mobile: mobile,
      pwd: pwd,
    );

    _handleAuthResult(
      result,
      successEvent: AuthEvent.loginSuccess, // Can reuse the same events
      errorEvent: AuthEvent.loginError,
    );
  }

  /// Handles the multi-step process of requesting an SMS code.
  Future<bool> requestSmsCode({
    required String mobile,
    required String aliCaptchaParam,
    required String type,
  }) async {
    _isSendingSms = true;
    _smsErrorMessage = null;
    notifyListeners();

    final result = await _authRepository.requestSmsCode(
      mobile: mobile,
      aliCaptchaParam: aliCaptchaParam,
      type: type,
    );

    _isSendingSms = false;

    if (result is Success) {
      _event = AuthEvent.smsCodeRequestSuccess;
      notifyListeners();
      return true;
    } else {
      // result is Failure
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

  Future<void> resetPassword({
    required String mobile,
    required String code,
    required String pwd,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.resetPassword(
      mobile: mobile,
      code: code,
      pwd: pwd,
    );

    // We can reuse the _handleAuthResult logic if we want,
    // but for clarity, let's handle it separately.
    if (result is Success) {
      _state = AuthState.success;
      _event = AuthEvent.resetPasswordSuccess;
    } else if (result is Failure) {
      _state = AuthState.error;
      _event = AuthEvent.resetPasswordError;

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
}
