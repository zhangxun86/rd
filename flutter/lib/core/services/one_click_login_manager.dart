import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// 必须同时引入 Common 和 Verify 库
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:umeng_verify_sdk/umeng_verify_sdk.dart';

class OneClickLoginManager {
  // =========================================================
  // 1. 请在此处替换你的友盟 AppKey 和 Secret
  // =========================================================

  // 友盟后台 -> 应用设置 -> AppKey
  static const String _androidAppKey = "691fc6e39a7f376488e17a6b";
  static const String _iosAppKey = "你的iOS_AppKey";
  static const String _channel = "Umeng"; // 渠道名

  // 友盟后台 -> 认证服务 -> 认证秘钥 (Secret)
  static const String _androidVerifySecret = "S9if6llSvYkAzhxGQkbGStCW/xpWPLUQlztT29BmjlU2ErqSBsN0ZWmjYw3iUgdJ+wW8MxoqhC/rPt7C1JS3ipK4/RHAIMHZzoVzCGGiPEQHDqWd9RMpZrkTWJVKJ/GaQhrRUhJH1Zk13qoIu2gUUwwTV7Ls54dXz26mFhJn9N0KX1KUpYfzyWxuTxjrDEmJdD4mr2bi8WQ3ReWcBnnZjmVsQJcto8w5Mkm6xGzV5cd72lAuZmAX7IiHN8kPtavrXCrD+l/KPQcifaS0BJHsU79y+iaWgk9velqv0E4gpPwSl7bPKhYMoQ==";
  static const String _iosVerifySecret = "你的iOS_Secret_Key";

  // =========================================================
  // 2. 资源文件说明 (非常重要)
  //
  // 以下代码中引用的图片名称（如 "umeng_logo", "login_btn_bg" 等）
  // 必须放在原生工程目录中，不能放在 Flutter assets 里！
  // Android: android/app/src/main/res/drawable/
  // iOS: ios/Runner/Assets.xcassets/
  // =========================================================


  /// 全局初始化 SDK
  /// 建议在 main.dart 的 main() 中或 SplashPage 中调用一次
  static Future<void> init() async {
    try {
      print("OneClickLoginManager: SDK 初始化====================");
      // 1. 初始化友盟基础统计库 (Common) - 必须步骤
      // 如果没有这一步，后续功能都无法使用
      UmengCommonSdk.initCommon(_androidAppKey, _iosAppKey, _channel);

      // Android 设置页面采集模式（推荐手动模式）
      if (Platform.isAndroid) {
        UmengCommonSdk.setPageCollectionModeManual();
      }

      // 2. 初始化一键登录鉴权 (Verify) - 必须步骤
      if (Platform.isAndroid) {
        // Android 必须调用 register
        UmengVerifySdk.register_android();
      }

      // 设置秘钥鉴权
      UmengVerifySdk.setVerifySDKInfo(_androidVerifySecret, _iosVerifySecret);

      print("OneClickLoginManager: SDK 初始化完成");
    } catch (e) {
      print("OneClickLoginManager: SDK 初始化异常 -> $e");
    }
  }

  /// 唤起一键登录
  /// [onSuccess] 成功回调，返回 token 和 verifyId (需传给服务端)
  /// [onFailure] 失败或取消回调，返回错误信息
  static Future<void> login({
    required Function(String token, String verifyId) onSuccess,
    required Function(String msg) onFailure,
  }) async {

    // 1. 设置监听回调
    _setupCallbacks(onSuccess, onFailure);

    // 2. 获取 UI 配置
    UMCustomModel uiConfig = _getUIConfig();

    // 3. 执行登录流程
    try {
      // 3.1 加速授权页弹起 (预取号)
      // 超时时间设置 3 秒
      await UmengVerifySdk.accelerateLoginPageWithTimeout(3);

      // 3.2 拉起授权页
      UmengVerifySdk.getLoginTokenWithTimeout(3, uiConfig);

    } catch (e) {
      onFailure("SDK调用异常: $e");
    }
  }

