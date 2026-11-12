import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../store/data/models/payment_method_model.dart';
import '../../data/models/checkout_result_model.dart';
import '../../data/models/customer_address_model.dart';
import '../../data/models/shipping_type_model.dart';
import '../../data/repositories/checkout_repository.dart';
import 'checkout_providers.dart';
import 'checkout_state.dart';

class CheckoutViewModel extends Notifier<CheckoutState> {
  late final CheckoutRepository _repository;

  @override
  CheckoutState build() {
    _repository = ref.watch(checkoutRepositoryProvider);
    return const CheckoutState();
  }

  /// Inisialisasi data checkout: memuat alamat tersimpan & metode pembayaran.
  /// Jika alamat primary ditemukan, otomatis menjalankan cek ongkir via RajaOngkir.
  /// Jika alamat belum ada, daftar opsi pengiriman (shippingTypes) dikosongkan.
  Future<void> initCheckout(List<CartItemModel> cartItems) async {
    state = state.copyWith(
      status: CheckoutStatus.loading,
      errorMessage: null,
      items: cartItems,
      shippingTypes: const [],
      selectedShippingType: null,
    );

    try {
      final results = await Future.wait([
        _repository.getAddresses(),
        _repository.getPaymentMethods(),
      ]);

      final addresses = results[0] as List<CustomerAddressModel>;
      final paymentMethods = results[1] as List<PaymentMethodModel>;

      // Prioritaskan alamat utama jika ada
      CustomerAddressModel? defaultAddress = state.selectedAddress;
      if (defaultAddress == null && addresses.isNotEmpty) {
        defaultAddress = addresses.firstWhere(
          (a) => a.isPrimary,
          orElse: () => addresses.first,
        );
      }

      // Prioritaskan payment method yang sudah dipilih atau yang pertama
      PaymentMethodModel? defaultPayment = state.selectedPaymentMethod;
      if (defaultPayment == null && paymentMethods.isNotEmpty) {
        defaultPayment = paymentMethods.first;
      }

      state = state.copyWith(
        status: CheckoutStatus.success,
        addresses: addresses,
        selectedAddress: defaultAddress,
        paymentMethods: paymentMethods,
        selectedPaymentMethod: defaultPayment,
        errorMessage: null,
      );

      // Jika alamat sudah ada (primary / selected), jalankan cek ongkir
      if (defaultAddress != null) {
        await calculateShippingForAddress(defaultAddress, cartItems: cartItems);
      } else {
        // Jika belum ada alamat, pastikan shipping type kosong tanpa pilihan
        state = state.copyWith(
          shippingTypes: const [],
          selectedShippingType: null,
        );
      }
    } catch (e, stack) {
      AppLogger.e('Gagal memuat data checkout', error: e, stackTrace: stack);
      state = state.copyWith(
        status: CheckoutStatus.error,
        errorMessage: 'Gagal memuat data checkout. Silakan coba lagi.',
      );
    }
  }

  /// Menghitung ongkir untuk alamat pengiriman tertentu via RajaOngkir
  Future<void> calculateShippingForAddress(
    CustomerAddressModel address, {
    List<CartItemModel>? cartItems,
  }) async {
    final items = cartItems ?? state.items;
    final destination = address.subdistrictId ?? address.cityId;

    if (destination == null || destination == 0) {
      AppLogger.w('Alamat tidak memiliki subdistrict_id / city_id valid.');
      state = state.copyWith(
        shippingTypes: const [],
        selectedShippingType: null,
      );
      return;
    }

    // Hitung total berat dalam gram (min. 1000 atau berat produk terhitung)
    int totalWeight = items.fold<int>(0, (sum, item) {
      final w = item.totalWeight > 0
          ? item.totalWeight
          : (item.weight > 0 ? item.weight * item.qty : 350 * item.qty);
      return sum + w;
    });

    if (totalWeight <= 0) totalWeight = 1000;

    state = state.copyWith(isLoadingShipping: true);

    try {
      final shippingTypes = await _repository.checkShippingCost(
        destination: destination,
        weight: totalWeight,
      );

      if (shippingTypes.isNotEmpty) {
        // By default pilih yang Reguler (REG), jika tidak ada pilih yang pertama
        final defaultShipping = shippingTypes.firstWhere(
          (s) {
            final name = s.name.toLowerCase();
            final code = s.code.toLowerCase();
            final desc = (s.description ?? '').toLowerCase();
            return name.contains('reg') || code.contains('reg') || desc.contains('reguler');
          },
          orElse: () => shippingTypes.first,
        );

        state = state.copyWith(
          shippingTypes: shippingTypes,
          selectedShippingType: defaultShipping,
          isLoadingShipping: false,
        );
      } else {
        state = state.copyWith(
          shippingTypes: const [],
          selectedShippingType: null,
          isLoadingShipping: false,
        );
      }
    } catch (e, stack) {
      AppLogger.e('Gagal menghitung ongkir', error: e, stackTrace: stack);
      state = state.copyWith(
        shippingTypes: const [],
        selectedShippingType: null,
        isLoadingShipping: false,
      );
    }
  }

