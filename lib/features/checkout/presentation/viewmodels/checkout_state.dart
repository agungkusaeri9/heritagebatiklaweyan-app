import '../../../cart/data/models/cart_item_model.dart';
import '../../../store/data/models/payment_method_model.dart';
import '../../data/models/checkout_result_model.dart';
import '../../data/models/customer_address_model.dart';
import '../../data/models/shipping_type_model.dart';

enum CheckoutStatus { initial, loading, success, error }

class CheckoutState {
  final CheckoutStatus status;
  final String? errorMessage;
  final List<CustomerAddressModel> addresses;
  final CustomerAddressModel? selectedAddress;
  final List<ShippingTypeModel> shippingTypes;
  final ShippingTypeModel? selectedShippingType;
  final List<PaymentMethodModel> paymentMethods;
  final PaymentMethodModel? selectedPaymentMethod;
  final List<CartItemModel> items;
  final bool isSubmitting;
  final bool isLoadingShipping;
  final CheckoutResultModel? checkoutResult;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.errorMessage,
    this.addresses = const [],
    this.selectedAddress,
    this.shippingTypes = const [],
    this.selectedShippingType,
    this.paymentMethods = const [],
    this.selectedPaymentMethod,
    this.items = const [],
    this.isSubmitting = false,
    this.isLoadingShipping = false,
    this.checkoutResult,
  });

  bool get isLoading => status == CheckoutStatus.loading;
  bool get isSuccess => status == CheckoutStatus.success;
  bool get isError => status == CheckoutStatus.error;

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + (item.productPrice * item.qty));

  double get shippingFee => selectedShippingType?.fee ?? 0.0;

  double get totalAmount => subtotal + shippingFee;

  String get formattedSubtotal => formatRupiah(subtotal);
  String get formattedShippingFee =>
      shippingFee == 0 ? 'Free' : formatRupiah(shippingFee);
  String get formattedTotalAmount => formatRupiah(totalAmount);

  CheckoutState copyWith({
    CheckoutStatus? status,
    String? errorMessage,
    List<CustomerAddressModel>? addresses,
    CustomerAddressModel? selectedAddress,
    List<ShippingTypeModel>? shippingTypes,
    ShippingTypeModel? selectedShippingType,
    List<PaymentMethodModel>? paymentMethods,
    PaymentMethodModel? selectedPaymentMethod,
    List<CartItemModel>? items,
    bool? isSubmitting,
    bool? isLoadingShipping,
    CheckoutResultModel? checkoutResult,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      shippingTypes: shippingTypes ?? this.shippingTypes,
      selectedShippingType: selectedShippingType ?? this.selectedShippingType,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      items: items ?? this.items,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingShipping: isLoadingShipping ?? this.isLoadingShipping,
      checkoutResult: checkoutResult ?? this.checkoutResult,
    );
  }
}
