import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/vip_info_model.dart';
import '../../data/models/wechat_pay_info_model.dart';
import '../../domain/repositories/vip_repository.dart';
import '../../domain/services/payment_service.dart';

enum PaymentMethod { none, wechat, alipay }
// The enum below was simplified in my previous response, I will revert to your original one.
// enum VipState { initial, loading, loaded, error }
enum VipEvent { none, purchaseInitiated, purchaseSuccess, purchaseError }

class VipViewModel extends ChangeNotifier {
  final VipRepository _vipRepository;
  final PaymentService _paymentService = PaymentService();

  VipViewModel(this._vipRepository);

  // --- Using your original state variables ---
  /// true only when fetching the VIP package list.
  bool _isLoadingList = false;
  bool get isLoadingList => _isLoadingList;

  /// An error message specifically for when fetching the list fails.
  String? _listErrorMessage;
  String? get listErrorMessage => _listErrorMessage;

  /// true only when creating the order and calling the payment SDK.
  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  /// An error message for purchase failures, primarily for the SnackBar.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  // ---

  List<PriceListItemModel> _priceList = [];
  List<PriceListItemModel> get priceList => _priceList;

  int _currentVipType = 1;
  int get currentVipType => _currentVipType;

  int? _selectedPackageId;
  int? get selectedPackageId => _selectedPackageId;

  PaymentMethod _selectedPaymentMethod = PaymentMethod.wechat;
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;

  bool _agreedToTerms = false;
  bool get agreedToTerms => _agreedToTerms;

  bool get isPayButtonEnabled => _selectedPackageId != null && _agreedToTerms;

  VipEvent _event = VipEvent.none;
  VipEvent get event => _event;

  // --- START: MODIFICATION ---
  /// A new getter to find and return the full `PriceListItemModel`
  /// for the currently selected package. Returns null if none is selected.
  PriceListItemModel? get selectedPackage {
    if (_selectedPackageId == null) {
      return null;
    }
    try {
      // Find the package in the list that matches the selected ID.
      return _priceList.firstWhere((p) => p.id == _selectedPackageId);
    } catch (e) {
      // This might happen if the list changes after a selection was made.
      // Returning null is a safe fallback.
      return null;
    }
  }
  // --- END: MODIFICATION ---

  void consumeEvent() {
    _event = VipEvent.none;
  }

  Future<void> fetchVipList(int type) async {
    _isLoadingList = true;
    _listErrorMessage = null;
    _currentVipType = type;
    _selectedPackageId = null;
    notifyListeners();

    final result = await _vipRepository.getVipList(type);
    _isLoadingList = false;

    if (result is Success<VipInfoModel, ApiException>) {
      _priceList = result.value.priceList;
      _listErrorMessage = null;
    } else if (result is Failure<VipInfoModel, ApiException>) {
      final exception = result.exception;
      _listErrorMessage = exception.message;
      _priceList = [];
    }
    notifyListeners();
  }

  void selectPackage(int packageId) {
    _selectedPackageId = packageId;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void setAgreement(bool value) {
    _agreedToTerms = value;
    notifyListeners();
  }

  Future<void> purchaseVip() async {
    if (!isPayButtonEnabled || _isPurchasing) return;

    _isPurchasing = true;
    _errorMessage = null;
    notifyListeners();

    int payType;
    switch (_selectedPaymentMethod) {
      case PaymentMethod.wechat: payType = 2; break;
      case PaymentMethod.alipay: payType = 3; break;
      default:
        _isPurchasing = false;
        _errorMessage = "无效的支付方式";
        _event = VipEvent.purchaseError;
        notifyListeners();
        return;
    }

    final result = await _vipRepository.buyVip(
      packageId: _selectedPackageId!,
      payType: payType,
    );

    if (result is Success<dynamic, ApiException>) {
      final dynamic orderData = result.value;
      try {
        if (_selectedPaymentMethod == PaymentMethod.alipay && orderData is String) {
          final paymentResult = await _paymentService.payWithAlipay(orderData);
          if (paymentResult['resultStatus']?.toString() == '9000') {
            // Wait for the config to be updated before showing success
            await handlePurchaseSuccess();
          } else {
            handlePurchaseFailure(paymentResult['memo']?.toString() ?? "支付失败或已取消");
          }
        }
        else if (_selectedPaymentMethod == PaymentMethod.wechat && orderData is Map<String, dynamic>) {
          final wechatPayInfo = WeChatPayInfoModel.fromJson(orderData);
          await _paymentService.payWithWeChat(wechatPayInfo);
          _event = VipEvent.purchaseInitiated;
        }
        else {
          throw Exception("支付数据格式不正确");
        }
      } catch (e) {
        handlePurchaseFailure(e.toString());
      }
    } else if (result is Failure<dynamic, ApiException>) {
      // The type needs to be specified for the compiler to know about `exception`.
      final failure = result;
      // Use the helper to handle failure
      handlePurchaseFailure(failure.exception.message);
    }

    // Only reset purchasing state if it's not a WeChat payment (which waits for a callback)
    if (_selectedPaymentMethod != PaymentMethod.wechat) {
      _isPurchasing = false;
    }
    notifyListeners();
  }

  // --- MODIFICATION: Updated to async and added server config fetch ---
  /// Called when payment is successful (either from Alipay sync result or WeChat async callback).
  Future<void> handlePurchaseSuccess() async {
    // 1. Fetch and apply latest server config immediately after purchase.
    // This ensures the user gets the updated relay/id server info associated with their VIP status.
    await _vipRepository.fetchAndApplyServerConfig();

    // 2. Update state to success.
    _isPurchasing = false;
    _event = VipEvent.purchaseSuccess;
    notifyListeners();
  }
  // --- END MODIFICATION ---

  void handlePurchaseFailure(String message) {
    _isPurchasing = false;
    _errorMessage = message;
    _event = VipEvent.purchaseError;
    notifyListeners();
  }
}