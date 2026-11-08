import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'order_review_model.dart';

/// Helper untuk menormalisasi URL gambar dari backend (mendukung path relatif & localhost)
String? normalizeBackendImageUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.trim().isEmpty) return null;
  final trimmed = rawUrl.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      final serverUri = Uri.tryParse(ApiConstants.serverUrl);
      if (serverUri != null) {
        return uri
            .replace(host: serverUri.host, port: serverUri.port)
            .toString();
      }
    }
    return trimmed;
  }
  final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '${ApiConstants.serverUrl}$cleanPath';
}

/// Item pesanan di dalam hasil checkout / detail pesanan
class CheckoutOrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productSlug;
  final String? primaryImage;
  final String? variantInfo;
  final double price;
  final int quantity;
  final double totalPrice;
  final bool isReviewed;
  final OrderItemReviewModel? review;

  const CheckoutOrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSlug,
    this.primaryImage,
    this.variantInfo,
    required this.price,
    required this.quantity,
    required this.totalPrice,
    this.isReviewed = false,
    this.review,
  });

  CheckoutOrderItemModel copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productSlug,
    String? primaryImage,
    String? variantInfo,
    double? price,
    int? quantity,
    double? totalPrice,
    bool? isReviewed,
    OrderItemReviewModel? review,
  }) {
    return CheckoutOrderItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSlug: productSlug ?? this.productSlug,
      primaryImage: primaryImage ?? this.primaryImage,
      variantInfo: variantInfo ?? this.variantInfo,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      isReviewed: isReviewed ?? this.isReviewed,
      review: review ?? this.review,
    );
  }

  factory CheckoutOrderItemModel.fromJson(Map<String, dynamic> json) {
    final nestedProduct = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : null;

    final rawName =
        json['product_name']?.toString() ??
        nestedProduct?['name']?.toString() ??
        '';
    final rawSlug =
        json['product_slug']?.toString() ?? nestedProduct?['slug']?.toString();
    final rawImg =
        json['primary_image']?.toString() ??
        nestedProduct?['primary_image_url']?.toString() ??
        nestedProduct?['primary_image']?.toString();

    final parsedPrice =
        (json['price'] as num?)?.toDouble() ??
        double.tryParse(json['price']?.toString() ?? '0') ??
        0.0;
    final parsedQty = json['quantity'] is int
        ? json['quantity'] as int
        : (int.tryParse(json['quantity']?.toString() ?? '1') ?? 1);
    final parsedTotal =
        (json['total_price'] as num?)?.toDouble() ??
        double.tryParse(json['total_price']?.toString() ?? '') ??
        (parsedPrice * parsedQty);

    final parsedProductId = json['product_id'] is int
        ? json['product_id'] as int
        : (int.tryParse(json['product_id']?.toString() ?? '0') ?? 0);

    OrderItemReviewModel? parsedReview;
    if (json['review'] is Map<String, dynamic>) {
      parsedReview = OrderItemReviewModel.fromJson(
        json['review'] as Map<String, dynamic>,
        fallbackProductId: parsedProductId,
      );
    }
    final bool parsedIsReviewed =
        json['is_reviewed'] == true || parsedReview != null;

    return CheckoutOrderItemModel(
      id: json['id'] is int
          ? json['id'] as int
          : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      productId: parsedProductId,
      productName: rawName,
      productSlug: rawSlug,
      primaryImage: normalizeBackendImageUrl(rawImg),
      variantInfo: json['variant_info']?.toString(),
      price: parsedPrice,
      quantity: parsedQty,
      totalPrice: parsedTotal,
      isReviewed: parsedIsReviewed,
      review: parsedReview,
    );
  }

  String get formattedPrice => formatRupiah(price);
  String get formattedTotalPrice => formatRupiah(totalPrice);

  bool get hasVariant => variantInfo != null && variantInfo!.trim().isNotEmpty;

  String get displayVariant {
    if (!hasVariant) return '';
    return variantInfo!.trim();
  }
}

