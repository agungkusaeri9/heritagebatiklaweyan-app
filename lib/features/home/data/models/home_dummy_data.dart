import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../store/data/models/store_setting_model.dart';

/// Model untuk opsi varian produk (misal: Ukuran / Size)
class ProductVariantOption {
  final int id;
  final String type;
  final String value;

  const ProductVariantOption({
    required this.id,
    required this.type,
    required this.value,
  });

  factory ProductVariantOption.fromJson(Map<String, dynamic> json) {
    return ProductVariantOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'Size',
      value: json['value']?.toString() ?? '',
    );
  }
}

/// Model untuk satu item ulasan produk (Product Review)
class ProductReviewItem {
  final int id;
  final String customerName;
  final String? customerUsername;
  final String? customerAvatarUrl;
  final int rating;
  final String? comment;
  final String? createdAt;

  const ProductReviewItem({
    required this.id,
    required this.customerName,
    this.customerUsername,
    this.customerAvatarUrl,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory ProductReviewItem.fromJson(Map<String, dynamic> json) {
    return ProductReviewItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerName: json['customer_name']?.toString().trim().isNotEmpty == true
          ? json['customer_name'].toString().trim()
          : 'Pelanggan Batik',
      customerUsername: json['customer_username']?.toString(),
      customerAvatarUrl: ProductItem._normalizeImageUrl(
        json['customer_avatar_url']?.toString(),
      ),
      rating: ((json['rating'] as num?)?.toInt() ?? 5).clamp(1, 5),
      comment: json['comment']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

/// Model untuk statistik ringkasan rating & rincian bintang (5 s/d 1)
class ProductRatingStats {
  final double averageRating;
  final int totalCount;
  final Map<int, int> starCounts;
  final Map<int, int> starPercentages;

  const ProductRatingStats({
    this.averageRating = 0.0,
    this.totalCount = 0,
    this.starCounts = const {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
    this.starPercentages = const {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
  });

  int countForStar(int star) => starCounts[star] ?? 0;

  int percentageForStar(int star) => starPercentages[star] ?? 0;

  factory ProductRatingStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProductRatingStats();

    final double avg = (json['average_rating'] as num?)?.toDouble() ?? 0.0;
    final int total =
        (json['total_count'] as num?)?.toInt() ??
        (json['total_reviews'] as num?)?.toInt() ??
        0;

    final Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    final Map<int, int> percentages = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    final breakdown = json['breakdown'];
    if (breakdown is Map) {
      for (int star = 5; star >= 1; star--) {
        final dynamic entry = breakdown[star] ?? breakdown[star.toString()];
        if (entry is Map) {
          counts[star] = (entry['count'] as num?)?.toInt() ?? 0;
          percentages[star] = (entry['percentage'] as num?)?.toInt() ?? 0;
        } else if (entry is num) {
          counts[star] = entry.toInt();
          percentages[star] = total > 0
              ? ((entry.toInt() / total) * 100).round()
              : 0;
        }
      }
    }

    return ProductRatingStats(
      averageRating: avg,
      totalCount: total,
      starCounts: counts,
      starPercentages: percentages,
    );
  }
}

/// Model untuk banner promosi carousel
class PromoBannerItem {
  final String id;
  final String title;
  final String subtitle;
  final String discountTag;
  final String buttonText;
  final List<Color> gradientColors;
  final String? imageUrl;
  final IconData icon;
  final String targetType;
  final String? targetUrl;
  final int? productId;
  final int? categoryId;

  const PromoBannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.discountTag,
    required this.buttonText,
    required this.gradientColors,
    this.imageUrl,
    this.icon = Icons.local_offer_rounded,
    this.targetType = 'none',
    this.targetUrl,
    this.productId,
    this.categoryId,
  });

  factory PromoBannerItem.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '0';
    final int idNum = int.tryParse(id) ?? 0;
    final title = json['title']?.toString() ?? 'Promo Spesial';
    final description = json['description']?.toString() ?? '';

    const gradients = [
      [Color(0xFF704F38), Color(0xFF4A3423)],
      [Color(0xFF8D674B), Color(0xFF5D3F28)],
      [Color(0xFFB45309), Color(0xFF78350F)],
      [Color(0xFF8B5E3C), Color(0xFF6B4423)],
    ];
    final gradient = gradients[idNum % gradients.length];

    String? rawImg = json['image_url']?.toString() ?? json['image']?.toString();
    String? imgUrl;
    if (rawImg != null && rawImg.trim().isNotEmpty) {
      final trimmed = rawImg.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        final uri = Uri.tryParse(trimmed);
        if (uri != null &&
            (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
          final serverUri = Uri.tryParse(ApiConstants.serverUrl);
          if (serverUri != null) {
            imgUrl = uri
                .replace(host: serverUri.host, port: serverUri.port)
                .toString();
          } else {
            imgUrl = trimmed;
          }
        } else {
          imgUrl = trimmed;
        }
      } else {
        final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
        imgUrl = '${ApiConstants.serverUrl}$cleanPath';
      }
    }

    final targetType = json['target_type']?.toString() ?? 'none';
    IconData icon = Icons.local_offer_rounded;
    String buttonText = 'Lihat Detail';

    if (targetType == 'url') {
      icon = Icons.language_rounded;
      buttonText = 'Buka Link';
    } else if (targetType == 'category') {
      icon = Icons.grid_view_rounded;
      buttonText = 'Lihat Koleksi';
    } else if (targetType == 'product') {
      icon = Icons.checkroom_rounded;
      buttonText = 'Belanja Sekarang';
    } else {
      icon = Icons.auto_awesome_rounded;
      buttonText = 'Pelajari Lebih';
    }

    String discountTag = 'PROMO SPESIAL';
    final titleUpper = title.toUpperCase();
    final descUpper = description.toUpperCase();
    if (titleUpper.contains('DISKON') || descUpper.contains('DISKON')) {
      discountTag = 'SPECIAL OFFER';
    } else if (titleUpper.contains('TRY-ON') ||
        descUpper.contains('TRY-ON') ||
        titleUpper.contains('AI')) {
      discountTag = 'FITUR AI';
    } else if (titleUpper.contains('EKSKLUSIF') ||
        descUpper.contains('EKSKLUSIF')) {
      discountTag = 'EXCLUSIVE';
    } else if (titleUpper.contains('SERAGAM')) {
      discountTag = 'CUSTOM ORDER';
    }

    return PromoBannerItem(
      id: id,
      title: title,
      subtitle: description.isNotEmpty
          ? description
          : 'Koleksi Autentik Batik Warisan Laweyan',
      discountTag: discountTag,
      buttonText: buttonText,
      gradientColors: gradient,
      imageUrl: imgUrl,
      icon: icon,
      targetType: targetType,
      targetUrl: json['target_url']?.toString(),
      productId: (json['product_id'] as num?)?.toInt(),
      categoryId: (json['category_id'] as num?)?.toInt(),
    );
  }
}

/// Model untuk kategori produk batik
class ProductCategoryItem {
  final String id;
  final String name;
  final String slug;
  final String description;
  final IconData icon;
  final String? imageUrl;
  final int totalItems;

  const ProductCategoryItem({
    required this.id,
    required this.name,
    this.slug = '',
    this.description = '',
    this.icon = Icons.grid_view_rounded,
    this.imageUrl,
    this.totalItems = 0,
  });

  factory ProductCategoryItem.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? 'Kategori';
    final slug = json['slug']?.toString() ?? '';
    final description = json['description']?.toString() ?? '';
    final lower = name.toLowerCase();

    IconData icon = Icons.checkroom_rounded;
    if (lower.contains('sarung')) {
      icon = Icons.checkroom_rounded;
    } else if (lower.contains('kain') || lower.contains('jarik')) {
      icon = Icons.texture_rounded;
    } else if (lower.contains('dress') ||
        lower.contains('tunik') ||
        lower.contains('wanita')) {
      icon = Icons.woman_rounded;
    } else if (lower.contains('kemeja') || lower.contains('pria')) {
      icon = Icons.dry_cleaning_rounded;
    } else if (lower.contains('couple') || lower.contains('sarimbit')) {
      icon = Icons.people_alt_rounded;
    } else if (lower.contains('anak')) {
      icon = Icons.child_care_rounded;
    } else if (lower.contains('tulis')) {
      icon = Icons.brush_rounded;
    } else if (lower.contains('cap')) {
      icon = Icons.approval_rounded;
    }

    String? rawImg = json['image_url']?.toString() ?? json['image']?.toString();
    String? imgUrl;
    if (rawImg != null && rawImg.trim().isNotEmpty) {
      final trimmed = rawImg.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        final uri = Uri.tryParse(trimmed);
        if (uri != null &&
            (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
          final serverUri = Uri.tryParse(ApiConstants.serverUrl);
          if (serverUri != null) {
            imgUrl = uri
                .replace(host: serverUri.host, port: serverUri.port)
                .toString();
          } else {
            imgUrl = trimmed;
          }
        } else {
          imgUrl = trimmed;
        }
      } else {
        final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
        imgUrl = '${ApiConstants.serverUrl}$cleanPath';
      }
    }

    return ProductCategoryItem(
      id: json['id']?.toString() ?? '0',
      name: name,
      slug: slug,
      description: description,
      icon: icon,
      imageUrl: imgUrl,
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
    );
  }

  ProductCategoryItem copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    IconData? icon,
    String? imageUrl,
    int? totalItems,
  }) {
    return ProductCategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

/// Model untuk kartu & detail produk
class ProductItem {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String sku;
  final String category;
  final double discountedPrice;
  final double originalPrice;
  final int discountPercentage;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final String? imageUrl;
  final List<String> galleryImages;
  final List<ProductVariantOption> variants;
  final Color placeholderColor;
  final bool isFavorite;
  final int stock;
  final int weight;
  final bool isVirtualTryOn;
  final int storeId;
  final StoreSettingModel? store;

  const ProductItem({
    required this.id,
    required this.name,
    this.slug = '',
    this.description = '',
    this.sku = '',
    required this.category,
    required this.discountedPrice,
    required this.originalPrice,
    required this.discountPercentage,
    required this.rating,
    this.reviewCount = 0,
    required this.soldCount,
    this.imageUrl,
    this.galleryImages = const [],
    this.variants = const [],
    required this.placeholderColor,
    this.isFavorite = false,
    this.stock = 0,
    this.weight = 0,
    this.isVirtualTryOn = false,
    this.storeId = 1,
    this.store,
  });

  bool get hasDiscount =>
      originalPrice > discountedPrice && discountPercentage > 0;

  bool get isInStock => stock > 0;

  List<String> get allImages {
    final result = <String>[];
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      result.add(imageUrl!.trim());
    }
    for (final img in galleryImages) {
      final trimmed = img.trim();
      if (trimmed.isNotEmpty) {
        result.add(trimmed);
      }
    }
    return result;
  }

  static String formatRupiah(double amount) {
    final int intAmount = amount.round();
    final String str = intAmount.toString();
    final StringBuffer buffer = StringBuffer();
    int count = 0;

    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  String get formattedDiscountedPrice => formatRupiah(discountedPrice);

  String get formattedOriginalPrice => formatRupiah(originalPrice);

  static String? _normalizeImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();
    final serverUri = Uri.tryParse(ApiConstants.serverUrl);
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && serverUri != null) {
        if (uri.path.contains('/storage/') ||
            uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host == '10.0.2.2') {
          return uri
              .replace(
                scheme: serverUri.scheme,
                host: serverUri.host,
                port: serverUri.port,
              )
              .toString();
        }
      }
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '${ApiConstants.serverUrl}$cleanPath';
  }

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] as num?)?.toDouble() ?? 0.0;
    final originalPriceVal =
        (json['original_price'] as num?)?.toDouble() ?? price;
    final discountPctVal =
        (json['discount_percentage'] as num?)?.toInt() ??
        (originalPriceVal > price && originalPriceVal > 0
            ? (((originalPriceVal - price) / originalPriceVal) * 100).round()
            : 0);

    final catName = json['category'] is Map
        ? json['category']['name']?.toString() ?? 'Batik'
        : (json['category']?.toString() ?? 'Batik');

    final int idNum = int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    const colors = [
      Color(0xFF8B5E3C),
      Color(0xFF6B4423),
      Color(0xFF9C6644),
      Color(0xFF7F4F24),
      Color(0xFF582F0E),
      Color(0xFF8D674B),
    ];
    final color = colors[idNum % colors.length];

    double ratingVal = 0.0;
    int revCount = 0;
    if (json['rating'] != null) {
      ratingVal = (json['rating'] as num).toDouble();
    } else if (json['rating_stats'] is Map) {
      final stats = json['rating_stats'] as Map;
      if (stats['average_rating'] != null) {
        final avg = (stats['average_rating'] as num).toDouble();
        if (avg > 0) ratingVal = avg;
      }
      revCount =
          (stats['total_count'] as num?)?.toInt() ??
          (stats['total_reviews'] as num?)?.toInt() ??
          0;
    }

    final int effectiveSold = (json['sold_count'] as num?)?.toInt() ?? 0;

    final String? primaryImg = _normalizeImageUrl(
      json['primary_image_url']?.toString(),
    );

    final List<String> gallery = [];
    if (json['gallery_images'] is List) {
      for (final item in (json['gallery_images'] as List)) {
        if (item is Map && item['image_url'] != null) {
          final normalized = _normalizeImageUrl(item['image_url'].toString());
          if (normalized != null) gallery.add(normalized);
        } else if (item is String) {
          final normalized = _normalizeImageUrl(item);
          if (normalized != null) gallery.add(normalized);
        }
      }
    }

    final List<ProductVariantOption> parsedVariants = [];
    if (json['variants'] is List) {
      for (final v in (json['variants'] as List)) {
        if (v is Map<String, dynamic>) {
          parsedVariants.add(ProductVariantOption.fromJson(v));
        }
      }
    }

    StoreSettingModel? parsedStore;
    if (json['store'] is Map<String, dynamic>) {
      parsedStore = StoreSettingModel.fromJson(
        json['store'] as Map<String, dynamic>,
      );
    }

    return ProductItem(
      id: json['id']?.toString() ?? '0',
      name: json['name']?.toString() ?? 'Produk Batik',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      category: catName,
      discountedPrice: price,
      originalPrice: originalPriceVal,
      discountPercentage: discountPctVal,
      rating: ratingVal > 5.0 ? 5.0 : ratingVal,
      reviewCount: revCount,
      soldCount: effectiveSold,
      imageUrl: primaryImg,
      galleryImages: gallery,
      variants: parsedVariants,
      placeholderColor: color,
      isFavorite: json['is_favorite'] == true,
      stock: (json['stock'] as num?)?.toInt() ?? 10,
      weight: (json['weight'] as num?)?.toInt() ?? 350,
      isVirtualTryOn: json['is_virtual_try_on'] == true,
      storeId: parsedStore?.id ?? (json['store_id'] as num?)?.toInt() ?? 1,
      store: parsedStore,
    );
  }

  ProductItem copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? sku,
    String? category,
    double? discountedPrice,
    double? originalPrice,
    int? discountPercentage,
    double? rating,
    int? reviewCount,
    int? soldCount,
    String? imageUrl,
    List<String>? galleryImages,
    List<ProductVariantOption>? variants,
    Color? placeholderColor,
    bool? isFavorite,
    int? stock,
    int? weight,
    bool? isVirtualTryOn,
    int? storeId,
    StoreSettingModel? store,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      soldCount: soldCount ?? this.soldCount,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      variants: variants ?? this.variants,
      placeholderColor: placeholderColor ?? this.placeholderColor,
      isFavorite: isFavorite ?? this.isFavorite,
      stock: stock ?? this.stock,
      weight: weight ?? this.weight,
      isVirtualTryOn: isVirtualTryOn ?? this.isVirtualTryOn,
      storeId: storeId ?? this.storeId,
      store: store ?? this.store,
    );
  }
}

