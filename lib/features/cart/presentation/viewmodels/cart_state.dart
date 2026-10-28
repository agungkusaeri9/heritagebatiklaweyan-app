import '../../data/models/cart_item_model.dart';
import '../../data/models/cart_summary_model.dart';

enum CartStatus { initial, loading, success, error }

class CartState {
  final CartStatus status;
  final bool isRefreshing;
  final bool isCheckingOut;
  final String? errorMessage;
  final List<CartItemModel> items;
  final CartSummaryModel summary;
  final Set<int> updatingItemIds;
  final Set<int> deletingItemIds;
  final String appliedPromoCode;
  final double deliveryFee;
  final double discount;

  const CartState({
    this.status = CartStatus.initial,
    this.isRefreshing = false,
    this.isCheckingOut = false,
    this.errorMessage,
    this.items = const [],
    this.summary = const CartSummaryModel.empty(),
    this.updatingItemIds = const {},
    this.deletingItemIds = const {},
    this.appliedPromoCode = '',
    this.deliveryFee = 15000.0,
    this.discount = 0.0,
  });

  bool get isLoading => status == CartStatus.loading;
  bool get isSuccess => status == CartStatus.success;
  bool get isError => status == CartStatus.error;
  bool get isEmpty => !isLoading && items.isEmpty;

  /// Total kuantitas barang dalam keranjang
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.qty);

  /// Subtotal harga produk murni
  double get calculatedSubtotal =>
      items.fold(0.0, (sum, item) => sum + (item.productPrice * item.qty));

  /// Ongkos kirim efektif (0 jika keranjang kosong)
  double get effectiveDeliveryFee => items.isEmpty ? 0.0 : deliveryFee;

  /// Potongan diskon efektif (maksimal sebesar subtotal)
  double get effectiveDiscount =>
      items.isEmpty ? 0.0 : (discount > calculatedSubtotal ? calculatedSubtotal : discount);

  /// Total akhir setelah ongkir dan diskon
  double get calculatedTotalCost =>
      items.isEmpty ? 0.0 : (calculatedSubtotal + effectiveDeliveryFee - effectiveDiscount);

  /// Helper format tampilan mata uang
  String get formattedSubtotal => formatRupiah(calculatedSubtotal);
  String get formattedDeliveryFee =>
      effectiveDeliveryFee == 0 ? 'Free' : formatRupiah(effectiveDeliveryFee);
  String get formattedDiscount =>
      effectiveDiscount == 0 ? 'Rp 0' : '-${formatRupiah(effectiveDiscount)}';
  String get formattedTotalCost => formatRupiah(calculatedTotalCost);

  bool isItemUpdating(int cartId) => updatingItemIds.contains(cartId);
  bool isItemDeleting(int cartId) => deletingItemIds.contains(cartId);

  CartState copyWith({
    CartStatus? status,
    bool? isRefreshing,
    bool? isCheckingOut,
    String? errorMessage,
    List<CartItemModel>? items,
    CartSummaryModel? summary,
    Set<int>? updatingItemIds,
    Set<int>? deletingItemIds,
    String? appliedPromoCode,
    double? deliveryFee,
    double? discount,
  }) {
    return CartState(
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      errorMessage: errorMessage,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      updatingItemIds: updatingItemIds ?? this.updatingItemIds,
      deletingItemIds: deletingItemIds ?? this.deletingItemIds,
      appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
    );
  }
}
