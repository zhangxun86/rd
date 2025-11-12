import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/user_profile_model.dart';
import '../../domain/repositories/profile_repository.dart';

enum ProfileState { initial, loading, loaded, error }

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  ProfileViewModel(this._profileRepository);

  ProfileState _state = ProfileState.initial;
  ProfileState get state => _state;

  UserProfileModel? _userProfile;
  UserProfileModel? get userProfile => _userProfile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserProfile() async {
    // Only show full-page loader on initial fetch
    if (_userProfile == null) {
      _state = ProfileState.loading;
    }
    notifyListeners();

    final result = await _profileRepository.getUserProfile();

    if (result is Success) {
      _userProfile = (result as Success).value as UserProfileModel;
      _state = ProfileState.loaded;
    } else if (result is Failure) {
      _state = ProfileState.error;

      // --- THIS IS THE FIX ---
      final exception = (result as Failure).exception;
      if (exception is ApiException) {
        // If it's our custom exception, we can safely access its message.
        _errorMessage = exception.message;
      } else {
        // For any other type of exception, use its toString() method.
        _errorMessage = "An unexpected error occurred: ${exception.toString()}";
      }
      // --- END OF FIX ---
    }
    notifyListeners();
  }
}