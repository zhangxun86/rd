class UserProfileModel {
  final int id;
  final String nickname;
  final String avatar;
  final bool isVip;
  final String vipName;
  final String vipExpDate;
  final String mobile;

  UserProfileModel({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.isVip,
    required this.vipName,
    required this.vipExpDate,
    required this.mobile,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as int,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String,
      // The API returns 0 or 1 for is_vip, so we convert it to a boolean.
      isVip: (json['is_vip'] as int) == 1,
      vipName: json['vip_name'] as String,
      vipExpDate: json['vip_exp_date'] as String,
      mobile: json['mobile'] as String? ?? '',
    );
  }
}