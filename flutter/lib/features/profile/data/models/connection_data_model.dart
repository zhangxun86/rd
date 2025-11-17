/// Represents the user's connection status and rights data
/// from the /r_desk_connection_data endpoint.
class ConnectionDataModel {
  /// Remaining connection time in seconds.
  final int remainingTime;

  /// The nation associated with the user's IP.
  final String? ipNation;

  /// The province associated with the user's IP.
  final String? ipProvince;

  /// A flag indicating if the user needs to upgrade to a global VIP.
  /// 0 = false, 1 = true.
  final bool needOpenGlobalVip;

  /// The user's current VIP type (e.g., 0 for none, 1 for regular, 2 for global).
  final int vipType;

  ConnectionDataModel({
    required this.remainingTime,
    this.ipNation,
    this.ipProvince,
    required this.needOpenGlobalVip,
    required this.vipType,
  });

  /// Creates an instance from a JSON map, providing default values for safety.
  factory ConnectionDataModel.fromJson(Map<String, dynamic> json) {
    return ConnectionDataModel(
      // For required fields, provide a sensible default if null.
      remainingTime: (json['r_time'] as num?)?.toInt() ?? 0,

      // For optional string fields, they can be null.
      ipNation: json['ip_nation'] as String?,
      ipProvince: json['ip_province'] as String?,

      // Convert the integer flag to a boolean.
      needOpenGlobalVip: (json['need_open_global_vip'] as int?) == 1,

      // Provide a default value for the VIP type.
      vipType: (json['vip_type'] as int?) ?? 0,
    );
  }
}