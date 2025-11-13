import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/vip_info_model.dart';
import '../../data/models/wechat_pay_info_model.dart';
import '../../domain/repositories/vip_repository.dart';
import '../../domain/services/payment_service.dart';

enum PaymentMethod { none, wechat, alipay }
enum VipState { initial, loading, loaded, error }
enum VipEvent { none, purchaseInitiated, purchaseSuccess, purchaseError }

class VipViewModel extends ChangeNotifier {
  final VipRepository _vipRepository;
  final PaymentService _paymentService = PaymentService();

  VipViewModel(this._vipRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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

  VipState _state = VipState.initial;
  VipState get state => _state;

  VipEvent _event = VipEvent.none;
  VipEvent get event => _event;

  void consumeEvent() {
    _event = VipEvent.none;
  }

  Future<void> fetchVipList(int type) async {
    _isLoading = true;
    _errorMessage = null;
    _currentVipType = type;
    _selectedPackageId = null;
    notifyListeners();

    final result = await _vipRepository.getVipList(type);
    _isLoading = false;

    if (result is Success<VipInfoModel, ApiException>) {
      _priceList = result.value.priceList;
      _errorMessage = null;
    } else if (result is Failure<VipInfoModel, ApiException>) {
      final exception = result.exception;
      _errorMessage = exception.message;
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
    if (!isPayButtonEnabled) return;

    _state = VipState.loading;
    _errorMessage = null;
    notifyListeners();

    int payType;
    switch (_selectedPaymentMethod) {
      case PaymentMethod.wechat: payType = 2; break;
      case PaymentMethod.alipay: payType = 3; break;
      default:
        _state = VipState.error;
        _errorMessage = "无效的支付方式";
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
            handlePurchaseSuccess();
          } else {
            handlePurchaseFailure(paymentResult['memo']?.toString() ?? "支付失败或已取消");
          }
        }
        else if (_selectedPaymentMethod == PaymentMethod.wechat && orderData is Map<String, dynamic>) {
          final wechatPayInfo = WeChatPayInfoModel.fromJson(orderData);
          await _paymentService.payWithWeChat(wechatPayInfo);
          _state = VipState.loaded;
          _event = VipEvent.purchaseInitiated;
        }
        else {
          throw Exception("支付数据格式不正确");
        }
      } catch (e) {
        handlePurchaseFailure(e.toString());
      }

    } else if (result is Failure<dynamic, ApiException>) {
      _state = VipState.error;
      _event = VipEvent.purchaseError;
      final exception = result.exception;
      _errorMessage = exception.message;
    }
    notifyListeners();
  }

  void handlePurchaseSuccess() {
    _state = VipState.loaded;
    _event = VipEvent.purchaseSuccess;
    notifyListeners();
  }

  void handlePurchaseFailure(String message) {
    _state = VipState.error;
    _errorMessage = message;
    _event = VipEvent.purchaseError;
    notifyListeners();
  }
}