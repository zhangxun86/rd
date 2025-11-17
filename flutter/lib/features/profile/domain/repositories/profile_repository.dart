import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/connection_data_model.dart';
import '../../data/models/user_profile_model.dart';

abstract class ProfileRepository {
  Future<Result<UserProfileModel, ApiException>> getUserProfile();

  Future<Result<ConnectionDataModel, ApiException>> getConnectionData();
}