/// Model hasil dari proses checkout, daftar pesanan, & detail transaksi aktual
class CheckoutResultModel {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final double subtotal;
  final double shippingFee;
  final double? discount;
  final double? additionalCharges;
  final int totalItemsCount;
  final String? paymentMethodName;
  final String? paymentAccountNumber;
  final String? paymentAccountName;
  final String? paymentLogoUrl;
  final String? paymentProof;
  final String? paymentProofUrl;
  final String? courierName;
  final String? courierCode;
  final String? shippingName;
  final String? trackingNumber;
  final String? recipientName;
  final String? recipientPhone;
  final String? recipientAddress;
  final String? provinceName;
  final String? cityName;
  final String? subdistrictName;
  final String? postalCode;
  final List<CheckoutOrderItemModel> items;
  final bool isReviewedExplicit;
  final int reviewedCount;
  final double? averageRating;
  final int? transactionRating;
  final String? transactionReviewComment;
  final List<OrderItemReviewModel> reviews;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CheckoutResultModel({
    int? id,
    int? orderId,
    required this.orderNumber,
    this.status = 'pending',
    this.paymentStatus = 'pending',
    required this.totalAmount,
    this.subtotal = 0.0,
    this.shippingFee = 0.0,
    this.discount,
    this.additionalCharges,
    this.totalItemsCount = 0,
    String? paymentMethodName,
    String? paymentMethod,
    this.paymentAccountNumber,
    this.paymentAccountName,
    this.paymentLogoUrl,
    this.paymentProof,
    this.paymentProofUrl,
    this.courierName,
    this.courierCode,
    this.shippingName,
    this.trackingNumber,
    this.recipientName,
    this.recipientPhone,
    this.recipientAddress,
    this.provinceName,
    this.cityName,
    this.subdistrictName,
    this.postalCode,
    this.items = const [],
    this.isReviewedExplicit = false,
    this.reviewedCount = 0,
    this.averageRating,
    this.transactionRating,
    this.transactionReviewComment,
    this.reviews = const [],
    this.createdAt,
    this.updatedAt,
  }) : id = id ?? orderId ?? 0,
       paymentMethodName = paymentMethodName ?? paymentMethod;

  int get orderId => id;
  String? get paymentMethod => paymentMethodName;

  bool get hasPaymentProof =>
      (paymentProof != null && paymentProof!.isNotEmpty) ||
      (paymentProofUrl != null && paymentProofUrl!.isNotEmpty);

  /// Produk pertama sebagai ringkasan utama pada Order List
  CheckoutOrderItemModel? get primaryProduct =>
      items.isNotEmpty ? items.first : null;

  /// Jumlah produk berbeda (distinct products) di dalam pesanan
  int get distinctProductCount {
    if (items.isNotEmpty) return items.length;
    return totalItemsCount > 0 ? 1 : 0;
  }

  /// Jumlah produk tambahan selain produk pertama
  int get additionalProductCount => items.length > 1 ? items.length - 1 : 0;

  /// Total kuantitas seluruh produk dalam pesanan
  int get totalQuantity {
    final summedFromItems = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    if (totalItemsCount > 0 && totalItemsCount >= summedFromItems) {
      return totalItemsCount;
    }
    if (summedFromItems > 0) {
      return summedFromItems;
    }
    return totalItemsCount;
  }

  /// Evaluasi status sesuai definisi backend (pending, processing, success, failed)
  bool get isActiveOrder {
    final s = status.toLowerCase().trim();
    return s == 'pending' ||
        s == 'processing' ||
        s == 'shipped' ||
        s == 'in_transit' ||
        s == 'active';
  }

  bool get isCompletedOrder {
    final s = status.toLowerCase().trim();
    return s == 'success' || s == 'completed' || s == 'delivered';
  }

  bool get isCancelledOrder {
    final s = status.toLowerCase().trim();
    return s == 'failed' || s == 'cancelled' || s == 'canceled';
  }

  /// Tombol Track Order ditampilkan untuk pesanan yang berstatus Active
  bool get canTrackOrder => isActiveOrder;

