import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluwx/fluwx.dart';
import '../../../../di_container.dart'; // Import to get the global fluwx instance
import '../provider/vip_viewmodel.dart';
import '../../data/models/vip_info_model.dart';

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
      _viewModel.fetchVipList(1);
    });

    // --- CORRECT fluwx LISTENER FOR YOUR VERSION ---
    // Use the `addSubscriber` method on the global fluwx instance.
    _paymentSubscription = fluwx.addSubscriber((response) {
      // The response can be of different types, we only care about PaymentResponse.
      if (response is WeChatPaymentResponse) {
        if (response.isSuccessful ?? false) {
          debugPrint("WeChat Pay Success Callback!");
          _viewModel.handlePurchaseSuccess();
        } else {
          debugPrint("WeChat Pay Failed Callback: ${response.errCode} - ${response.errStr}");
          _viewModel.handlePurchaseFailure(response.errStr ?? "支付失败或取消");
        }
      }
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onVipStateChanged);
    _paymentSubscription?.cancel(); // The cancelable object handles removal.
    super.dispose();
  }

  /// Listens for one-time events from the ViewModel to show SnackBars or navigate.
  void _onVipStateChanged() {
    if (!mounted) return;
    if (_viewModel.event == VipEvent.purchaseSuccess) {
      _viewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支付成功！'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true); // Pop with a success flag
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
              color: const Color(0xFFE3F2FD),
              // child: Image.asset('assets/images/vip_background.png', ...),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 10,
            child: const BackButton(color: Colors.black),
          ),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Expanded(
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(VipViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(viewModel.errorMessage!),
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
          const SizedBox(height: 24),
          _buildPackageGrid(viewModel),
          const SizedBox(height: 24),
          _buildInfoBox(),
          const SizedBox(height: 24),
          _buildPaymentMethods(viewModel),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVipTypeTabs(VipViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, left: 16, right: 16),
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
        onTap: isSelected ? null : () => viewModel.fetchVipList(type),
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
                Text('¥ ${package.price}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                if (originalPrice != null && originalPrice.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('¥$originalPrice', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
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

    return Column(
      children: [
        _buildPaymentButton(viewModel, title: '微信支付', icon: Icons.wechat, iconColor: Colors.green, method: PaymentMethod.wechat),
        const SizedBox(height: 12),
        _buildPaymentButton(viewModel, title: '支付宝支付', icon: Icons.account_balance_wallet_rounded, iconColor: Colors.blue, method: PaymentMethod.alipay),
      ],
    );
  }

  Widget _buildPaymentButton(VipViewModel viewModel, {required String title, required IconData icon, required Color iconColor, required PaymentMethod method}) {
    final isSelected = viewModel.selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => viewModel.selectPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.blueAccent : Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildBottomBar(VipViewModel viewModel, double bottomPadding) {
    final isLoading = viewModel.state == VipState.loading;

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
                  TextSpan(text: '《会员服务协议》', style: const TextStyle(color: Colors.blueAccent), recognizer: TapGestureRecognizer()..onTap = () {}),
                ],
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: (isLoading || !viewModel.isPayButtonEnabled) ? null : () => viewModel.purchaseVip(),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blueAccent,
            disabledBackgroundColor: const Color(0xFFC2D9FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('立即支付', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}