  /// Memilih alamat pengiriman langsung (otomatis hitung ulang ongkir)
  void selectAddress(CustomerAddressModel address) {
    state = state.copyWith(selectedAddress: address);
    calculateShippingForAddress(address);
  }

  /// Memilih kurir / tipe pengiriman langsung
  void selectShippingType(ShippingTypeModel shippingType) {
    state = state.copyWith(selectedShippingType: shippingType);
  }

  /// Memilih metode pembayaran langsung
  void selectPaymentMethod(PaymentMethodModel paymentMethod) {
    state = state.copyWith(selectedPaymentMethod: paymentMethod);
  }

  /// Menambahkan alamat baru melalui API dan langsung memilihnya serta hitung ongkir
  Future<bool> addNewAddress(
    Map<String, dynamic> data, {
    void Function(String message)? onError,
    void Function()? onSuccess,
  }) async {
    try {
      final createdAddress = await _repository.addAddress(data);

      final updatedAddresses = [createdAddress, ...state.addresses];
      state = state.copyWith(
        addresses: updatedAddresses,
        selectedAddress: createdAddress,
      );

      // Hitung ongkir untuk alamat yang baru ditambahkan
      calculateShippingForAddress(createdAddress);

      onSuccess?.call();
      return true;
    } catch (e, stack) {
      AppLogger.e('Gagal menambahkan alamat baru', error: e, stackTrace: stack);
      onError?.call('Gagal menyimpan alamat baru. Periksa data Anda.');
      return false;
    }
  }

  /// Memproses pesanan checkout ke backend API
  Future<CheckoutResultModel?> processCheckout({
    int? paymentMethodId,
    void Function(String message)? onError,
    void Function(CheckoutResultModel result)? onSuccess,
  }) async {
    final chosenPaymentMethodId = paymentMethodId ?? state.selectedPaymentMethod?.id;

    if (state.selectedAddress == null) {
      onError?.call('Silakan pilih alamat pengiriman terlebih dahulu.');
      return null;
    }

    if (state.selectedShippingType == null) {
      onError?.call('Silakan pilih tipe pengiriman terlebih dahulu.');
      return null;
    }

    if (chosenPaymentMethodId == null) {
      onError?.call('Silakan pilih metode pembayaran terlebih dahulu.');
      return null;
    }

    if (state.items.isEmpty) {
      onError?.call('Daftar pesanan Anda kosong.');
      return null;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final payload = {
        'address_id': state.selectedAddress!.id,
        'courier_id': state.selectedShippingType!.effectiveCourierId,
        'shipping_name': state.selectedShippingType!.name,
        'shipping_fee': state.selectedShippingType!.fee,
        'payment_method_id': chosenPaymentMethodId,
        'from_cart': true,
        'cart_item_ids': state.items.map((i) => i.id).toList(),
      };

      final result = await _repository.processCheckout(payload);

      ref.read(orderListViewModelProvider.notifier).updateOrderInState(result);

      state = state.copyWith(
        isSubmitting: false,
        checkoutResult: result,
      );

      onSuccess?.call(result);
      return result;
    } catch (e, stack) {
      AppLogger.e('Gagal menyelesaikan checkout', error: e, stackTrace: stack);
      state = state.copyWith(isSubmitting: false);
      onError?.call(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }
}
