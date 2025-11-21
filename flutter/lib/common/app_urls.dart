/// 统一管理 App 中的所有静态链接
class AppUrls {
  // 私有构造函数，防止被实例化
  AppUrls._();

  // --- 基础官网地址 (如果协议都在官网) ---
  static const String _baseUrl = 'https://p-api.fykp88.cn';

  // --- 协议与政策 ---

  // 用户协议
  static const String userAgreement = '$_baseUrl/html_article/61/281.html';

  // 隐私政策
  static const String privacyPolicy = '$_baseUrl/html_article/61/283.html';

  // --- 其他文档 ---

  // 用户行为规范
  static const String behaviorRules = '$_baseUrl/html_article/61/285.html';

  // 证件信息
  static const String licenseInfo = '$_baseUrl/html_article/61/284.html';

  // 会员服务协议 (VIP页面用到)
  static const String vipServiceAgreement = '$_baseUrl/html_article/61/286.html';

  // 帮助中心 (如果有)
  static const String helpCenter = '$_baseUrl/help';

  static const String service = 'https://p-api.zzhh0088.com/gochat?ctype=13';


}