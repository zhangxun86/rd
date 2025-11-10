import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Gets the application version (e.g., "3.0.1").
  String get version => _packageInfo?.version ?? 'unknown';

  /// Gets the application build number (e.g., "3001").
  String get appCode => _packageInfo?.buildNumber ?? 'unknown';

  /// Gets the application channel ID (can be a fixed value or dynamic).
  String get appChannelId => '105'; // As specified in your requirement

  /// Gets the app shop/store name based on the platform.
  String get appShopName {
    if (Platform.isAndroid) {
      // This can be enhanced further based on build flavors or other logic.
      return "android";
    } else if (Platform.isIOS) {
      return "app_store";
    }
    // Add cases for other platforms if needed (web, desktop, etc.)
    return "unknown";
  }

  /// Gets a descriptive name for the device (e.g., "HUAWEI P40" or "John's iPhone").
  String get appDeviceName {
    final info = _deviceInfo;
    if (info is AndroidDeviceInfo) {
      // Combines manufacturer and model for a descriptive name.
      return "${info.manufacturer} ${info.model}";
    }
    if (info is IosDeviceInfo) {
      // Uses the user-assigned name of the iOS device.
      return info.name;
    }
    // A fallback for other platforms like web or desktop.
    return 'Desktop Device';
  }

  /// Asynchronously retrieves the stored authentication token.
  /// Returns `null` if the token is not found.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming the token is stored with the key 'auth_token' after successful login/registration.
    return prefs.getString('auth_token');
  }

  /// Asynchronously builds and returns a map of all common parameters
  /// required for most API requests.
  Future<Map<String, dynamic>> getCommonParameters() async {
    // Ensure that the service has been initialized before getting parameters.
    // This is a safety check in case `init()` wasn't awaited.
    if (_packageInfo == null || _deviceInfo == null) {
      await init();
    }

    return {
      'app_channel_id': appChannelId,
      'version': version,
      'app_code': appCode,
      'app_shop_name': appShopName,
      'app_device_name': appDeviceName,
      'token': await getToken(), // The token is fetched dynamically for each request.
    };
  }
}