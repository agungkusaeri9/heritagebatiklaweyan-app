import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/normalize_media_url.dart';

/// Model item wishlist (produk favorit pengguna) dari backend.
class WishlistItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productSlug;
  final String? primaryImage;
  final double productPrice;
  final int stock;
  final bool isInStock;
  final bool isProductActive;
  final String? createdAt;

  const WishlistItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSlug,
    this.primaryImage,
    required this.productPrice,
    this.stock = 0,
    this.isInStock = true,
    this.isProductActive = true,
    this.createdAt,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    final stock = (json['stock'] as num?)?.toInt() ?? 0;
    return WishlistItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name']?.toString() ?? 'Produk Batik',
      productSlug: json['product_slug']?.toString(),
      primaryImage: normalizeMediaUrl(json['primary_image']),
      productPrice: (json['product_price'] as num?)?.toDouble() ?? 0.0,
      stock: stock,
      isInStock: json['is_in_stock'] == true || stock > 0,
      isProductActive: json['is_product_active'] != false,
      createdAt: json['created_at']?.toString(),
    );
  }

  String get formattedPrice => formatRupiah(productPrice);
}
