import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_hbb/features/auth/domain/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A service dedicated to providing dynamic device, application,
/// and user-specific information required for API calls.
///
/// This service encapsulates the logic for fetching platform-specific details,
/// ensuring that the rest of the application doesn't need to know about
/// the underlying packages like `device_info_plus` or `package_info_plus`.
class DeviceInfoService {
  // Using a singleton pattern to ensure we only have one instance of this service.
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  PackageInfo? _packageInfo;
  BaseDeviceInfo? _deviceInfo;

  /// Initializes the service by fetching platform-specific information asynchronously.
  /// This method should be called once during application startup (e.g., in `initDI`).
  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    _deviceInfo = await DeviceInfoPlugin().deviceInfo;
  }

  // --- Getters for dynamic values ---

  /// Gets the application version (e.g., "1.4.2").
  String get version => _packageInfo?.version ?? 'unknown';

  /// Gets the application build number (e.g., "60").
  String get appCode => _packageInfo?.buildNumber ?? 'unknown';

  /// Gets the application channel ID.
  String get appChannelId => '105'; // As specified in your requirement

  /// Gets the app shop/store name based on the platform.
  String get appShopName {
    if (Platform.isAndroid) {
      return "android";
    } else if (Platform.isIOS) {
      return "app_store";
    }
    return "unknown";
  }

  /// Gets a descriptive name for the device (e.g., "HUAWEI YAL-AL10").
  String get appDeviceName {
    final info = _deviceInfo;
    if (info is AndroidDeviceInfo) {
      return "${info.manufacturer} ${info.model}";
    }
    if (info is IosDeviceInfo) {
      return info.name;
    }
    // A fallback for other platforms like web or desktop.
    try {
      return info?.data['prettyName'] ?? 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Asynchronously retrieves the stored authentication token for the custom PHP APIs.
  /// It gets the token via the `AuthRepository` to maintain layer separation.
  /// Returns `null` if the token is not found.
  Future<String?> getToken() async {
    // Check if AuthRepository is registered before trying to get it.
    if (GetIt.instance.isRegistered<AuthRepository>()) {
      final authRepository = GetIt.instance<AuthRepository>();
      return await authRepository.getToken();
    }
    // Return null if the repository is not available yet (e.g., during early startup).
    return null;
  }

  /// Asynchronously builds and returns a map of all common parameters
  /// required for most API requests.
  Future<Map<String, dynamic>> getCommonParameters() async {
    // Ensure that the service has been initialized before getting parameters.
    // This is a safety check.
    if (_packageInfo == null || _deviceInfo == null) {
      await init();
    }

    return {
      'app_channel_id': appChannelId,
      'version': version,
      'app_code': appCode,
      'app_shop_name': appShopName,
      'app_device_name': appDeviceName,
      // This will fetch the correct token from SharedPreferences via the repository.
      'token': await getToken(),
    };
  }
}