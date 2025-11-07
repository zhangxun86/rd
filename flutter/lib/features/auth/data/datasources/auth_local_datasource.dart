import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response_model.dart';

class AuthLocalDataSource {
  static const _tokenKey = 'auth_token';

  Future<void> saveAuthData(AuthResponseModel authData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, authData.token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}