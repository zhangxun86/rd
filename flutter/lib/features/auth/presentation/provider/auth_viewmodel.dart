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
  deleteAccountSuccess, // <-- NEW
  deleteAccountError,   // <-- NEW
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  AuthViewModel(this._authRepository);

  // --- START: MODIFICATION 1 - Add login state management ---
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  // --- END: MODIFICATION 1 ---

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

  // --- START: MODIFICATION 2 - Add method to check initial state ---
  /// Checks the initial login state from local storage.
  /// This should be called once when the app starts.
  Future<void> checkInitialLoginState() async {
    final token = await _authRepository.getToken();
    _isLoggedIn = token != null && token.isNotEmpty;
    // Notify listeners so the AppShell can update
    notifyListeners();
  }
  // --- END: MODIFICATION 2 ---

  // --- START: MODIFICATION 3 - Add a logout method ---
  /// Logs the user out and clears all stored data.
  Future<void> logout() async {
    await _authRepository.logout();
    _isLoggedIn = false; // Update the login state
    notifyListeners(); // Notify AppShell to switch to the login screen
  }
  // --- END: MODIFICATION 3 ---

  /// Helper method to handle the result of any authentication attempt.
  void _handleAuthResult(Result result,
      {required AuthEvent successEvent, required AuthEvent errorEvent}) {
    if (result is Success) {
      _isLoggedIn = true; // --- MODIFICATION 4: Update login state on success ---
      _state = AuthState.success;
      _event = successEvent;
    } else if (result is Failure) {
      _isLoggedIn = false; // Ensure logged in is false on failure
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
      successEvent: AuthEvent.loginSuccess,
      errorEvent: AuthEvent.loginError,
    );
  }

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

    // This method can also use the helper for consistency.
    _handleAuthResult(
      result,
      successEvent: AuthEvent.resetPasswordSuccess,
      errorEvent: AuthEvent.resetPasswordError,
    );
  }

  Future<void> deleteAccount() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.deleteAccount();

    if (result is Success) {
      _state = AuthState.success;
      _event = AuthEvent.deleteAccountSuccess;
      // Also update the isLoggedIn flag
      _isLoggedIn = false;
    } else if (result is Failure) {
      _state = AuthState.error;
      _event = AuthEvent.deleteAccountError;

      final exception = (result as Failure).exception;
      if (exception is ApiException) {
        _errorMessage = exception.message;
      } else {
        _errorMessage = "An unexpected error occurred: ${exception.toString()}";
      }
    }
    notifyListeners();
  }
}