import 'package:shared_preferences/shared_preferences.dart';

/// Manages storing and retrieving authentication data from the device's local storage
/// using SharedPreferences. This is the Dart-level storage.
class AuthLocalDataSource {
  static const _tokenKey = 'auth_token';

  /// Saves the authentication token to SharedPreferences.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Retrieves the authentication token from SharedPreferences.
  /// Returns `null` if the token is not found.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Removes the authentication token from SharedPreferences.
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}