class AuthResponseModel {
  final String token;
  final HxTokenInfo hxTokenInfo;
  final List<dynamic> ryTokenInfo;

  AuthResponseModel({
    required this.token,
    required this.hxTokenInfo,
    required this.ryTokenInfo,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String,
      hxTokenInfo: HxTokenInfo.fromJson(json['hxtoken_info'] as Map<String, dynamic>),
      ryTokenInfo: json['rytoken_info'] as List<dynamic>,
    );
  }
}

class HxTokenInfo {
  final String accessToken;
  final String configData;

  HxTokenInfo({
    required this.accessToken,
    required this.configData,
  });

  factory HxTokenInfo.fromJson(Map<String, dynamic> json) {
    return HxTokenInfo(
      accessToken: json['access_token'] as String,
      configData: json['config_data'] as String,
    );
  }
}