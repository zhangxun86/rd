import 'package:dio/dio.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/user_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<UserProfileModel, ApiException>> getUserProfile() async {
    try {
      final profile = await _remoteDataSource.getUserProfile();
      return Success(profile);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Failed to fetch profile', requestOptions: e.requestOptions));
    }
  }
}