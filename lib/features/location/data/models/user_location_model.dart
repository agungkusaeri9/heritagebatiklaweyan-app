import '../../domain/entities/user_location_entity.dart';

class UserLocationModel {
  final int? id;
  final String source;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? label;
  final DateTime? updatedAt;

  const UserLocationModel({
    this.id,
    required this.source,
    this.latitude,
    this.longitude,
    this.address,
    this.label,
    this.updatedAt,
  });

  factory UserLocationModel.fromJson(Map<String, dynamic> json) {
    return UserLocationModel(
      id: json['id'] is int
          ? json['id'] as int
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      source: json['source']?.toString() ?? 'manual',
      latitude: json['latitude'] != null
          ? (json['latitude'] is num
              ? (json['latitude'] as num).toDouble()
              : double.tryParse(json['latitude'].toString()))
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] is num
              ? (json['longitude'] as num).toDouble()
              : double.tryParse(json['longitude'].toString()))
          : null,
      address: json['address']?.toString(),
      label: json['label']?.toString(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'source': source,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null) 'address': address,
      if (label != null) 'label': label,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  UserLocationEntity toEntity() {
    return UserLocationEntity(
      id: id,
      source: source,
      latitude: latitude,
      longitude: longitude,
      address: address,
      label: label,
      updatedAt: updatedAt,
    );
  }

  factory UserLocationModel.fromEntity(UserLocationEntity entity) {
    return UserLocationModel(
      id: entity.id,
      source: entity.source,
      latitude: entity.latitude,
      longitude: entity.longitude,
      address: entity.address,
      label: entity.label,
      updatedAt: entity.updatedAt,
    );
  }
}
