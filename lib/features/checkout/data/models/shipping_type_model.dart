import '../../../../core/utils/currency_formatter.dart';

/// Model data untuk kurir dan opsi tipe pengiriman (Shipping Type)
class ShippingTypeModel {
  final int id;
  final int? courierId;
  final String name;
  final String code;
  final String? description;
  final String? logo;
  final double fee;
  final String estimatedDays;
  final bool isActive;

  const ShippingTypeModel({
    required this.id,
    this.courierId,
    required this.name,
    required this.code,
    this.description,
    this.logo,
    this.fee = 15000.0,
    this.estimatedDays = 'Estimated Arrival 2 - 3 Days',
    this.isActive = true,
  });

  /// ID kurir asli di database (1: JNE, 2: POS, 3: TIKI, dll)
  int get effectiveCourierId => courierId ?? id;

  factory ShippingTypeModel.fromJson(Map<String, dynamic> json) {
    final codeStr = json['code']?.toString().toLowerCase() ?? '';
    double defaultFee = 15000.0;
    String defaultEst = 'Estimated Arrival 2 - 3 Days';

    if (codeStr.contains('pos')) {
      defaultFee = 12000.0;
      defaultEst = 'Estimated Arrival 3 - 5 Days';
    } else if (codeStr.contains('tiki')) {
      defaultFee = 18000.0;
      defaultEst = 'Estimated Arrival 1 - 2 Days';
    }

    final courierIdVal = json['courier_id'] is int
        ? json['courier_id'] as int
        : int.tryParse(json['courier_id']?.toString() ?? '');

    return ShippingTypeModel(
      id: json['id'] is int
          ? json['id'] as int
          : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      courierId: courierIdVal,
      name: json['name'] as String? ?? 'Pengiriman Standar',
      code: json['code'] as String? ?? 'std',
      description: json['description'] as String?,
      logo: json['logo'] as String?,
      fee: json['fee'] != null
          ? (json['fee'] is num ? (json['fee'] as num).toDouble() : (double.tryParse(json['fee'].toString()) ?? defaultFee))
          : defaultFee,
      estimatedDays: json['estimated_days'] as String? ?? defaultEst,
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['is_active'] == 1 || json['is_active'] == '1'),
    );
  }

  String get formattedFee => formatRupiah(fee);

  ShippingTypeModel copyWith({
    int? id,
    int? courierId,
    String? name,
    String? code,
    String? description,
    String? logo,
    double? fee,
    String? estimatedDays,
    bool? isActive,
  }) {
    return ShippingTypeModel(
      id: id ?? this.id,
      courierId: courierId ?? this.courierId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      fee: fee ?? this.fee,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShippingTypeModel &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          id == other.id;

  @override
  int get hashCode => id.hashCode ^ code.hashCode;
}
