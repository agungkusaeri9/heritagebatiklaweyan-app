import '../../../home/data/models/home_dummy_data.dart';

/// Opsi pilihan gender produk
enum GenderFilter { all, men, women }

/// Opsi pengurutan produk
enum SortByFilter {
  mostRecent,
  popular,
  priceLowToHigh,
  priceHighToLow,
}

/// Opsi filter ulasan/rating produk
enum RatingFilter {
  all,
  fourPointFiveAndAbove, // >= 4.5
  fourToFourPointFive,   // 4.0 - 4.5
  threePointFiveToFour,  // 3.5 - 4.0
  threeToThreePointFive, // 3.0 - 3.5
  belowThree,            // < 3.0
}

/// Model state filter produk
class ProductFilter {
  final GenderFilter gender;
  final SortByFilter sortBy;
  final double minPrice;
  final double maxPrice;
  final RatingFilter rating;

  static const double defaultMinPrice = 0.0;
  static const double defaultMaxPrice = 5000000.0;

  const ProductFilter({
    this.gender = GenderFilter.all,
    this.sortBy = SortByFilter.mostRecent,
    this.minPrice = defaultMinPrice,
    this.maxPrice = defaultMaxPrice,
    this.rating = RatingFilter.all,
  });

  bool get isDefault =>
      gender == GenderFilter.all &&
      sortBy == SortByFilter.mostRecent &&
      minPrice == defaultMinPrice &&
      maxPrice == defaultMaxPrice &&
      rating == RatingFilter.all;

  /// Jumlah filter yang sedang aktif
  int get activeFilterCount {
    int count = 0;
    if (gender != GenderFilter.all) count++;
    if (sortBy != SortByFilter.mostRecent) count++;
    if (minPrice > defaultMinPrice || maxPrice < defaultMaxPrice) count++;
    if (rating != RatingFilter.all) count++;
    return count;
  }

  ProductFilter copyWith({
    GenderFilter? gender,
    SortByFilter? sortBy,
    double? minPrice,
    double? maxPrice,
    RatingFilter? rating,
  }) {
    return ProductFilter(
      gender: gender ?? this.gender,
      sortBy: sortBy ?? this.sortBy,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      rating: rating ?? this.rating,
    );
  }

  /// Kolom sort untuk API backend
  String get apiSortColumn {
    switch (sortBy) {
      case SortByFilter.priceLowToHigh:
      case SortByFilter.priceHighToLow:
        return 'price';
      case SortByFilter.mostRecent:
      case SortByFilter.popular:
        return 'created_at';
    }
  }

  /// Arah sort untuk API backend
  String get apiSortDirection {
    switch (sortBy) {
      case SortByFilter.priceLowToHigh:
        return 'asc';
      case SortByFilter.priceHighToLow:
      case SortByFilter.mostRecent:
      case SortByFilter.popular:
        return 'desc';
    }
  }

  /// Melakukan pencocokan kriteria filter pada produk
  bool matches(ProductItem product) {
    // 1. Filter Harga
    final price = product.discountedPrice > 0 ? product.discountedPrice : product.originalPrice;
    if (minPrice > defaultMinPrice && price < minPrice) {
      return false;
    }
    if (maxPrice < defaultMaxPrice && price > maxPrice) {
      return false;
    }

    // 2. Filter Gender (berdasarkan kata kunci nama dan kategori)
    if (gender != GenderFilter.all) {
      final nameLower = product.name.toLowerCase();
      final catLower = product.category.toLowerCase();

      final isMen = nameLower.contains('pria') ||
          nameLower.contains('kemeja') ||
          nameLower.contains('hem') ||
          nameLower.contains('koko') ||
          catLower.contains('pria');

      final isWomen = nameLower.contains('wanita') ||
          nameLower.contains('tunik') ||
          nameLower.contains('dress') ||
          nameLower.contains('blouse') ||
          nameLower.contains('gamis') ||
          nameLower.contains('rok') ||
          catLower.contains('tunik') ||
          catLower.contains('wanita');

      if (gender == GenderFilter.men && !isMen) {
        return false;
      }
      if (gender == GenderFilter.women && !isWomen) {
        return false;
      }
    }

    // 3. Filter Rating
    if (rating != RatingFilter.all) {
      final r = product.rating;
      switch (rating) {
        case RatingFilter.all:
          break;
        case RatingFilter.fourPointFiveAndAbove:
          if (r < 4.5) return false;
          break;
        case RatingFilter.fourToFourPointFive:
          if (r < 4.0 || r > 4.5) return false;
          break;
        case RatingFilter.threePointFiveToFour:
          if (r < 3.5 || r > 4.0) return false;
          break;
        case RatingFilter.threeToThreePointFive:
          if (r < 3.0 || r > 3.5) return false;
          break;
        case RatingFilter.belowThree:
          if (r >= 3.0) return false;
          break;
      }
    }

    return true;
  }

  /// Mengurutkan daftar produk sesuai pilihan sortBy
  List<ProductItem> sortProducts(List<ProductItem> items) {
    final copy = List<ProductItem>.from(items);
    switch (sortBy) {
      case SortByFilter.priceLowToHigh:
        copy.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
        break;
      case SortByFilter.priceHighToLow:
        copy.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
        break;
      case SortByFilter.popular:
        copy.sort((a, b) {
          final comp = b.soldCount.compareTo(a.soldCount);
          if (comp != 0) return comp;
          return b.rating.compareTo(a.rating);
        });
        break;
      case SortByFilter.mostRecent:
        break;
    }
    return copy;
  }
}