String? _normalizeTryOnMediaUrl(dynamic raw) {
  final str = raw?.toString().trim();
  if (str == null || str.isEmpty) return null;
  final serverUri = Uri.tryParse(ApiConstants.serverUrl);
  if (str.startsWith('http://') || str.startsWith('https://')) {
    final uri = Uri.tryParse(str);
    if (uri != null && serverUri != null) {
      if (uri.path.contains('/storage/') ||
          uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '10.0.2.2') {
        return uri
            .replace(
              scheme: serverUri.scheme,
              host: serverUri.host,
              port: serverUri.port,
            )
            .toString();
      }
    }
    return str;
  }
  final cleanPath = str.startsWith('/') ? str.substring(1) : str;
  return '${ApiConstants.serverUrl}/$cleanPath';
}

/// Model Avatar / Mannequin Virtual Try-On dari Database
class VirtualTryOnModelItem {
  final int id;
  final String name;
  final String gender;
  final String? photoUrl;

  const VirtualTryOnModelItem({
    required this.id,
    required this.name,
    required this.gender,
    this.photoUrl,
  });

  String get genderLabel {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Pria';
      case 'female':
        return 'Wanita';
      default:
        return 'Unisex';
    }
  }

  factory VirtualTryOnModelItem.fromJson(Map<String, dynamic> json) {
    return VirtualTryOnModelItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name']?.toString().trim().isNotEmpty == true)
          ? json['name'].toString().trim()
          : 'Model Batik',
      gender: json['gender']?.toString() ?? 'unisex',
      photoUrl: _normalizeTryOnMediaUrl(json['photo_url'] ?? json['photo']),
    );
  }
}

