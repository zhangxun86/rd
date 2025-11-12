import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/vip_viewmodel.dart';
import '../../data/models/vip_info_model.dart';

class VipPage extends StatefulWidget {
  const VipPage({super.key});
  @override
  _VipPageState createState() => _VipPageState();
}

class _VipPageState extends State<VipPage> {
  @override
  void initState() {
    super.initState();
    // Fetch the data for the default tab (Regular VIP) when the page is first loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VipViewModel>().fetchVipList(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VipViewModel>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      // We use a Stack to layer the background image, back button, and main content.
      body: Stack(
        children: [
          // Layer 1: Background Image/Color
          Positioned.fill(
            child: Container(
              // Using a solid color as a fallback for the background image.
              color: const Color(0xFFE3F2FD), // A light blue background
              // child: Image.asset(
              //   'assets/images/vip_background.png', // Replace with your actual background image asset
              //   fit: BoxFit.contain,
              //   alignment: Alignment.topCenter,
              // ),
            ),
          ),

          // Layer 2: Back Button, positioned within the safe area.
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 10,
            child: const BackButton(color: Colors.black), // Changed to black for better visibility on light background
          ),

          // Layer 3: Main Content Card that slides up from the bottom.
          Column(
            children: [
              // This Spacer pushes the content card down. Adjust the flex value to control the height of the top banner.
              const Spacer(flex: 3),
              Expanded(
                flex: 7,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      )
                    ],
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

  /// Builds the main content area, which shows a loader, error, or the VIP packages.
  Widget _buildContent(VipViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null) {
      return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(viewModel.errorMessage!),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => viewModel.fetchVipList(viewModel.currentVipType),
                child: const Text('重试'),
              )
            ],
          )
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
          const SizedBox(height: 24), // Add extra padding at the bottom
        ],
      ),
    );
  }

  /// Builds the "普通会员" and "全球会员" tabs.
  Widget _buildVipTypeTabs(VipViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, left: 16, right: 16),
      child: Row(
        children: [
          _buildTab(viewModel, title: '普通会员', type: 1),
          const SizedBox(width: 16),
          _buildTab(viewModel, title: '全球会员', type: 2),
        ],
      ),
    );
  }

  /// Helper to build a single tab.
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

  /// Builds the grid of selectable VIP packages.
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

  /// Helper to build a single package card.
  Widget _buildPackageCard(VipViewModel viewModel, {required PriceListItemModel package, required bool isSelected}) {
    // Extracting the duration from the name (e.g., "年卡", "季卡", "月卡")
    String duration = package.name.replaceAll("SVIP", "").replaceAll("VIP", "").trim();
    // Extracting the original price from the note
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(package.tag!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(duration, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('¥ ${package.price}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  if (originalPrice != null) ...[
                    const SizedBox(height: 4),
                    if (originalPrice != null && originalPrice.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '¥$originalPrice', // Keep the ¥ symbol for visual consistency
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the info box below the packages.
  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'VIP享每日5小时远控时长',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54),
      ),
    );
  }

  /// Builds the selectable payment method buttons.
  Widget _buildPaymentMethods(VipViewModel viewModel) {
    return Column(
      children: [
        _buildPaymentButton(viewModel, title: '微信支付', icon: Icons.wechat, iconColor: Colors.green, method: PaymentMethod.wechat),
        const SizedBox(height: 12),
        _buildPaymentButton(viewModel, title: '支付宝支付', icon: Icons.account_balance_wallet_rounded, iconColor: Colors.blue, method: PaymentMethod.alipay),
      ],
    );
  }

  /// Helper to build a single payment method button.
  Widget _buildPaymentButton(VipViewModel viewModel, {required String title, required IconData icon, required Color iconColor, required PaymentMethod method}) {
    final isSelected = viewModel.selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => viewModel.selectPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.blueAccent : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the bottom bar with the agreement checkbox and payment button.
  Widget _buildBottomBar(VipViewModel viewModel, double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24, height: 24,
                child: Checkbox(
                  value: viewModel.agreedToTerms,
                  onChanged: (val) => viewModel.setAgreement(val ?? false),
                ),
              ),
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
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: viewModel.isPayButtonEnabled ? () { /* TODO: Implement payment logic */ } : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blueAccent,
              disabledBackgroundColor: const Color(0xFFC2D9FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('立即支付', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}