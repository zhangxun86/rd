import 'package:dio/dio.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import '../../../../common.dart';
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
      // The data source returns `dynamic` data, which we pass along in the Success case.
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

  @override
  Future<void> fetchAndApplyServerConfig() async {
    try {
      // 1. Fetch the encrypted/encoded config string
      final configData = await _remoteDataSource.fetchServerConfig();

      if (configData.isNotEmpty) {
        // 2. Decode using RustDesk's logic
        final serverConfig = ServerConfig.decode(configData);

        print("VIP Purchase Success: Updating server config to ID=${serverConfig.idServer}");

        // 3. Apply the configuration using setServerConfig (from setting_widgets.dart)
        // We pass empty RxStrings because we don't need UI error feedback here (it's a background update)
        await setServerConfig(
            null,
            [RxString(''), RxString(''), RxString('')],
            serverConfig
        );
        print("Server configuration updated successfully.");
      }
    } catch (e) {
      // Log error but don't throw, as payment was already successful.
      // We don't want to confuse the user if this background step fails.
      print("Error updating server config after payment: $e");
    }
  }

}