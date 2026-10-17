import '../../data/models/faq_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../data/models/store_setting_model.dart';

/// State penampung data toko, metode pembayaran, dan FAQ di memory (Riverpod State)
class StoreState {
  final bool isLoading;
  final StoreSettingModel? storeSetting;
  final List<PaymentMethodModel> paymentMethods;
  final List<FaqModel> faqs;
  final String? errorMessage;

  const StoreState({
    this.isLoading = false,
    this.storeSetting,
    this.paymentMethods = const [],
    this.faqs = const [],
    this.errorMessage,
  });

  bool get hasStoreSetting => storeSetting != null;
  bool get hasPaymentMethods => paymentMethods.isNotEmpty;
  bool get hasFaqs => faqs.isNotEmpty;

  StoreState copyWith({
    bool? isLoading,
    StoreSettingModel? storeSetting,
    List<PaymentMethodModel>? paymentMethods,
    List<FaqModel>? faqs,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StoreState(
      isLoading: isLoading ?? this.isLoading,
      storeSetting: storeSetting ?? this.storeSetting,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      faqs: faqs ?? this.faqs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
