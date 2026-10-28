import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';

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
        if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
          final serverUri = Uri.tryParse(ApiConstants.serverUrl);
          if (serverUri != null) {
            imgUrl = uri.replace(host: serverUri.host, port: serverUri.port).toString();
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
    } else if (titleUpper.contains('TRY-ON') || descUpper.contains('TRY-ON') || titleUpper.contains('AI')) {
      discountTag = 'FITUR AI';
    } else if (titleUpper.contains('EKSKLUSIF') || descUpper.contains('EKSKLUSIF')) {
      discountTag = 'EXCLUSIVE';
    } else if (titleUpper.contains('SERAGAM')) {
      discountTag = 'CUSTOM ORDER';
    }

    return PromoBannerItem(
      id: id,
      title: title,
      subtitle: description.isNotEmpty ? description : 'Koleksi Autentik Batik Warisan Laweyan',
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
    } else if (lower.contains('dress') || lower.contains('tunik') || lower.contains('wanita')) {
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
        if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
          final serverUri = Uri.tryParse(ApiConstants.serverUrl);
          if (serverUri != null) {
            imgUrl = uri.replace(host: serverUri.host, port: serverUri.port).toString();
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

/// Model untuk kartu produk
class ProductItem {
  final String id;
  final String name;
  final String slug;
  final String category;
  final double discountedPrice;
  final double originalPrice;
  final int discountPercentage;
  final double rating;
  final int soldCount;
  final String? imageUrl;
  final Color placeholderColor;
  final bool isFavorite;
  final int stock;
  final int weight;

  const ProductItem({
    required this.id,
    required this.name,
    this.slug = '',
    required this.category,
    required this.discountedPrice,
    required this.originalPrice,
    required this.discountPercentage,
    required this.rating,
    required this.soldCount,
    this.imageUrl,
    required this.placeholderColor,
    this.isFavorite = false,
    this.stock = 0,
    this.weight = 0,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] as num?)?.toDouble() ?? 0.0;
    final catName = json['category'] is Map
        ? json['category']['name']?.toString() ?? 'Batik'
        : 'Batik';

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

    double ratingVal = 4.8;
    if (json['rating'] != null) {
      ratingVal = (json['rating'] as num).toDouble();
    } else if (json['rating_stats'] is Map && json['rating_stats']['average_rating'] != null) {
      ratingVal = (json['rating_stats']['average_rating'] as num).toDouble();
    } else {
      const ratings = [4.9, 4.4, 3.8, 4.7, 4.2, 3.4, 4.8];
      ratingVal = ratings[idNum % ratings.length];
    }

    return ProductItem(
      id: json['id']?.toString() ?? '0',
      name: json['name']?.toString() ?? 'Produk Batik',
      slug: json['slug']?.toString() ?? '',
      category: catName,
      discountedPrice: price,
      originalPrice: price,
      discountPercentage: 0,
      rating: ratingVal > 5.0 ? 5.0 : ratingVal,
      soldCount: 25 + (idNum * 14),
      imageUrl: json['primary_image_url']?.toString(),
      placeholderColor: color,
      isFavorite: false,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toInt() ?? 350,
    );
  }

  ProductItem copyWith({
    String? id,
    String? name,
    String? slug,
    String? category,
    double? discountedPrice,
    double? originalPrice,
    int? discountPercentage,
    double? rating,
    int? soldCount,
    String? imageUrl,
    Color? placeholderColor,
    bool? isFavorite,
    int? stock,
    int? weight,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      category: category ?? this.category,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      soldCount: soldCount ?? this.soldCount,
      imageUrl: imageUrl ?? this.imageUrl,
      placeholderColor: placeholderColor ?? this.placeholderColor,
      isFavorite: isFavorite ?? this.isFavorite,
      stock: stock ?? this.stock,
      weight: weight ?? this.weight,
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

  /// Daftar Produk Rekomendasi
  static const List<ProductItem> recommendations = [
    ProductItem(
      id: '1',
      name: 'Kain Batik Tulis Sogan Motif Parang Kusumo',
      category: 'Kain',
      discountedPrice: 345000,
      originalPrice: 450000,
      discountPercentage: 23,
      rating: 4.9,
      soldCount: 142,
      placeholderColor: Color(0xFF8B5E3C),
      isFavorite: true,
    ),
    ProductItem(
      id: '2',
      name: 'Sarung Batik Cap Katun Primisima Laweyan',
      category: 'Sarung',
      discountedPrice: 165000,
      originalPrice: 220000,
      discountPercentage: 25,
      rating: 4.8,
      soldCount: 98,
      placeholderColor: Color(0xFF6B4423),
      isFavorite: false,
    ),
    ProductItem(
      id: '3',
      name: 'Tunik Batik Sutra Motif Truntum Emas Mewah',
      category: 'Tunik',
      discountedPrice: 275000,
      originalPrice: 380000,
      discountPercentage: 28,
      rating: 5.0,
      soldCount: 76,
      placeholderColor: Color(0xFF9C6644),
      isFavorite: false,
    ),
    ProductItem(
      id: '4',
      name: 'Kemeja Batik Anak Motif Kawung Modern Solo',
      category: 'Anak-Anak',
      discountedPrice: 115000,
      originalPrice: 150000,
      discountPercentage: 23,
      rating: 4.7,
      soldCount: 64,
      placeholderColor: Color(0xFF7F4F24),
      isFavorite: true,
    ),
    ProductItem(
      id: '5',
      name: 'Kain Batik Tulis Celup Pewarna Alami Laweyan',
      category: 'Kain',
      discountedPrice: 420000,
      originalPrice: 600000,
      discountPercentage: 30,
      rating: 4.9,
      soldCount: 53,
      placeholderColor: Color(0xFF582F0E),
      isFavorite: false,
    ),
  ];
}
