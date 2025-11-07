import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/register_request_model.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthState { idle, loading, success, error }

/// An enumeration for one-time events that the UI should react to.
enum AuthEvent {
  none,
  registrationSuccess,
  registrationError,
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  AuthViewModel(this._authRepository);

  AuthState _state = AuthState.idle;
  AuthState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// A variable to hold one-time events.
  AuthEvent _event = AuthEvent.none;
  AuthEvent get event => _event;

  /// The UI calls this method after handling an event to prevent it from firing again.
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
      appChannelId: "1", // Example value
      appShopName: "huawei", // Example value
    );

    final result = await _authRepository.register(requestModel);

    if (result is Success) {
      _state = AuthState.success;
      _event = AuthEvent.registrationSuccess; // Set success event
    } else if (result is Failure) {
      _state = AuthState.error;

      final exception = (result as Failure).exception;
      if (exception is ApiException) {
        _errorMessage = exception.message;
        debugPrint(exception.toString());
      } else {
        _errorMessage = "An unexpected error occurred: ${exception.toString()}";
      }
      _event = AuthEvent.registrationError; // Set error event
    }
    notifyListeners();
  }
}