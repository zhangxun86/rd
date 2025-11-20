/// 统一管理 App 中的所有静态链接
class AppUrls {
  // 私有构造函数，防止被实例化
  AppUrls._();

  // --- 基础官网地址 (如果协议都在官网) ---
  static const String _baseUrl = 'https://www.your-website.com';

  // --- 协议与政策 ---

  // 用户协议
  static const String userAgreement = '$_baseUrl/terms.html';

  // 隐私政策
  static const String privacyPolicy = '$_baseUrl/privacy.html';

  // --- 其他文档 ---

  // 用户行为规范
  static const String behaviorRules = '$_baseUrl/rules.html';

  // 证件信息
  static const String licenseInfo = '$_baseUrl/license.html';

  // 会员服务协议 (VIP页面用到)
  static const String vipServiceAgreement = '$_baseUrl/vip-terms.html';

  // 帮助中心 (如果有)
  static const String helpCenter = '$_baseUrl/help';
}