/// Status & Progress Task Virtual Try-On
class VirtualTryOnTaskItem {
  final int id;
  final int? productId;
  final String? productName;
  final double? productPrice;
  final String? productSku;
  final String? productImageUrl;
  final int? virtualTryOnModelId;
  final String? modelName;
  final String? modelPhotoUrl;
  final String? gender;
  final String status; // queued, processing, completed, failed
  final int progress;
  final String? stepLabel;
  final String? photoUrl;
  final String? videoUrl;
  final bool generateVideo;
  final String? errorMessage;
  final DateTime? createdAt;

  const VirtualTryOnTaskItem({
    required this.id,
    this.productId,
    this.productName,
    this.productPrice,
    this.productSku,
    this.productImageUrl,
    this.virtualTryOnModelId,
    this.modelName,
    this.modelPhotoUrl,
    this.gender,
    required this.status,
    required this.progress,
    this.stepLabel,
    this.photoUrl,
    this.videoUrl,
    this.generateVideo = false,
    this.errorMessage,
    this.createdAt,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isActive => !isCompleted && !isFailed;

  factory VirtualTryOnTaskItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? productMap;
    if (json['product'] is Map<String, dynamic>) {
      productMap = json['product'] as Map<String, dynamic>;
    }

    Map<String, dynamic>? modelMap;
    if (json['virtual_model'] is Map<String, dynamic>) {
      modelMap = json['virtual_model'] as Map<String, dynamic>;
    }

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'].toString());
    }

    return VirtualTryOnTaskItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['product_id'] as num?)?.toInt() ??
          (productMap?['id'] as num?)?.toInt(),
      productName: productMap?['name']?.toString() ??
          json['product_name']?.toString(),
      productPrice: (productMap?['price'] as num?)?.toDouble() ??
          (json['product_price'] as num?)?.toDouble(),
      productSku: productMap?['sku']?.toString() ??
          json['product_sku']?.toString(),
      productImageUrl: _normalizeTryOnMediaUrl(
        productMap?['primary_image_url'] ?? productMap?['primary_image'],
      ),
      virtualTryOnModelId: (json['virtual_try_on_model_id'] as num?)?.toInt() ??
          (modelMap?['id'] as num?)?.toInt(),
      modelName:
          modelMap?['name']?.toString() ?? json['model_name']?.toString(),
      modelPhotoUrl: _normalizeTryOnMediaUrl(
        modelMap?['photo_url'] ?? modelMap?['photo'],
      ),
      gender: json['gender']?.toString() ?? modelMap?['gender']?.toString(),
      status: json['status']?.toString() ?? 'queued',
      progress: ((json['progress'] as num?)?.toInt() ?? 0).clamp(0, 100),
      stepLabel: json['step_label']?.toString(),
      photoUrl: _normalizeTryOnMediaUrl(json['photo_url']),
      videoUrl: _normalizeTryOnMediaUrl(json['video_url']),
      generateVideo: json['generate_video'] == true ||
          json['generate_video'] == 1 ||
          json['generate_video'] == '1',
      errorMessage: json['error_message']?.toString(),
      createdAt: parsedCreatedAt,
    );
  }
}

