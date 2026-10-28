/// Model data untuk Provinsi (Master Location)
class ProvinceModel {
  final int id;
  final String name;

  const ProvinceModel({
    required this.id,
    required this.name,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ??
              (json['province_id'] is int
                  ? json['province_id'] as int
                  : int.tryParse(json['province_id']?.toString() ?? '') ?? 0),
      name: json['name'] as String? ?? json['province_name'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProvinceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model data untuk Kota / Kabupaten (Master Location)
class CityModel {
  final int id;
  final int provinceId;
  final String name;
  final String? postalCode;

  const CityModel({
    required this.id,
    required this.provinceId,
    required this.name,
    this.postalCode,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ??
              (json['city_id'] is int
                  ? json['city_id'] as int
                  : int.tryParse(json['city_id']?.toString() ?? '') ?? 0),
      provinceId: json['province_id'] is int
          ? json['province_id'] as int
          : int.tryParse(json['province_id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? json['city_name'] as String? ?? '',
      postalCode: json['postal_code']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model data untuk Kecamatan (Master Location)
class SubdistrictModel {
  final int id;
  final int cityId;
  final String name;

  const SubdistrictModel({
    required this.id,
    required this.cityId,
    required this.name,
  });

  factory SubdistrictModel.fromJson(Map<String, dynamic> json) {
    return SubdistrictModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ??
              (json['subdistrict_id'] is int
                  ? json['subdistrict_id'] as int
                  : int.tryParse(json['subdistrict_id']?.toString() ?? '') ?? 0),
      cityId: json['city_id'] is int
          ? json['city_id'] as int
          : int.tryParse(json['city_id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? json['subdistrict_name'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubdistrictModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