  /// Apakah pesanan masih membutuhkan/mengizinkan unggah bukti pembayaran
  bool get canUploadPaymentProof =>
      isActiveOrder && paymentStatus.toLowerCase().trim() != 'paid';

  /// Mencari data ulasan untuk produk tertentu dalam pesanan ini
  OrderItemReviewModel? reviewForProduct(int productId) {
    for (final item in items) {
      if (item.productId == productId && item.review != null) {
        return item.review;
      }
    }
    for (final rev in reviews) {
      if (rev.productId == productId) {
        return rev;
      }
    }
    return null;
  }

  /// Apakah seluruh produk di dalam pesanan sudah diberikan ulasan
  bool get isFullyReviewed {
    if (isReviewedExplicit) return true;
    final distinctProductIds = items
        .map((e) => e.productId)
        .where((pid) => pid > 0)
        .toSet();
    if (distinctProductIds.isEmpty) {
      return reviewedCount > 0 || reviews.isNotEmpty;
    }
    return distinctProductIds.every((pid) => reviewForProduct(pid) != null);
  }

  /// Apakah baru sebagian produk yang diulas
  bool get isPartiallyReviewed {
    if (isFullyReviewed) return false;
    return reviewedCount > 0 ||
        reviews.isNotEmpty ||
        items.any((i) => i.isReviewed || i.review != null);
  }

  /// Jumlah produk yang belum diberikan ulasan
  int get unreviewedProductCount {
    final distinctProductIds = items
        .map((e) => e.productId)
        .where((pid) => pid > 0)
        .toSet();
    if (distinctProductIds.isEmpty) {
      return isFullyReviewed ? 0 : distinctProductCount;
    }
    return distinctProductIds
        .where((pid) => reviewForProduct(pid) == null)
        .length;
  }

  /// Hanya transaksi yang sudah selesai (Completed) dan belum selesai diulas yang dapat meninggalkan ulasan
  bool get canLeaveReview => isCompletedOrder && !isFullyReviewed;

  /// Nilai rating efektif pesanan (dari transactionRating, averageRating backend, atau rata-rata ulasan produk)
  double? get effectiveRating {
    if (transactionRating != null && transactionRating! > 0) {
      return transactionRating!.toDouble();
    }
    if (averageRating != null && averageRating! > 0) {
      return averageRating;
    }
    final allRatings = <int>[];
    for (final rev in reviews) {
      if (rev.rating > 0) allRatings.add(rev.rating);
    }
    if (allRatings.isEmpty) {
      for (final item in items) {
        if (item.review != null && item.review!.rating > 0) {
          allRatings.add(item.review!.rating);
        }
      }
    }
    if (allRatings.isEmpty) return null;
    final avg = allRatings.reduce((a, b) => a + b) / allRatings.length;
    return double.parse(avg.toStringAsFixed(1));
  }