/// Koleksi data dummy lokal untuk Halaman Home
class HomeDummyData {
  HomeDummyData._();

  /// Daftar Banner Promo Carousel
  static const List<PromoBannerItem> banners = [
    PromoBannerItem(
      id: 'banner_1',
      title: 'Diskon Spesial Laweyan',
      subtitle: 'Koleksi Autentik Batik Tulis Asli Surakarta',
      discountTag: 'UP TO 50% OFF',
      buttonText: 'Belanja Sekarang',
      gradientColors: [Color(0xFF704F38), Color(0xFF4A3423)],
      icon: Icons.auto_awesome_rounded,
    ),
    PromoBannerItem(
      id: 'banner_2',
      title: 'Pesta Sarung Cap Klasik',
      subtitle: 'Bahan Katun Primisima Nyaman Dipakai Harian',
      discountTag: 'DISKON 35%',
      buttonText: 'Lihat Koleksi',
      gradientColors: [Color(0xFF8D674B), Color(0xFF5D3F28)],
      icon: Icons.style_rounded,
    ),
    PromoBannerItem(
      id: 'banner_3',
      title: 'Tunik & Busana Muslimah',
      subtitle: 'Tampil Anggun Elegan di Setiap Momen Istimewa',
      discountTag: 'CASHBACK 25K',
      buttonText: 'Klaim Promo',
      gradientColors: [Color(0xFFB45309), Color(0xFF78350F)],
      icon: Icons.dry_cleaning_rounded,
    ),
  ];

