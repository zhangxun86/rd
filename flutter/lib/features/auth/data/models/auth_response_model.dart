// You must import the file where UserPayload is defined.
import '../../../../common/hbbs/hbbs.dart';
import '../../../../models/user_model.dart';

/// Represents the successful response data from all authentication APIs.
/// This model is now precisely mapped to your backend's JSON structure.
class AuthResponseModel {
  /// The token for your PHP API system.
  final String token;

  /// Contains tokens and user info for the RustDesk system.
  final HxTokenInfo hxTokenInfo;

  /// Additional token information (e.g., for Rongyun).
  final List<dynamic> ryTokenInfo;

  // A convenient getter to access the RustDesk token
  String get accessToken => hxTokenInfo.accessToken;

  // A convenient getter to access the UserPayload
  UserPayload? get user => hxTokenInfo.user;

  AuthResponseModel({
    required this.token,
    required this.hxTokenInfo,
    required this.ryTokenInfo,
  });

  /// A factory constructor to create an instance from a JSON map.
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      // 1. Read the top-level 'token'.
      token: json['token'] as String? ?? '',

      // 2. Parse the 'hxtoken_info' object.
      hxTokenInfo: json['hxtoken_info'] != null && json['hxtoken_info'] is Map<String, dynamic>
          ? HxTokenInfo.fromJson(json['hxtoken_info'] as Map<String, dynamic>)
          : HxTokenInfo.empty(), // Provide a default empty object if null

      // 3. Parse 'rytoken_info'.
      ryTokenInfo: (json['rytoken_info'] as List<dynamic>?) ?? [],
    );
  }
}

/// Represents the nested `hxtoken_info` object.
class HxTokenInfo {
  /// The token for the RustDesk system.
  final String accessToken;
  final String configData;

  /// The user object is nested inside hxtoken_info.
  final UserPayload? user;

  HxTokenInfo({
    required this.accessToken,
    required this.configData,
    this.user,
  });

  /// Factory to create an instance from JSON.
  factory HxTokenInfo.fromJson(Map<String, dynamic> json) {
    return HxTokenInfo(
      accessToken: json['access_token'] as String? ?? '',
      configData: json['config_data'] as String? ?? '',
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserPayload.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Factory to create an empty instance for safety.
  factory HxTokenInfo.empty() {
    return HxTokenInfo(accessToken: '', configData: '', user: null);
  }
}