class UserLocationEntity {
  final int? id;
  final String source; // 'gps' | 'manual'
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? label;
  final DateTime? updatedAt;

  const UserLocationEntity({
    this.id,
    required this.source,
    this.latitude,
    this.longitude,
    this.address,
    this.label,
    this.updatedAt,
  });

  bool get isGps => source.toLowerCase() == 'gps';
  bool get isManual => source.toLowerCase() == 'manual';

  String get displayName {
    if (label != null && label!.trim().isNotEmpty) {
      return label!.trim();
    }
    if (address != null && address!.trim().isNotEmpty) {
      return address!.trim();
    }
    if (latitude != null && longitude != null) {
      return 'Lat: ${latitude!.toStringAsFixed(4)}, Lng: ${longitude!.toStringAsFixed(4)}';
    }
    return 'Lokasi Belum Diatur';
  }

  String get displaySubtitle {
    if (isGps && latitude != null && longitude != null) {
      return 'GPS (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})';
    }
    if (address != null && address!.trim().isNotEmpty) {
      return address!.trim();
    }
    return 'Lokasi Tersimpan';
  }

  UserLocationEntity copyWith({
    int? id,
    String? source,
    double? latitude,
    double? longitude,
    String? address,
    String? label,
    DateTime? updatedAt,
  }) {
    return UserLocationEntity(
      id: id ?? this.id,
      source: source ?? this.source,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      label: label ?? this.label,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
