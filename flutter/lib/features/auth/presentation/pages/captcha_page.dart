import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CaptchaPage extends StatefulWidget {
  const CaptchaPage({super.key});

  @override
  State<CaptchaPage> createState() => _CaptchaPageState();
}

class _CaptchaPageState extends State<CaptchaPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final String htmlContent = await rootBundle.loadString('assets/index.html');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'testInterface',
        onMessageReceived: (JavaScriptMessage message) {
          print('验证成功，收到参数: ${message.message}');
          if (mounted) {
            Navigator.of(context).pop(message.message);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView 加载错误: ${error.description}');
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      )
    // --- THE FIX IS HERE ---
    // By providing a baseUrl, we set the WebView's origin, avoiding CORS issues.
      ..loadHtmlString(htmlContent, baseUrl: 'https://your-backend-domain.com');
    // You can replace 'your-backend-domain.com' with your actual domain for best practice.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : SizedBox(
          width: 320, // Give it a slightly larger width
          height: 400, // and height to ensure everything is visible
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}