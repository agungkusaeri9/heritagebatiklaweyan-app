import '../../data/models/wishlist_item_model.dart';

enum WishlistStatus { initial, loading, success, error }

class WishlistState {
  final WishlistStatus status;
  final bool isToggling;
  final String? errorMessage;
  final List<WishlistItemModel> items;

  const WishlistState({
    this.status = WishlistStatus.initial,
    this.isToggling = false,
    this.errorMessage,
    this.items = const [],
  });

  bool get isLoading => status == WishlistStatus.loading;
  bool get isError => status == WishlistStatus.error;
  bool get isEmpty => !isLoading && items.isEmpty;
  int get total => items.length;

  /// ID produk (string) agar konsisten dengan pemakaian di UI (ProductItem.id).
  Set<String> get productIds => items.map((e) => e.productId.toString()).toSet();

  bool containsProductId(dynamic productId) =>
      productIds.contains(productId?.toString());

  WishlistState copyWith({
    WishlistStatus? status,
    bool? isToggling,
    String? errorMessage,
    bool clearError = false,
    List<WishlistItemModel>? items,
  }) {
    return WishlistState(
      status: status ?? this.status,
      isToggling: isToggling ?? this.isToggling,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      items: items ?? this.items,
    );
  }
}