  /// 处理 SDK 回调逻辑
  static void _setupCallbacks(
      Function(String, String) onSuccess,
      Function(String) onFailure
      ) {

    // 统一的回调处理函数
    Callback callback = (dynamic data) {
      print("OneClickLoginManager Callback: $data");

      if (data == null) return;

      // 解析数据，兼容 Map 和 String 两种返回格式
      Map<String, dynamic> result;
      if (data is String) {
        try {
          result = json.decode(data);
        } catch (e) {
          result = {};
        }
      } else if (data is Map) {
        result = Map<String, dynamic>.from(data);
      } else {
        result = {};
      }

      // 获取状态码
      final String code = result['code'] ?? result['resultCode'] ?? "";
      final String msg = result['msg'] ?? "";
      final String token = result['token'] ?? "";

      // --- MODIFICATION: 获取 verifyId ---
      // 注意：具体字段名取决于友盟 SDK 的返回，通常可能在 result 中
      // 如果返回结果中没有明确的 verifyId，可能需要检查是否有 traceId 或其他字段
      final String verifyId = result['verifyId'] ?? "";
      // ---------------------------------

      // --- 状态码判断 ---
      switch (code) {
        case "600000": // 获取 Token 成功
          _quitLoginPage(); // 务必关闭授权页
          // 将 token 和 verifyId 一起返回
          onSuccess(token, verifyId);
          break;

        case "600001": // 唤起授权页成功
        // 页面已显示，无需处理，等待用户操作
          break;

        case "600002": // 唤起授权页失败
        case "600011": // 获取 Token 失败
        case "600013": // 运营商维护
        case "600014": // 运营商维护
        case "600015": // 接口超时
        case "600024": // 终端环境不支持 (无SIM卡/无流量)
          _quitLoginPage();
          onFailure("环境不支持或失败: $msg ($code)");
          break;

        case "700000": // 用户点击了左上角返回/取消
          _quitLoginPage();
          onFailure("用户取消登录");
          break;

        case "700001": // 用户点击了“切换其他账号”
          _quitLoginPage();
          onFailure("用户选择其他登录方式");
          break;

        case "700002": // 点击登录按钮
        case "700003": // 点击CheckBox
        case "700004": // 点击协议
        // 这些是由于点击产生的事件，通常不需要关闭页面，除非业务需要
          break;

        default:
        // 其他未知错误
          print("未处理的Code: $code");
          break;
      }
    };

    // 注册回调
    if (Platform.isAndroid) {
      // Android 结果回调
      UmengVerifySdk.setTokenResultCallback_android(callback);
      // Android 点击事件回调 (处理点击切换账号等)
      UmengVerifySdk.setUIClickCallback_android(callback);
    } else if (Platform.isIOS) {
      // iOS 统一回调
      UmengVerifySdk.getLoginTokenCallback(callback);
    }
  }

  /// 关闭授权页面
  static void _quitLoginPage() {
    if (Platform.isAndroid) {
      UmengVerifySdk.quitLoginPage_android();
    } else {
      // iOS 参数 true 表示带动画关闭
      UmengVerifySdk.cancelLoginVCAnimated(true);
    }
  }

