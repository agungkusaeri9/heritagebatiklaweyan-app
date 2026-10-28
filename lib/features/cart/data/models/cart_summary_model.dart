import 'cart_item_model.dart';

/// Model ringkasan harga keranjang belanja
class CartSummaryModel {
  final int totalItems;
  final int totalWeight;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double totalCost;

  const CartSummaryModel({
    required this.totalItems,
    required this.totalWeight,
    required this.subtotal,
    this.deliveryFee = 0.0,
    this.discount = 0.0,
    required this.totalCost,
  });

  factory CartSummaryModel.fromJson(Map<String, dynamic> json, {double deliveryFee = 0.0, double discount = 0.0}) {
    final subtotal = (json['total_price'] as num?)?.toDouble() ?? 0.0;
    final total = (subtotal + deliveryFee - discount).clamp(0.0, double.infinity);

    return CartSummaryModel(
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      totalWeight: (json['total_weight'] as num?)?.toInt() ?? 0,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      totalCost: total,
    );
  }

  const CartSummaryModel.empty()
      : totalItems = 0,
        totalWeight = 0,
        subtotal = 0.0,
        deliveryFee = 0.0,
        discount = 0.0,
        totalCost = 0.0;

  CartSummaryModel copyWith({
    int? totalItems,
    int? totalWeight,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? totalCost,
  }) {
    final newSubtotal = subtotal ?? this.subtotal;
    final newDeliveryFee = deliveryFee ?? this.deliveryFee;
    final newDiscount = discount ?? this.discount;
    final newTotalCost = totalCost ?? ((newSubtotal + newDeliveryFee - newDiscount).clamp(0.0, double.infinity));

    return CartSummaryModel(
      totalItems: totalItems ?? this.totalItems,
      totalWeight: totalWeight ?? this.totalWeight,
      subtotal: newSubtotal,
      deliveryFee: newDeliveryFee,
      discount: newDiscount,
      totalCost: newTotalCost,
    );
  }

  String get formattedSubtotal => formatRupiah(subtotal);
  String get formattedDeliveryFee => deliveryFee == 0 ? 'Free' : formatRupiah(deliveryFee);
  String get formattedDiscount => discount == 0 ? 'Rp 0' : '-${formatRupiah(discount)}';
  String get formattedTotalCost => formatRupiah(totalCost);
}
