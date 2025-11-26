import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/user_profile_model.dart';
import '../../domain/repositories/profile_repository.dart';
// 1. 导入 SafeRequest 工具类
import '../../../../core/utils/safe_request.dart';

enum ProfileState { initial, loading, loaded, error }

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  ProfileViewModel(this._profileRepository);

  ProfileState _state = ProfileState.initial;
  ProfileState get state => _state;

  UserProfileModel? _userProfile;
  UserProfileModel? get userProfile => _userProfile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserProfile() async {
    // Only show full-page loader on initial fetch
    if (_userProfile == null) {
      _state = ProfileState.loading;
    }
    notifyListeners();

    // --- START: MODIFICATION (Use SafeRequest) ---

    // 使用 SafeRequest.run 包裹请求。
    // 它会自动处理 8001 跳转，以及普通错误的 Toast 提示。
    // 如果成功，返回 UserProfileModel；如果失败（包括 8001），返回 null。
    final profile = await SafeRequest.run(_profileRepository.getUserProfile());

    if (profile != null) {
      // 成功获取数据
      _userProfile = profile;
      _state = ProfileState.loaded;
      _errorMessage = null;
    } else {
      // 获取失败 (可能是网络错误，或者是 8001 已跳转)
      _state = ProfileState.error;
      // 设置一个通用错误提示供 UI 显示重试按钮，具体错误信息 SafeRequest 已通过 Toast 弹出
      _errorMessage = "加载失败，请重试";
    }

    // --- END: MODIFICATION ---

    notifyListeners();
  }
}