  /// 获取 UI 配置
  /// 注意：这里的所有图片名必须在原生资源目录中存在
  static UMCustomModel _getUIConfig() {
    UMCustomModel model = UMCustomModel();

    // ------------------------------------------------------------
    // 基础配置
    // ------------------------------------------------------------
    model.navColor = Colors.white.value;
    model.navTitle = ["一键登录", 0xFF000000, 18];
    model.navBackImage = "icon_close"; // 原生图片名：关闭/返回图标
    model.hideNavBackItem = false;

    // 状态栏设置 (false显示, true隐藏)
    model.prefersStatusBarHidden = false;

    // 背景设置
    model.backgroundColor_ios = 0xFFFFFFFF;
    // model.backgroundImage = "page_bg"; // 如需背景图可开启

    // ------------------------------------------------------------
    // 1. Logo 设置
    // ------------------------------------------------------------
    model.logoImage = "umeng_logo"; // 原生图片名：APP图标
    model.logoIsHidden = false;

    // ------------------------------------------------------------
    // 2. 手机掩码设置
    // ------------------------------------------------------------
    model.numberColor = 0xFF333333;
    model.numberFont = 24.0;

    // ------------------------------------------------------------
    // 3. 登录按钮设置
    // ------------------------------------------------------------
    model.loginBtnText = ["本机号码一键登录", 0xFFFFFFFF, 16];
    // Android 登录按钮背景 (selector xml 或 png)
    model.loginBtnBgImg_android = "login_btn_bg";
    // iOS 登录按钮背景 [正常, 失效, 高亮]
    model.loginBtnBgImgs_ios = ["login_btn_bg", "login_btn_bg", "login_btn_bg"];

    // ------------------------------------------------------------
    // 4. 协议相关设置 (必须配置)
    // ------------------------------------------------------------
    model.checkBoxImages = ["checkbox_unchecked", "checkbox_checked"]; // 原生图片名
    model.checkBoxIsChecked = false; // 默认不勾选
    model.checkBoxWH = 20.0; // Checkbox 大小
    model.checkBoxIsHidden = false;

    model.privacyColors = [0xFF999999, 0xFF007AFF]; // [常规文字颜色, 协议链接颜色]
    model.privacyAlignment = UMTextAlignment.Center; // 协议文案居中
    model.privacyPreText = "登录即同意";
    model.privacySufText = "并授权本机号码登录";

    model.privacyOne = ["用户协议", "https://www.example.com/terms"];
    model.privacyTwo = ["隐私政策", "https://www.example.com/privacy"];

    // ------------------------------------------------------------
    // 5. 切换账号按钮设置
    // ------------------------------------------------------------
    model.changeBtnTitle = ["切换其他账号登录", 0xFF666666, 14];
    model.changeBtnIsHidden = false;

    // ------------------------------------------------------------
    // 布局坐标设置 (难点)
    // Android: [x, y1, y2, w, h]  (x=0水平居中, -1为自适应)
    // iOS: [x, y, w, h]
    // ------------------------------------------------------------
    if (Platform.isIOS) {
      // iOS 布局 (基于 pt)
      // 假设 Logo 宽高 100，居中 x = (ScreenW - 100) / 2
      // SDK 会自动处理居中，这里主要控制 y 轴

      model.navTitleFrame_ios = [0, 0, 0, 0]; // 默认

      // Logo: y=100, w=100, h=100
      model.logoFrame = [(375-100)/2, 100, 100, 100];

      // 号码: y=220
      model.numberFrame = [0, 220, 375, 30];

      // 登录按钮: y=280
      model.loginBtnFrame = [40, 280, 295, 48];

      // 切换账号: y=350
      model.changeBtnFrame = [0, 350, 375, 40];

      // 协议栏: 放在底部 y=500 (或使用负数表示距离底部)
      model.privacyFrame = [40, 500, 295, 100];

    } else {
      // Android 布局 (基于 dp)
      // x=0 表示水平居中

      model.navBackButtonFrame = [10, 10, 20, 20];

      // Logo: 距离顶部 80dp
      model.logoFrame = [0, 80, -1, 100, 100];

      // 号码: 距离顶部 190dp
      model.numberFrame = [0, 190, -1, -1];

      // 登录按钮: 距离顶部 250dp
      model.loginBtnFrame = [0, 250, -1, 300, 48];

      // 切换账号: 距离顶部 320dp
      model.changeBtnFrame = [0, 320, -1, -1];

      // 协议栏: 距离底部 20dp (y1=-1, y2=20)
      model.privacyFrame = [0, -1, 20, -1];
    }

    return model;
  }
}