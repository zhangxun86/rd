import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/app_urls.dart';
import 'package:package_info_plus/package_info_plus.dart'; // 用于获取版本号
import '../../../../common/routes.dart'; // 用于跳转问题反馈等

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      // 组合版本号，例如: v1.4.2.60 (version + buildNumber)
      // 如果您只想显示主版本，可以只用 info.version
      _version = 'v${info.version}.${info.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于我们'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: Colors.grey[50], // 背景色
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // --- 1. App Icon & Version ---
            _buildAppInfo(),
            const SizedBox(height: 40),
            // --- 2. Menu List ---
            _buildMenuList(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          // App Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // 阴影效果，让图标稍微浮起
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              image: const DecorationImage(
                // 这里使用项目 assets 中的 logo，通常与 App 图标一致
                // 如果您的 logo 路径不同，请修改这里，例如 'assets/icon.png'
                image: AssetImage('assets/logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Version Text
          Text(
            _version,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildMenuItem(title: '用户协议', onTap: () {
              // TODO: 跳转到用户协议 WebView
              _navigateToWebView(context, '用户协议', AppUrls.userAgreement);
            }),
            _buildDivider(),
            _buildMenuItem(title: '隐私政策', onTap: () {
              // TODO: 跳转到隐私政策 WebView
              _navigateToWebView(context, '隐私政策', AppUrls.privacyPolicy);
            }),
            _buildDivider(),
            _buildMenuItem(title: '用户行为规范', onTap: () {
              _navigateToWebView(context, '用户行为规范', AppUrls.behaviorRules);
            }),
            _buildDivider(),
            _buildMenuItem(title: '证件信息', isLast: true, onTap: () {
              _navigateToWebView(context, '证件信息', AppUrls.licenseInfo);
            }),
            _buildDivider(),
            _buildMenuItem(title: '个人信息收集与使用', onTap: () {
              _navigateToWebView(context, '个人信息收集与使用', AppUrls.privacyPolicy);
            }),
            _buildDivider(),
            _buildMenuItem(title: '个人第三方信息共享清单', onTap: () {
              _navigateToWebView(context, '个人第三方信息共享清单', AppUrls.privacyPolicy);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))
            : const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)), // 只有第一个需要上圆角，这里简化处理，中间的点击水波纹也不会溢出
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: Color(0xFFEEEEEE), // 浅灰色分割线
      indent: 20, // 左侧缩进，符合截图风格
      endIndent: 0,
    );
  }

  // 辅助方法：跳转到 WebView
  void _navigateToWebView(BuildContext context, String title, String url) {
    Navigator.of(context).pushNamed(
      AppRoutes.webview,
      arguments: {'title': title, 'url': url},
    );
  }
}