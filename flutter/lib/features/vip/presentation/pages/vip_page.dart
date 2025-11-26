import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluwx/fluwx.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher for launching tip URLs
import '../../../../common/app_urls.dart';
import '../../../../di_container.dart';
import '../provider/vip_viewmodel.dart';
import '../../data/models/vip_info_model.dart';
import '../../../../common/routes.dart'; // Import routes to use AppRoutes.webview

class VipPage extends StatefulWidget {
  const VipPage({super.key});
  @override
  _VipPageState createState() => _VipPageState();
}

class _VipPageState extends State<VipPage> {
  late final VipViewModel _viewModel;
  FluwxCancelable? _paymentSubscription;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<VipViewModel>();
    _viewModel.addListener(_onVipStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 获取路由参数
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      // 默认为 1 (普通会员)，如果参数指定了 2 (全球会员)，则使用 2
      final initialType = args?['initialType'] as int? ?? 1;

      // 加载对应类型的列表
      _viewModel.fetchVipList(initialType);
    });

    _paymentSubscription = fluwx.addSubscriber((response) {
      if (response is WeChatPaymentResponse) {
        if (response.isSuccessful ?? false) {
          _viewModel.handlePurchaseSuccess();
        } else {
          _viewModel.handlePurchaseFailure(response.errStr ?? "支付失败或取消");
        }
      }
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onVipStateChanged);
    _paymentSubscription?.cancel();
    super.dispose();
  }

  void _onVipStateChanged() {
    if (!mounted) return;
    if (_viewModel.event == VipEvent.purchaseSuccess) {
      _viewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支付成功！'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } else if (_viewModel.event == VipEvent.purchaseError) {
      _viewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage ?? '支付失败'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VipViewModel>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/vip_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 10,
            child: const BackButton(color: Colors.black),
          ),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.32),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                    ),
                    child: Column(
                      children: [
                        _buildVipTypeTabs(viewModel),
                        Expanded(child: _buildContent(viewModel)),
                        _buildBottomBar(viewModel, bottomPadding),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(VipViewModel viewModel) {
    if (viewModel.isLoadingList) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.listErrorMessage != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(viewModel.listErrorMessage!),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => viewModel.fetchVipList(viewModel.currentVipType),
            child: const Text('重试'),
          )
        ]),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          //const SizedBox(height: 24), // Using the padding from your original code
          _buildPackageGrid(viewModel),
          //const SizedBox(height: 14),

          // --- START: MODIFICATION ---
          _buildTipMessage(viewModel),
          // --- END: MODIFICATION ---

          const SizedBox(height: 14),
          _buildInfoBox(),
          const SizedBox(height: 14),
          _buildPaymentMethods(viewModel),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // --- START: MODIFICATION - New widget to display the tip message ---
  Widget _buildTipMessage(VipViewModel viewModel) {
    final selectedPackage = viewModel.selectedPackage;
    // If no package is selected or it doesn't have a tip message, return an empty widget.
    if (selectedPackage == null || selectedPackage.tipMsg == null || selectedPackage.tipMsg!.isEmpty) {
      return const SizedBox(height: 0.0);
    }

    final tipMsg = selectedPackage.tipMsg!;
    final tipUrl = selectedPackage.tipUrl;
    final isClickable = tipUrl != null && tipUrl.isNotEmpty;

    var textSpans = <TextSpan>[
      TextSpan(
        text: tipMsg,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
    ];

    if (isClickable) {
      textSpans.addAll([
        const TextSpan(text: ', '),
        TextSpan(
          text: '点击查看折算规则',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blueAccent,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              // Navigate to the WebViewPage
              Navigator.of(context).pushNamed(
                AppRoutes.webview,
                arguments: {
                  'url': tipUrl,
                  'title': '会员折算规则',
                },
              );
            },
        ),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text.rich(
        TextSpan(children: textSpans),
        textAlign: TextAlign.center,
      ),
    );
  }
  // --- END: MODIFICATION ---

  Widget _buildVipTypeTabs(VipViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(top: 14.0, left: 16, right: 16, bottom: 14),
      child: Row(children: [
        _buildTab(viewModel, title: '普通会员', type: 1),
        const SizedBox(width: 16),
        _buildTab(viewModel, title: '全球会员', type: 2),
      ]),
    );
  }

  Widget _buildTab(VipViewModel viewModel, {required String title, required int type}) {
    final isSelected = viewModel.currentVipType == type;
    return Expanded(
      child: GestureDetector(
        onTap: isSelected || viewModel.isLoadingList ? null : () => viewModel.fetchVipList(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: Colors.blueAccent) : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.blueAccent : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageGrid(VipViewModel viewModel) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: viewModel.priceList.length,
      itemBuilder: (context, index) {
        final package = viewModel.priceList[index];
        final isSelected = viewModel.selectedPackageId == package.id;
        return _buildPackageCard(viewModel, package: package, isSelected: isSelected);
      },
    );
  }

  Widget _buildPackageCard(VipViewModel viewModel, {required PriceListItemModel package, required bool isSelected}) {
    String duration = package.name.replaceAll("SVIP", "").replaceAll("VIP", "").trim();
    String? originalPrice = package.note;

    return GestureDetector(
      onTap: () => viewModel.selectPackage(package.id),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (package.tag != null && package.tag!.isNotEmpty)
              Positioned(
                top: -1, left: -1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(11), bottomRight: Radius.circular(12)),
                  ),
                  child: Text(package.tag!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(duration, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('¥ ${package.price}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                if (originalPrice != null && originalPrice.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('¥$originalPrice', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: const Text('VIP享每日5小时远控时长', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
    );
  }

  Widget _buildPaymentMethods(VipViewModel viewModel) {
    if (!Platform.isAndroid) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("支付功能仅在 Android 平台可用。", textAlign: TextAlign.center),
      ));
    }

    return Row(
      children: [
        Expanded(
          child: _buildPaymentButton(
            viewModel,
            title: '微信支付',
            icon: Icons.wechat,
            iconColor: Colors.green,
            method: PaymentMethod.wechat,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPaymentButton(
            viewModel,
            title: '支付宝支付',
            imageAsset: 'assets/images/alipay_icon.png',
            method: PaymentMethod.alipay,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton(
      VipViewModel viewModel, {
        required String title,
        required PaymentMethod method,
        IconData? icon,
        Color? iconColor,
        String? imageAsset,
      }) {
    assert(icon != null || imageAsset != null, 'Either icon or imageAsset must be provided.');
    assert(icon == null || imageAsset == null, 'Cannot provide both icon and imageAsset.');

    final isSelected = viewModel.selectedPaymentMethod == method;
    final selectedColor = const Color(0xFFE3F2FD);
    final unselectedColor = Colors.grey[100];
    final selectedBorder = Border.all(color: Colors.blueAccent, width: 1.5);

    Widget iconWidget;
    if (imageAsset != null) {
      iconWidget = Image.asset(imageAsset, width: 26, height: 26);
    } else {
      iconWidget = Icon(icon!, color: iconColor, size: 26);
    }

    return GestureDetector(
      onTap: () => viewModel.selectPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? selectedBorder : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(VipViewModel viewModel, double bottomPadding) {
    final isPurchasing = viewModel.isPurchasing;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          SizedBox(width: 24, height: 24, child: Checkbox(value: viewModel.agreedToTerms, onChanged: (val) => viewModel.setAgreement(val ?? false))),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '我已阅读并同意 ',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                children: [
                  TextSpan(text: '《会员服务协议》', style: const TextStyle(color: Colors.blueAccent), recognizer: TapGestureRecognizer()..onTap = () {
                    _navigateToWebView(context, '会员服务协议', AppUrls.vipServiceAgreement);
                  }),
                ],
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: (isPurchasing || !viewModel.isPayButtonEnabled) ? null : () => viewModel.purchaseVip(),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blueAccent,
            disabledBackgroundColor: const Color(0xFFC2D9FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: isPurchasing
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('立即支付', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  void _navigateToWebView(BuildContext context, String title, String url) {
    Navigator.of(context).pushNamed(
      AppRoutes.webview,
      arguments: {'title': title, 'url': url},
    );
  }
}