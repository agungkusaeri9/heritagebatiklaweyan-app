/// Model data untuk alamat pengiriman customer (Customer Address)
class CustomerAddressModel {
  final int id;
  final String? label;
  final String recipientName;
  final String phone;
  final String fullAddress;
  final int? provinceId;
  final String? provinceName;
  final int? cityId;
  final String? cityName;
  final int? subdistrictId;
  final String? subdistrictName;
  final String? postalCode;
  final bool isPrimary;

  const CustomerAddressModel({
    required this.id,
    this.label,
    required this.recipientName,
    required this.phone,
    required this.fullAddress,
    this.provinceId,
    this.provinceName,
    this.cityId,
    this.cityName,
    this.subdistrictId,
    this.subdistrictName,
    this.postalCode,
    this.isPrimary = false,
  });

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic val) {
      if (val is int) return val;
      if (val != null) return int.tryParse(val.toString());
      return null;
    }

    String? parseName(dynamic val) {
      if (val is Map) return val['name']?.toString();
      return val?.toString();
    }

    int? parseSubId(dynamic val) {
      if (val is Map) return parseId(val['id']);
      return parseId(val);
    }

    return CustomerAddressModel(
      id: parseId(json['id']) ?? 0,
      label: json['label']?.toString(),
      recipientName: json['recipient_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      fullAddress: json['full_address']?.toString() ?? '',
      provinceId: parseSubId(json['province']) ?? parseId(json['province_id']),
      provinceName: parseName(json['province']),
      cityId: parseSubId(json['city']) ?? parseId(json['city_id']),
      cityName: parseName(json['city']),
      subdistrictId: parseSubId(json['subdistrict']) ?? parseId(json['subdistrict_id']),
      subdistrictName: parseName(json['subdistrict']),
      postalCode: json['postal_code']?.toString(),
      isPrimary: json['is_primary'] is bool
          ? json['is_primary'] as bool
          : (json['is_primary'] == 1 || json['is_primary'] == '1'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (label != null) 'label': label,
      'recipient_name': recipientName,
      'phone': phone,
      'full_address': fullAddress,
      if (provinceId != null) 'province_id': provinceId,
      if (cityId != null) 'city_id': cityId,
      if (subdistrictId != null) 'subdistrict_id': subdistrictId,
      if (postalCode != null) 'postal_code': postalCode,
      'is_primary': isPrimary,
    };
  }

  /// Teks alamat lengkap rapi berurutan
  String get formattedAddress {
    final parts = <String>[];
    if (fullAddress.isNotEmpty) parts.add(fullAddress);
    if (subdistrictName != null && subdistrictName!.isNotEmpty) parts.add(subdistrictName!);
    if (cityName != null && cityName!.isNotEmpty) parts.add(cityName!);
    if (provinceName != null && provinceName!.isNotEmpty) parts.add(provinceName!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }

  CustomerAddressModel copyWith({
    int? id,
    String? label,
    String? recipientName,
    String? phone,
    String? fullAddress,
    int? provinceId,
    String? provinceName,
    int? cityId,
    String? cityName,
    int? subdistrictId,
    String? subdistrictName,
    String? postalCode,
    bool? isPrimary,
  }) {
    return CustomerAddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      fullAddress: fullAddress ?? this.fullAddress,
      provinceId: provinceId ?? this.provinceId,
      provinceName: provinceName ?? this.provinceName,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      subdistrictId: subdistrictId ?? this.subdistrictId,
      subdistrictName: subdistrictName ?? this.subdistrictName,
      postalCode: postalCode ?? this.postalCode,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