  /// Daftar Kategori Produk Sesuai Scope
  static const List<ProductCategoryItem> categories = [
    ProductCategoryItem(
      id: 'all',
      name: 'All',
      slug: '',
      description: 'Semua koleksi mahakarya batik autentik Laweyan Surakarta',
      icon: Icons.grid_view_rounded,
      totalItems: 84,
    ),
    ProductCategoryItem(
      id: 'sarung',
      name: 'Sarung',
      slug: 'sarung',
      description: 'Sarung batik cap dan tulis primisima nyaman dipakai harian',
      icon: Icons.checkroom_rounded,
      totalItems: 28,
    ),
    ProductCategoryItem(
      id: 'kain',
      name: 'Kain',
      slug: 'kain',
      description: 'Kain panjang dan jarik tradisional pewarna alami',
      icon: Icons.texture_rounded,
      totalItems: 35,
    ),
    ProductCategoryItem(
      id: 'tunik',
      name: 'Tunik',
      slug: 'tunik',
      description: 'Busana tunik dan dress anggun motif modern Laweyan',
      icon: Icons.woman_rounded,
      totalItems: 22,
    ),
    ProductCategoryItem(
      id: 'anak',
      name: 'Anak-Anak',
      slug: 'anak',
      description: 'Kemeja dan busana batik anak motif ceria Solo',
      icon: Icons.child_care_rounded,
      totalItems: 16,
    ),
  ];

