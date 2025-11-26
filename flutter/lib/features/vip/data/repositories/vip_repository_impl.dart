import 'package:dio/dio.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import 'package:get/get.dart';
import '../../../../common.dart';
import '../../../../common/hbbs/hbbs.dart';
import '../../../../common/widgets/setting_widgets.dart';
import '../../domain/repositories/vip_repository.dart';
import '../datasources/vip_remote_datasource.dart';
import '../models/vip_info_model.dart';

class VipRepositoryImpl implements VipRepository {
  final VipRemoteDataSource _remoteDataSource;
  VipRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<VipInfoModel, ApiException>> getVipList(int type) async {
    try {
      final vipInfo = await _remoteDataSource.getVipList(type);
      return Success(vipInfo);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Failed to fetch VIP list', requestOptions: e.requestOptions));
    }
  }

  @override
  Future<Result<dynamic, ApiException>> buyVip({
    required int packageId,
    required int payType,
  }) async {
    try {
      final orderData = await _remoteDataSource.buyVip(
        packageId: packageId,
        payType: payType,
      );
      return Success(orderData);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Failed to create payment order', requestOptions: e.requestOptions));
    }
  }

  /// --- MODIFICATION: Return Result type ---
  @override
  Future<Result<void, ApiException>> fetchAndApplyServerConfig() async {
    try {
      // 1. Fetch config
      final configData = await _remoteDataSource.fetchServerConfig();

      if (configData.isNotEmpty) {
        // 2. Decode
        final serverConfig = ServerConfig.decode(configData);

        print("VIP Purchase Success: Updating server config to ID=${serverConfig.idServer}");

        // 3. Apply
        await setServerConfig(
            null,
            [RxString(''), RxString(''), RxString('')],
            serverConfig
        );
        print("Server configuration updated successfully.");
      }
      // Return success (void)
      return const Success(null);

    } on DioException catch (e) {
      // Wrap Dio errors
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Failed to update server config', requestOptions: e.requestOptions));
    } catch (e) {
      // Wrap other errors
      return Failure(ApiException(
          message: "Error applying server config: $e",
          requestOptions: RequestOptions(path: 'local_config_apply')
      ));
    }
  }
// --- END MODIFICATION ---
}