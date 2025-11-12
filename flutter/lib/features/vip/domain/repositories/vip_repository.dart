import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/vip_info_model.dart';

abstract class VipRepository {
  /// Fetches the list of VIP packages for a given type.
  Future<Result<VipInfoModel, ApiException>> getVipList(int type);

  /// Initiates a VIP purchase.
  /// On success, returns the raw order string for the payment SDK.
  Future<Result<String, ApiException>> buyVip({
    required int packageId,
    required int payType,
  });
}