class RegisterRequestModel {
  final String mobile;
  final String code;
  final String pwd;
  final String appChannelId;
  final String appShopName;

  RegisterRequestModel({
    required this.mobile,
    required this.code,
    required this.pwd,
    required this.appChannelId,
    required this.appShopName,
  });

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile,
      'code': code,
      'pwd': pwd,
      'app_channel_id': appChannelId,
      'app_shop_name': appShopName,
    };
  }
}