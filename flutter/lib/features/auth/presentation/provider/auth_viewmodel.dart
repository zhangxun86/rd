import 'dart:async';
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
  loginWithCodeSuccess,
  loginWithCodeError,
  loginWithPasswordSuccess,
  loginWithPasswordError,
  resetPasswordSuccess,
  resetPasswordError,
  deleteAccountSuccess,
  deleteAccountError,
  oneClickLoginSuccess, // <-- NEW
  oneClickLoginError,   // <-- NEW
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  AuthViewModel(this._authRepository);

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  AuthState _state = AuthState.idle;
  AuthState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isSendingSms = false;
  bool get isSendingSms => _isSendingSms;

  String? _smsErrorMessage;
  String? get smsErrorMessage => _smsErrorMessage;

  final StreamController<AuthEvent> _eventController = StreamController<AuthEvent>.broadcast();
  Stream<AuthEvent> get authEvents => _eventController.stream;

  // --- 核心修复：全局防抖变量 ---
  DateTime _lastEventTime = DateTime.fromMillisecondsSinceEpoch(0);
  AuthEvent _lastEvent = AuthEvent.none;
  // ---------------------------

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }

  // --- 核心修复：统一的事件发送入口 ---
  // 所有事件发送必须经过这里，这里就像一个“安检口”，拦截所有重复事件
  void _sendEvent(AuthEvent event) {
    final now = DateTime.now();
    // 如果是同一个事件，且间隔小于 1000 毫秒，直接丢弃！
    if (event == _lastEvent && now.difference(_lastEventTime) < const Duration(milliseconds: 1000)) {
      print("🛑 拦截到重复事件: $event");
      return;
    }

    _lastEvent = event;
    _lastEventTime = now;

    print("✅ 发送事件: $event");
    _eventController.add(event);
  }
  // --------------------------------

  Future<void> checkInitialLoginState() async {
    final token = await _authRepository.getToken();
    _isLoggedIn = token != null && token.isNotEmpty;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    _state = AuthState.loading;
    notifyListeners();

    final result = await _authRepository.deleteAccount();

    if (result is Success) {
      _isLoggedIn = false;
      _state = AuthState.success;
      _sendEvent(AuthEvent.deleteAccountSuccess); // 使用 _sendEvent
    } else if (result is Failure) {
      _state = AuthState.error;
      _extractErrorMessage(result as Failure);
      _sendEvent(AuthEvent.deleteAccountError); // 使用 _sendEvent
    }
    notifyListeners();
  }

  void _extractErrorMessage(Failure failure) {
    final exception = failure.exception;
    if (exception is ApiException) {
      _errorMessage = exception.message;
      debugPrint(exception.toString());
    } else {
      _errorMessage = "An unexpected error occurred: ${exception.toString()}";
    }
  }

  void _handleAuthResult(Result result,
      {required AuthEvent successEvent, required AuthEvent errorEvent}) {
    if (result is Success) {
      _isLoggedIn = true;
      _state = AuthState.success;
      _sendEvent(successEvent); // 使用 _sendEvent
    } else if (result is Failure) {
      _isLoggedIn = false;
      _state = AuthState.error;
      _extractErrorMessage(result as Failure);
      _sendEvent(errorEvent); // 使用 _sendEvent
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

    if (result is Success) {
      _isLoggedIn = true;
      _state = AuthState.success;
      _sendEvent(AuthEvent.loginWithCodeSuccess); // 使用 _sendEvent
    } else if (result is Failure) {
      _isLoggedIn = false;
      _state = AuthState.error;
      _extractErrorMessage(result as Failure);
      _sendEvent(AuthEvent.loginWithCodeError); // 使用 _sendEvent
    }
    notifyListeners();
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

    if (result is Success) {
      _isLoggedIn = true;
      _state = AuthState.success;
      _sendEvent(AuthEvent.loginWithPasswordSuccess); // 使用 _sendEvent
    } else if (result is Failure) {
      _isLoggedIn = false;
      _state = AuthState.error;
      _extractErrorMessage(result as Failure);
      _sendEvent(AuthEvent.loginWithPasswordError); // 使用 _sendEvent
    }
    notifyListeners();
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
      _sendEvent(AuthEvent.smsCodeRequestSuccess); // 使用 _sendEvent
      notifyListeners();
      return true;
    } else {
      final failure = result as Failure;
      final exception = failure.exception;

      if (exception is ApiException) {
        _smsErrorMessage = exception.message;
        debugPrint(exception.toString());
      } else {
        _smsErrorMessage = "Failed to get code: ${exception.toString()}";
      }

      _sendEvent(AuthEvent.smsCodeRequestError); // 使用 _sendEvent
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

    _handleAuthResult(
      result,
      successEvent: AuthEvent.resetPasswordSuccess,
      errorEvent: AuthEvent.resetPasswordError,
    );
  }

  Future<void> loginWithOneClick({
    required String umToken,
    required String umVerifyId,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.loginWithOneClick(
      umToken: umToken,
      umVerifyId: umVerifyId,
    );

    // Reuse the helper method for consistent state updates
    _handleAuthResult(
      result,
      successEvent: AuthEvent.oneClickLoginSuccess,
      errorEvent: AuthEvent.oneClickLoginError,
    );
  }

}