  /// Label status pesanan yang bersih
  String get statusLabel {
    final s = status.toLowerCase().trim();
    switch (s) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'success':
      case 'completed':
        return 'Completed';
      case 'failed':
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  /// Label status pembayaran
  String get paymentStatusLabel {
    final ps = paymentStatus.toLowerCase().trim();
    if (ps == 'paid' || ps == 'success') {
      return 'Paid';
    }
    if (ps == 'failed' || ps == 'cancelled') {
      return 'Failed';
    }
    if (hasPaymentProof) {
      return 'Waiting Verification';
    }
    return 'Unpaid';
  }

  /// Alamat lengkap terformat beserta kecamatan, kota, provinsi, dan kode pos
  String? get fullShippingAddress {
    final parts = <String>[];
    if (recipientAddress != null && recipientAddress!.trim().isNotEmpty) {
      parts.add(recipientAddress!.trim());
    }
    if (subdistrictName != null && subdistrictName!.trim().isNotEmpty) {
      parts.add('Kec. ${subdistrictName!.trim()}');
    }
    if (cityName != null && cityName!.trim().isNotEmpty) {
      parts.add(cityName!.trim());
    }
    if (provinceName != null && provinceName!.trim().isNotEmpty) {
      parts.add(provinceName!.trim());
    }
    if (postalCode != null &&
        postalCode!.trim().isNotEmpty &&
        !(recipientAddress?.contains(postalCode!.trim()) ?? false)) {
      parts.add(postalCode!.trim());
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String get formattedTotal => formatRupiah(totalAmount);
  String get formattedSubtotal => formatRupiah(subtotal);
  String get formattedShippingFee =>
      shippingFee == 0 ? 'Free' : formatRupiah(shippingFee);
  String get formattedDiscount => discount != null && discount! > 0
      ? '-${formatRupiah(discount!)}'
      : formatRupiah(0);
  String get formattedAdditionalCharges =>
      additionalCharges != null && additionalCharges! > 0
      ? formatRupiah(additionalCharges!)
      : formatRupiah(0);

  String get formattedDate {
    final dt = createdAt ?? DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute WIB';
  }

  /// Salin objek model dengan properti yang diubah
  CheckoutResultModel copyWith({
    int? id,
    String? orderNumber,
    String? status,
    String? paymentStatus,
    double? totalAmount,
    double? subtotal,
    double? shippingFee,
    double? discount,
    double? additionalCharges,
    int? totalItemsCount,
    String? paymentMethodName,
    String? paymentAccountNumber,
    String? paymentAccountName,
    String? paymentLogoUrl,
    String? paymentProof,
    String? paymentProofUrl,
    String? courierName,
    String? courierCode,
    String? shippingName,
    String? trackingNumber,
    String? recipientName,
    String? recipientPhone,
    String? recipientAddress,
    String? provinceName,
    String? cityName,
    String? subdistrictName,
    String? postalCode,
    List<CheckoutOrderItemModel>? items,
    bool? isReviewedExplicit,
    int? reviewedCount,
    double? averageRating,
    int? transactionRating,
    String? transactionReviewComment,
    List<OrderItemReviewModel>? reviews,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CheckoutResultModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      discount: discount ?? this.discount,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      totalItemsCount: totalItemsCount ?? this.totalItemsCount,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      paymentAccountNumber: paymentAccountNumber ?? this.paymentAccountNumber,
      paymentAccountName: paymentAccountName ?? this.paymentAccountName,
      paymentLogoUrl: paymentLogoUrl ?? this.paymentLogoUrl,
      paymentProof: paymentProof ?? this.paymentProof,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      courierName: courierName ?? this.courierName,
      courierCode: courierCode ?? this.courierCode,
      shippingName: shippingName ?? this.shippingName,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      provinceName: provinceName ?? this.provinceName,
      cityName: cityName ?? this.cityName,
      subdistrictName: subdistrictName ?? this.subdistrictName,
      postalCode: postalCode ?? this.postalCode,
      items: items ?? this.items,
      isReviewedExplicit: isReviewedExplicit ?? this.isReviewedExplicit,
      reviewedCount: reviewedCount ?? this.reviewedCount,
      averageRating: averageRating ?? this.averageRating,
      transactionRating: transactionRating ?? this.transactionRating,
      transactionReviewComment:
          transactionReviewComment ?? this.transactionReviewComment,
      reviews: reviews ?? this.reviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Menggabungkan informasi dari detail pesanan ke item list pesanan
  CheckoutResultModel mergeWithDetail(CheckoutResultModel detail) {
    return CheckoutResultModel(
      id: detail.id != 0 ? detail.id : id,
      orderNumber: detail.orderNumber.isNotEmpty
          ? detail.orderNumber
          : orderNumber,
      status: detail.status.isNotEmpty ? detail.status : status,
      paymentStatus: detail.paymentStatus != 'pending'
          ? detail.paymentStatus
          : paymentStatus,
      totalAmount: detail.totalAmount > 0 ? detail.totalAmount : totalAmount,
      subtotal: detail.subtotal > 0 ? detail.subtotal : subtotal,
      shippingFee: detail.shippingFee > 0 ? detail.shippingFee : shippingFee,
      discount: detail.discount ?? discount,
      additionalCharges: detail.additionalCharges ?? additionalCharges,
      totalItemsCount: totalItemsCount > 0
          ? totalItemsCount
          : detail.totalItemsCount,
      paymentMethodName: detail.paymentMethodName ?? paymentMethodName,
      paymentAccountNumber: detail.paymentAccountNumber ?? paymentAccountNumber,
      paymentAccountName: detail.paymentAccountName ?? paymentAccountName,
      paymentLogoUrl: detail.paymentLogoUrl ?? paymentLogoUrl,
      paymentProof: detail.paymentProof ?? paymentProof,
      paymentProofUrl: detail.paymentProofUrl ?? paymentProofUrl,
      courierName: detail.courierName ?? courierName,
      courierCode: detail.courierCode ?? courierCode,
      shippingName: detail.shippingName ?? shippingName,
      trackingNumber: detail.trackingNumber ?? trackingNumber,
      recipientName: detail.recipientName ?? recipientName,
      recipientPhone: detail.recipientPhone ?? recipientPhone,
      recipientAddress: detail.recipientAddress ?? recipientAddress,
      provinceName: detail.provinceName ?? provinceName,
      cityName: detail.cityName ?? cityName,
      subdistrictName: detail.subdistrictName ?? subdistrictName,
      postalCode: detail.postalCode ?? postalCode,
      items: detail.items.isNotEmpty ? detail.items : items,
      isReviewedExplicit: detail.isReviewedExplicit || isReviewedExplicit,
      reviewedCount: detail.reviewedCount > 0
          ? detail.reviewedCount
          : reviewedCount,
      averageRating: detail.averageRating ?? averageRating,
      transactionRating: detail.transactionRating ?? transactionRating,
      transactionReviewComment:
          detail.transactionReviewComment ?? transactionReviewComment,
      reviews: detail.reviews.isNotEmpty ? detail.reviews : reviews,
      createdAt: detail.createdAt ?? createdAt,
      updatedAt: detail.updatedAt ?? updatedAt,
    );
  }

  factory CheckoutResultModel.fromJson(Map<String, dynamic> json) {
    // Pricing
    double total = 0.0;
    double sub = 0.0;
    double ship = 0.0;
    double? disc;
    double? addCharges;

    if (json['pricing'] is Map) {
      final p = json['pricing'] as Map<String, dynamic>;
      sub =
          (p['subtotal'] as num?)?.toDouble() ??
          double.tryParse(p['subtotal']?.toString() ?? '0') ??
          0.0;
      ship =
          (p['shipping_fee'] as num?)?.toDouble() ??
          double.tryParse(p['shipping_fee']?.toString() ?? '0') ??
          0.0;
      total =
          (p['total_amount'] as num?)?.toDouble() ??
          double.tryParse(p['total_amount']?.toString() ?? '0') ??
          0.0;
      if (p['discount'] != null) {
        disc =
            (p['discount'] as num?)?.toDouble() ??
            double.tryParse(p['discount'].toString());
      }
      if (p['additional_charges'] != null || p['service_fee'] != null) {
        final rawAdd = p['additional_charges'] ?? p['service_fee'];
        addCharges =
            (rawAdd as num?)?.toDouble() ?? double.tryParse(rawAdd.toString());
      }
    } else {
      total =
          (json['total_amount'] as num?)?.toDouble() ??
          double.tryParse(json['total_amount']?.toString() ?? '0') ??
          0.0;
      sub =
          (json['subtotal'] as num?)?.toDouble() ??
          double.tryParse(json['subtotal']?.toString() ?? '') ??
          total;
      ship =
          (json['shipping_fee'] as num?)?.toDouble() ??
          double.tryParse(json['shipping_fee']?.toString() ?? '0') ??
          0.0;
      if (json['discount'] != null) {
        disc =
            (json['discount'] as num?)?.toDouble() ??
            double.tryParse(json['discount'].toString());
      }
      if (json['additional_charges'] != null || json['service_fee'] != null) {
        final rawAdd = json['additional_charges'] ?? json['service_fee'];
        addCharges =
            (rawAdd as num?)?.toDouble() ?? double.tryParse(rawAdd.toString());
      }
    }

    // Total items count from OrderListResource
    final int parsedTotalItems = json['total_items'] is int
        ? json['total_items'] as int
        : (int.tryParse(json['total_items']?.toString() ?? '0') ?? 0);

    // Payment
    String? payName;
    String? payAccNum;
    String? payAccName;
    String? payLogo;
    String? proof;
    String? proofUrl;
    String payStatus = json['payment_status']?.toString() ?? 'pending';

    if (json['payment'] is Map) {
      final pay = json['payment'] as Map<String, dynamic>;
      payName = pay['payment_method_name']?.toString();
      payAccNum = pay['payment_account_number']?.toString();
      payAccName = pay['payment_account_name']?.toString();
      payLogo = pay['payment_logo_url']?.toString();
      proof = pay['payment_proof']?.toString();
      proofUrl = pay['payment_proof_url']?.toString();
      if (pay['payment_status'] != null) {
        payStatus = pay['payment_status'].toString();
      } else if (pay['transaction'] is Map) {
        final tx = pay['transaction'] as Map<String, dynamic>;
        if (tx['status'] != null) {
          payStatus = tx['status'].toString();
        }
        proof ??= tx['payment_proof']?.toString();
        proofUrl ??= tx['payment_proof_url']?.toString();
      }
    } else if (json['payment_method'] is Map) {
      final pm = json['payment_method'] as Map<String, dynamic>;
      payName = pm['name']?.toString();
      payAccNum = pm['account_number']?.toString();
      payAccName = pm['account_name']?.toString();
      payLogo = pm['logo_url']?.toString();
    }

    if (json['transaction'] is Map) {
      final tx = json['transaction'] as Map<String, dynamic>;
      if (tx['status'] != null) {
        payStatus = tx['status'].toString();
      }
      proof ??= tx['payment_proof']?.toString();
      proofUrl ??= tx['payment_proof_url']?.toString();
    }

    proof ??= json['payment_proof']?.toString();
    proofUrl ??= json['payment_proof_url']?.toString();

    // Shipping
    String? cName;
    String? cCode;
    String? sName = json['shipping_name']?.toString();
    String? tracking = json['tracking_number']?.toString();

    if (json['shipping'] is Map) {
      final s = json['shipping'] as Map<String, dynamic>;
      cName = s['courier_name']?.toString();
      cCode = s['courier_code']?.toString();
      sName ??= s['shipping_name']?.toString();
      tracking ??= s['tracking_number']?.toString();
    } else if (json['courier'] is Map) {
      final c = json['courier'] as Map<String, dynamic>;
      cName = c['name']?.toString();
      cCode = c['code']?.toString();
    }

    // Shipping Address & Recipient Info
    String? rName;
    String? rPhone;
    String? rAddress = json['address']?.toString();
    String? provName;
    String? citName;
    String? subName;
    String? postCode;

    if (json['shipping_address'] is Map) {
      final sa = json['shipping_address'] as Map<String, dynamic>;
      rAddress = sa['address']?.toString() ?? rAddress;
      if (sa['province'] is Map) {
        provName =
            (sa['province'] as Map)['name']?.toString() ??
            (sa['province'] as Map)['province_name']?.toString();
      }
      if (sa['city'] is Map) {
        citName =
            (sa['city'] as Map)['name']?.toString() ??
            (sa['city'] as Map)['city_name']?.toString();
        postCode = (sa['city'] as Map)['postal_code']?.toString();
      }
      if (sa['subdistrict'] is Map) {
        subName =
            (sa['subdistrict'] as Map)['name']?.toString() ??
            (sa['subdistrict'] as Map)['subdistrict_name']?.toString();
      }
    }

    if (json['customer'] is Map) {
      final c = json['customer'] as Map<String, dynamic>;
      rName = c['name']?.toString();
      rPhone = c['phone']?.toString();
    }

    // Ekstrak nama & telepon penerima jika tertanam dalam format CheckoutService: "Nama (08123...) - Jl. ..."
    if (rAddress != null && rAddress.contains(' - ')) {
      final match = RegExp(
        r'^(.+?)\s*\(([^)]+)\)\s*-\s*(.+)$',
      ).firstMatch(rAddress);
      if (match != null) {
        rName ??= match.group(1)?.trim();
        rPhone ??= match.group(2)?.trim();
        rAddress = match.group(3)?.trim();
      }
    }

    // Items
    List<CheckoutOrderItemModel> itemsList = [];
    if (json['items'] is List) {
      itemsList = (json['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => CheckoutOrderItemModel.fromJson(item))
          .toList();
    } else if (json['details'] is List) {
      itemsList = (json['details'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => CheckoutOrderItemModel.fromJson(item))
          .toList();
    }

    // Reviews
    final int parsedOrderId = json['id'] is int
        ? json['id'] as int
        : (int.tryParse(json['id']?.toString() ?? '0') ?? 0);
    List<OrderItemReviewModel> reviewsList = [];
    if (json['reviews'] is List) {
      reviewsList = (json['reviews'] as List)
          .whereType<Map<String, dynamic>>()
          .map(
            (r) => OrderItemReviewModel.fromJson(
              r,
              fallbackOrderId: parsedOrderId,
            ),
          )
          .toList();
    }

    // Jika item belum memiliki objek review namun ada di daftar reviews order, tautkan
    if (reviewsList.isNotEmpty && itemsList.isNotEmpty) {
      itemsList = itemsList.map((item) {
        if (item.review != null) return item;
        final matched = reviewsList
            .where((r) => r.productId == item.productId)
            .firstOrNull;
        if (matched != null) {
          return item.copyWith(isReviewed: true, review: matched);
        }
        return item;
      }).toList();
    }

    final bool parsedIsReviewed = json['is_reviewed'] == true;
    final int parsedReviewedCount = json['reviewed_count'] is int
        ? json['reviewed_count'] as int
        : (int.tryParse(json['reviewed_count']?.toString() ?? '') ??
            reviewsList.length);
    final double? parsedAvgRating = json['average_rating'] != null
        ? ((json['average_rating'] as num?)?.toDouble() ??
            double.tryParse(json['average_rating'].toString()))
        : null;
    final int? parsedTxRating = json['transaction_rating'] is int
        ? json['transaction_rating'] as int
        : int.tryParse(json['transaction_rating']?.toString() ?? '');
    final String? parsedTxComment = json['transaction_comment']?.toString();

    // Created At & Updated At
    DateTime? dt;
    if (json['created_at'] != null) {
      dt = DateTime.tryParse(json['created_at'].toString());
    }
    DateTime? udt;
    if (json['updated_at'] != null) {
      udt = DateTime.tryParse(json['updated_at'].toString());
    }

    return CheckoutResultModel(
      id: parsedOrderId,
      orderNumber: json['order_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: payStatus,
      totalAmount: total,
      subtotal: sub,
      shippingFee: ship,
      discount: disc,
      additionalCharges: addCharges,
      totalItemsCount: parsedTotalItems,
      paymentMethodName: payName,
      paymentAccountNumber: payAccNum,
      paymentAccountName: payAccName,
      paymentLogoUrl: normalizeBackendImageUrl(payLogo),
      paymentProof: proof,
      paymentProofUrl: normalizeBackendImageUrl(proofUrl ?? proof),
      courierName: cName ?? sName,
      courierCode: cCode,
      shippingName: sName,
      trackingNumber: tracking,
      recipientName: rName,
      recipientPhone: rPhone,
      recipientAddress: rAddress,
      provinceName: provName,
      cityName: citName,
      subdistrictName: subName,
      postalCode: postCode,
      items: itemsList,
      isReviewedExplicit: parsedIsReviewed,
      reviewedCount: parsedReviewedCount,
      averageRating: parsedAvgRating,
      transactionRating: parsedTxRating,
      transactionReviewComment: parsedTxComment,
      reviews: reviewsList,
      createdAt: dt ?? DateTime.now(),
      updatedAt: udt,
    );
  }
}
