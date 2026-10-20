import 'package:flutter/material.dart';

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

  const PromoBannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.discountTag,
    required this.buttonText,
    required this.gradientColors,
    this.imageUrl,
    this.icon = Icons.local_offer_rounded,
  });
}

/// Model untuk kategori produk batik
class ProductCategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final int totalItems;

  const ProductCategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    this.totalItems = 0,
  });
}

/// Model untuk kartu produk rekomendasi
class ProductItem {
  final String id;
  final String name;
  final String category;
  final double discountedPrice;
  final double originalPrice;
  final int discountPercentage;
  final double rating;
  final int soldCount;
  final String? imageUrl;
  final Color placeholderColor;
  final bool isFavorite;

  const ProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.discountedPrice,
    required this.originalPrice,
    required this.discountPercentage,
    required this.rating,
    required this.soldCount,
    this.imageUrl,
    required this.placeholderColor,
    this.isFavorite = false,
  });

  ProductItem copyWith({
    bool? isFavorite,
  }) {
    return ProductItem(
      id: id,
      name: name,
      category: category,
      discountedPrice: discountedPrice,
      originalPrice: originalPrice,
      discountPercentage: discountPercentage,
      rating: rating,
      soldCount: soldCount,
      imageUrl: imageUrl,
      placeholderColor: placeholderColor,
      isFavorite: isFavorite ?? this.isFavorite,
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
      icon: Icons.grid_view_rounded,
      totalItems: 84,
    ),
    ProductCategoryItem(
      id: 'sarung',
      name: 'Sarung',
      icon: Icons.checkroom_rounded,
      totalItems: 28,
    ),
    ProductCategoryItem(
      id: 'kain',
      name: 'Kain',
      icon: Icons.texture_rounded,
      totalItems: 35,
    ),
    ProductCategoryItem(
      id: 'tunik',
      name: 'Tunik',
      icon: Icons.woman_rounded,
      totalItems: 22,
    ),
    ProductCategoryItem(
      id: 'anak',
      name: 'Anak-Anak',
      icon: Icons.child_care_rounded,
      totalItems: 16,
    ),
  ];

  /// Daftar Produk Rekomendasi
  static const List<ProductItem> recommendations = [
    ProductItem(
      id: 'prod_1',
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
      id: 'prod_2',
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
      id: 'prod_3',
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
      id: 'prod_4',
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
      id: 'prod_5',
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
