/// Model ulasan untuk masing-masing produk di dalam satu transaksi/pesanan
class OrderItemReviewModel {
  final int? id;
  final int orderId;
  final int productId;
  final int rating;
  final String? comment;
  final List<String> photoPaths;
  final DateTime? createdAt;

  const OrderItemReviewModel({
    this.id,
    this.orderId = 0,
    required this.productId,
    required this.rating,
    this.comment,
    this.photoPaths = const [],
    this.createdAt,
  });

  OrderItemReviewModel copyWith({
    int? id,
    int? orderId,
    int? productId,
    int? rating,
    String? comment,
    List<String>? photoPaths,
    DateTime? createdAt,
  }) {
    return OrderItemReviewModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photoPaths: photoPaths ?? this.photoPaths,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory OrderItemReviewModel.fromJson(
    Map<String, dynamic> json, {
    int fallbackProductId = 0,
    int fallbackOrderId = 0,
  }) {
    final List<String> parsedPhotos = [];
    if (json['photo_paths'] is List) {
      for (final p in json['photo_paths'] as List) {
        if (p != null && p.toString().trim().isNotEmpty) {
          parsedPhotos.add(p.toString().trim());
        }
      }
    } else if (json['photos'] is List) {
      for (final p in json['photos'] as List) {
        if (p != null && p.toString().trim().isNotEmpty) {
          parsedPhotos.add(p.toString().trim());
        }
      }
    }

    return OrderItemReviewModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      orderId: json['order_id'] is int
          ? json['order_id'] as int
          : (int.tryParse(json['order_id']?.toString() ?? '') ?? fallbackOrderId),
      productId: json['product_id'] is int
          ? json['product_id'] as int
          : (int.tryParse(json['product_id']?.toString() ?? '') ?? fallbackProductId),
      rating: json['rating'] is int
          ? json['rating'] as int
          : (int.tryParse(json['rating']?.toString() ?? '0') ?? 0),
      comment: json['comment']?.toString(),
      photoPaths: parsedPhotos,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'order_id': orderId,
      'product_id': productId,
      'rating': rating,
      if (comment != null && comment!.trim().isNotEmpty) 'comment': comment!.trim(),
      if (photoPaths.isNotEmpty) 'photo_paths': photoPaths,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