  static const StoreSettingModel defaultStore = StoreSettingModel(
    id: 1,
    name: 'Heritage Batik Laweyan',
    description:
        'Pusat Kerajinan Batik Tulis & Cap Autentik Kampung Batik Laweyan, Surakarta sejak 1988.',
    address: 'Jl. Dr. Rajiman No. 515, Kampung Batik Laweyan, Kota Surakarta',
    phone: '+62 271 712345',
    whatsapp: '6281234567890',
    email: 'cs@heritagebatiklaweyan.id',
    website: 'https://heritagebatiklaweyan.id',
  );

  /// Daftar Produk Rekomendasi
  static const List<ProductItem> recommendations = [
    ProductItem(
      id: '1',
      name: 'Kain Batik Tulis Sogan Motif Parang Kusumo',
      slug: 'kain-batik-tulis-sogan-motif-parang-kusumo',
      description:
          'Kain batik tulis sogan klasik bermotif Parang Kusumo hasil karya pengrajin Kampung Batik Laweyan, Surakarta. Menggunakan bahan katun primisima halus berkualitas tinggi yang sejuk di kulit, nyaman dipakai untuk acara resmi maupun busana formal sehari-hari. Pewarnaan sogan alami memberikan nuansa hangat dan tahan lama.',
      category: 'Kain',
      discountedPrice: 345000,
      originalPrice: 450000,
      discountPercentage: 23,
      rating: 4.9,
      reviewCount: 38,
      soldCount: 142,
      placeholderColor: Color(0xFF8B5E3C),
      isFavorite: true,
      stock: 15,
      weight: 350,
      storeId: 1,
      store: defaultStore,
    ),
    ProductItem(
      id: '2',
      name: 'Sarung Batik Cap Katun Primisima Laweyan',
      slug: 'sarung-batik-cap-katun-primisima-laweyan',
      description:
          'Sarung batik cap asli Laweyan menggunakan kain katun primisima pilihan yang lembut, adem, dan tidak mudah kusut. Dikerjakan secara detail menggunakan canting tembaga tradisional oleh pengrajin berpengalaman.',
      category: 'Sarung',
      discountedPrice: 165000,
      originalPrice: 220000,
      discountPercentage: 25,
      rating: 4.8,
      reviewCount: 24,
      soldCount: 98,
      placeholderColor: Color(0xFF6B4423),
      isFavorite: false,
      stock: 20,
      weight: 400,
      storeId: 1,
      store: defaultStore,
    ),
    ProductItem(
      id: '3',
      name: 'Tunik Batik Sutra Motif Truntum Emas Mewah',
      slug: 'tunik-batik-sutra-motif-truntum-emas-mewah',
      description:
          'Busana tunik wanita berbahan sutra premium dengan motif filosofis Truntum berpadu aksen sogan keemasan. Potongan modern nan anggun, cocok untuk pesta pernikahan, wisuda, maupun acara formal.',
      category: 'Tunik',
      discountedPrice: 275000,
      originalPrice: 380000,
      discountPercentage: 28,
      rating: 5.0,
      reviewCount: 19,
      soldCount: 76,
      placeholderColor: Color(0xFF9C6644),
      isFavorite: false,
      stock: 12,
      weight: 320,
      storeId: 1,
      store: defaultStore,
    ),
    ProductItem(
      id: '4',
      name: 'Kemeja Batik Anak Motif Kawung Modern Solo',
      slug: 'kemeja-batik-anak-motif-kawung-modern-solo',
      description:
          'Kemeja batik anak lengan pendek bermotif Kawung modern khas Solo. Terbuat dari 100% katun adem yang menyerap keringat sehingga nyaman dipakai anak sepanjang hari.',
      category: 'Anak-Anak',
      discountedPrice: 115000,
      originalPrice: 150000,
      discountPercentage: 23,
      rating: 4.7,
      reviewCount: 15,
      soldCount: 64,
      placeholderColor: Color(0xFF7F4F24),
      isFavorite: true,
      stock: 18,
      weight: 220,
      storeId: 1,
      store: defaultStore,
    ),
    ProductItem(
      id: '5',
      name: 'Kain Batik Tulis Celup Pewarna Alami Laweyan',
      slug: 'kain-batik-tulis-celup-pewarna-alami-laweyan',
      description:
          'Mahakarya kain batik tulis eksklusif yang diwarnai menggunakan ekstrak tumbuh-tumbuhan alami (kayu tingi, tegeran, dan nila). Menghasilkan gradasi warna etnik yang unik pada setiap helai kain.',
      category: 'Kain',
      discountedPrice: 420000,
      originalPrice: 600000,
      discountPercentage: 30,
      rating: 4.9,
      reviewCount: 29,
      soldCount: 53,
      placeholderColor: Color(0xFF582F0E),
      isFavorite: false,
      stock: 8,
      weight: 380,
      storeId: 1,
      store: defaultStore,
    ),
  ];
}
