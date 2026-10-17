/// Model data untuk Metode Pembayaran (Payment Method)
class PaymentMethodModel {
  final int id;
  final String name;
  final String accountName;
  final String accountNumber;
  final String? logoUrl;
  final bool isActive;

  const PaymentMethodModel({
    required this.id,
    required this.name,
    required this.accountName,
    required this.accountNumber,
    this.logoUrl,
    this.isActive = true,
  });

  /// Factory untuk parsing dari JSON response backend API
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['is_active'] == 1 || json['is_active'] == '1'),
    );
  }

  /// Konversi ke Map untuk SQLite database local
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'account_name': accountName,
      'account_number': accountNumber,
      'logo_url': logoUrl,
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Factory untuk membaca dari SQLite database local
  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      accountName: map['account_name'] as String? ?? '',
      accountNumber: map['account_number'] as String? ?? '',
      logoUrl: map['logo_url'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
