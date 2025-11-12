import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/vip_info_model.dart';

abstract class VipRepository {
  Future<Result<VipInfoModel, ApiException>> getVipList(int type);
}