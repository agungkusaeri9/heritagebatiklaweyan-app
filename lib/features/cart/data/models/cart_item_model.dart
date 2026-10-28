import '../../../../core/utils/currency_formatter.dart';
export '../../../../core/utils/currency_formatter.dart';

/// Model untuk item produk di dalam keranjang
class CartItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productSlug;
  final String? primaryImage;
  final double productPrice;
  final int qty;
  final double total;
  final String? variantInfo;
  final int weight;
  final int totalWeight;
  final int stock;
  final bool isInStock;
  final bool isProductActive;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSlug,
    this.primaryImage,
    required this.productPrice,
    required this.qty,
    required this.total,
    this.variantInfo,
    this.weight = 0,
    this.totalWeight = 0,
    this.stock = 0,
    this.isInStock = true,
    this.isProductActive = true,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final price = (json['product_price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (json['qty'] as num?)?.toInt() ?? 1;
    final total = (json['total'] as num?)?.toDouble() ?? (price * quantity);
    final weight = (json['weight'] as num?)?.toInt() ?? 0;
    final stock = (json['stock'] as num?)?.toInt() ?? 99;

    String? parsedVariant;
    if (json['variant_info'] != null) {
      parsedVariant = json['variant_info'].toString();
    }

    return CartItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name']?.toString() ?? 'Produk Batik',
      productSlug: json['product_slug']?.toString(),
      primaryImage: json['primary_image']?.toString(),
      productPrice: price,
      qty: quantity,
      total: total,
      variantInfo: parsedVariant,
      weight: weight,
      totalWeight: (json['total_weight'] as num?)?.toInt() ?? (weight * quantity),
      stock: stock,
      isInStock: json['is_in_stock'] == true || stock >= quantity,
      isProductActive: json['is_product_active'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_slug': productSlug,
      'primary_image': primaryImage,
      'product_price': productPrice,
      'qty': qty,
      'total': total,
      'variant_info': variantInfo,
      'weight': weight,
      'total_weight': totalWeight,
      'stock': stock,
      'is_in_stock': isInStock,
      'is_product_active': isProductActive,
    };
  }

  CartItemModel copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productSlug,
    String? primaryImage,
    double? productPrice,
    int? qty,
    double? total,
    String? variantInfo,
    int? weight,
    int? totalWeight,
    int? stock,
    bool? isInStock,
    bool? isProductActive,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSlug: productSlug ?? this.productSlug,
      primaryImage: primaryImage ?? this.primaryImage,
      productPrice: productPrice ?? this.productPrice,
      qty: qty ?? this.qty,
      total: total ?? this.total,
      variantInfo: variantInfo ?? this.variantInfo,
      weight: weight ?? this.weight,
      totalWeight: totalWeight ?? this.totalWeight,
      stock: stock ?? this.stock,
      isInStock: isInStock ?? this.isInStock,
      isProductActive: isProductActive ?? this.isProductActive,
    );
  }

  /// Label ukuran atau varian produk (misal: "Size: XL" atau "Size: M")
  String get displayVariant {
    if (variantInfo == null || variantInfo!.trim().isEmpty) {
      return 'Size: All Size';
    }
    final trimmed = variantInfo!.trim();
    if (trimmed.toLowerCase().startsWith('size:')) {
      return trimmed;
    }
    return 'Size: $trimmed';
  }

  /// Harga satuan produk dalam format Rupiah
  String get formattedPrice => formatRupiah(productPrice);

  /// Total harga item (harga * kuantitas) dalam format Rupiah
  String get formattedTotal => formatRupiah(total);
}
