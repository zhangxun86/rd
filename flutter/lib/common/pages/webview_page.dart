import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// 1. 引入 Android 特有实现库
import 'package:webview_flutter_android/webview_flutter_android.dart';
// 2. 引入图片选择库
import 'package:image_picker/image_picker.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // 3. 初始化控制器
    // 为了支持 Android 的文件选择，我们需要先处理 AndroidWebViewController
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // 4. 针对 Android 平台设置文件选择回调
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true); // 可选：开启调试
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);

      // 关键代码：处理文件选择请求
      (controller.platform as AndroidWebViewController).setOnShowFileSelector(
        _androidFilePicker,
      );
    }

    _controller = controller;
  }

  /// 5. Android 文件选择处理函数
  Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
    final ImagePicker picker = ImagePicker();

    // 判断 H5 input 标签是否设置了 accept 属性只允许图片
    // params.acceptTypes 包含了 H5 中 accept 的内容，如 ['image/*']
    // 这里简单处理，只要触发就打开相册，你可以根据 params.mode 判断是单选还是多选

    try {
      // 如果是多选模式
      if (params.mode == FileSelectorMode.openMultiple) {
        final List<XFile> images = await picker.pickMultiImage();
        return images.map((e) => File(e.path).uri.toString()).toList();
      }
      // 单选模式
      else {
        // 这里默认打开相册，如果需要相机，可以使用 ImageSource.camera
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          return [File(image.path).uri.toString()];
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }

    // 如果用户取消选择或发生错误，返回空列表
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}