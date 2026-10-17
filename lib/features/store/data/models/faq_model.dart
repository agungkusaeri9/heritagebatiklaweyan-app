/// Model data untuk FAQ (Frequently Asked Questions)
class FaqModel {
  final int id;
  final String title;
  final String description;
  final String category;
  final int order;
  final bool isActive;

  const FaqModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.order = 0,
    this.isActive = true,
  });

  /// Factory untuk parsing dari JSON response backend API
  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Umum',
      order: json['order'] is int
          ? json['order'] as int
          : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['is_active'] == 1 || json['is_active'] == '1'),
    );
  }

  /// Konversi ke Map untuk SQLite database local
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'order_position': order,
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Factory untuk membaca dari SQLite database local
  factory FaqModel.fromMap(Map<String, dynamic> map) {
    return FaqModel(
      id: map['id'] as int,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Umum',
      order: map['order_position'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
