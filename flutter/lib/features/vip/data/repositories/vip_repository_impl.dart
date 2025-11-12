import 'package:dio/dio.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
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
  Future<Result<String, ApiException>> buyVip({
    required int packageId,
    required int payType,
  }) async {
    try {
      final orderString = await _remoteDataSource.buyVip(
        packageId: packageId,
        payType: payType,
      );
      return Success(orderString);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Failed to create payment order', requestOptions: e.requestOptions));
    }
  }
}