/// 统一管理 App 中的所有静态链接
class AppUrls {
  // 私有构造函数，防止被实例化
  AppUrls._();

  // --- 基础官网地址 (如果协议都在官网) ---
  static const String _baseUrl = 'https://p-api.fykp88.cn';

  // --- 协议与政策 ---

  // 用户协议
  static const String userAgreement = 'https://appapi.zly0808.cn/html_article/105/293.html';

  // 隐私政策
  static const String privacyPolicy = 'https://appapi.zly0808.cn/html_article/105/295.html';

  // --- 其他文档 ---

  // 用户行为规范
  static const String behaviorRules = 'https://appapi.zly0808.cn/html_article/105/297.html';

  // 证件信息
  static const String licenseInfo = 'https://appapi.zly0808.cn/html_article/105/296.html';

  // 会员服务协议 (VIP页面用到)
  static const String vipServiceAgreement = 'https://appapi.zly0808.cn/html_article/105/298.html';

  // 帮助中心 (如果有)
  static const String helpCenter = '$_baseUrl/help';

  static const String service = 'https://p-api.zzhh0088.com/gochat?ctype=13';

  //个人信息收集与使用清单
  static const String messageUse = 'https://appapi.zly0808.cn/html_article/105/301.html';

  //个人第三方信息共享清单
  static const String messageShare = 'https://appapi.zly0808.cn/html_article/105/300.html';


}