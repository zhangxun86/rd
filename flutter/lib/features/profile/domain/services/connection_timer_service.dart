import '../../data/models/connection_data_model.dart';
import 'dart:async';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/di_container.dart';
import 'package:flutter_hbb/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart'; // Import Result types

/// A service to periodically check the user's remaining connection time
/// during an active remote session.
class ConnectionTimerService {
  // Singleton pattern
  static final ConnectionTimerService _instance = ConnectionTimerService._internal();
  factory ConnectionTimerService() => _instance;
  ConnectionTimerService._internal();

  Timer? _timer;
  String? _activeSessionId;

  /// Starts the periodic check for the given [sessionId].
  void start(String sessionId) {
    stop();
    _activeSessionId = sessionId;
    print("ConnectionTimerService: Starting timer for session $_activeSessionId");
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkConnectionTime();
    });
    _checkConnectionTime(); // Initial check
  }

  /// Stops the periodic check.
  void stop() {
    if (_timer != null) {
      print("ConnectionTimerService: Stopping timer for session $_activeSessionId");
      _timer?.cancel();
      _timer = null;
      _activeSessionId = null;
    }
  }

  /// The internal method that performs the API call and checks the time.
  Future<void> _checkConnectionTime() async {
    if (_activeSessionId == null) {
      stop();
      return;
    }

    print("ConnectionTimerService: Checking remaining time...");
    final profileRepo = getIt<ProfileRepository>();
    final result = await profileRepo.getConnectionData();

    // --- THIS IS THE FIX ---
    // Use `is Success` to check the type and safely access the `value`.
    if (result is Success<ConnectionDataModel, ApiException>) {
      final remainingTime = result.value.remainingTime;
      print("ConnectionTimerService: Remaining time is $remainingTime seconds.");

      if (remainingTime <= 0) {
        print("ConnectionTimerService: Time is up! Closing connection for session $_activeSessionId.");
        closeConnection(id: _activeSessionId);
      }
    } else if (result is Failure<ConnectionDataModel, ApiException>) {
      // After checking the type, we can now safely cast and access `exception`.
      final exception = result.exception;
      print("ConnectionTimerService: Failed to check remaining time. Error: ${exception.message}");
    }
    // --- END OF FIX ---
  }
}