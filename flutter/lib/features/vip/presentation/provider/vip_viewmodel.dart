import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/vip_info_model.dart';
import '../../domain/repositories/vip_repository.dart';

enum PaymentMethod { none, wechat, alipay }

class VipViewModel extends ChangeNotifier {
  final VipRepository _vipRepository;
  VipViewModel(this._vipRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<PriceListItemModel> _priceList = [];
  List<PriceListItemModel> get priceList => _priceList;

  int _currentVipType = 1; // 1: 普通会员, 2: 全球会员
  int get currentVipType => _currentVipType;

  int? _selectedPackageId;
  int? get selectedPackageId => _selectedPackageId;

  PaymentMethod _selectedPaymentMethod = PaymentMethod.wechat; // Default to WeChat
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;

  bool _agreedToTerms = false;
  bool get agreedToTerms => _agreedToTerms;

  /// A computed property to determine if the payment button should be enabled.
  bool get isPayButtonEnabled => _selectedPackageId != null && _agreedToTerms;

  /// Fetches the list of VIP packages for a given [type].
  Future<void> fetchVipList(int type) async {
    _isLoading = true;
    _errorMessage = null;
    _currentVipType = type;
    _selectedPackageId = null; // Reset selection when switching tabs
    notifyListeners();

    final result = await _vipRepository.getVipList(type);

    _isLoading = false;

    if (result is Success) {
      _priceList = (result as Success).value.priceList;
      _errorMessage = null;
    } else if (result is Failure) {
      // --- THIS IS THE FIX ---
      final exception = (result as Failure).exception;
      if (exception is ApiException) {
        // If it's our custom exception, we can safely access its message.
        _errorMessage = exception.message;
      } else {
        // For any other type of exception, use its toString() method.
        _errorMessage = "An unexpected error occurred: ${exception.toString()}";
      }
      // --- END OF FIX ---
      _priceList = []; // Clear the list on error
    }
    notifyListeners();
  }

  /// Selects a VIP package by its [packageId].
  void selectPackage(int packageId) {
    _selectedPackageId = packageId;
    notifyListeners();
  }

  /// Selects a payment method.
  void selectPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  /// Updates the agreement checkbox state.
  void setAgreement(bool value) {
    _agreedToTerms = value;
    notifyListeners();
  }
}