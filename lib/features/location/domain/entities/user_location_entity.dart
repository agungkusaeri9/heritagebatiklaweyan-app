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

  static final RegExp _coordRegExp = RegExp(
    r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$',
  );

  static bool isPlaceholderOrCoordinate(String? value) {
    if (value == null || value.trim().isEmpty) return true;
    final lower = value.trim().toLowerCase();
    return lower == 'lokasi perangkat (gps)' ||
        lower == 'perangkat (gps)' ||
        lower == 'lokasi saat ini' ||
        lower == 'lokasi manual' ||
        lower.startsWith('koordinat') ||
        lower.startsWith('gps (') ||
        lower.startsWith('lat:') ||
        _coordRegExp.hasMatch(lower);
  }

  /// Apakah lokasi sudah memiliki nama alamat yang valid (bukan koordinat mentah / placeholder)
  bool get hasResolvedAddress {
    return (address != null && !isPlaceholderOrCoordinate(address)) ||
        (label != null && !isPlaceholderOrCoordinate(label));
  }

  /// Menampilkan nama lokasi / alamat sebenarnya (tidak pernah menampilkan koordinat mentah)
  String get displayName {
    if (address != null && !isPlaceholderOrCoordinate(address)) {
      return address!.trim();
    }
    if (label != null && !isPlaceholderOrCoordinate(label)) {
      return label!.trim();
    }
    return 'Pilih Lokasi Pengiriman';
  }

  String get displaySubtitle {
    if (address != null && !isPlaceholderOrCoordinate(address)) {
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
