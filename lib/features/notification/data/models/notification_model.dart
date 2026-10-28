/// Model untuk data kategori notifikasi
class NotificationCategoryModel {
  final String code;
  final String name;

  const NotificationCategoryModel({
    required this.code,
    required this.name,
  });

  factory NotificationCategoryModel.fromJson(Map<String, dynamic> json) {
    return NotificationCategoryModel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }
}

/// Model untuk pagination notifikasi
class NotificationPaginationModel {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final bool hasMorePages;

  const NotificationPaginationModel({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.hasMorePages,
  });

  factory NotificationPaginationModel.fromJson(Map<String, dynamic> json) {
    return NotificationPaginationModel(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      hasMorePages: json['has_more_pages'] == true,
    );
  }

  const NotificationPaginationModel.empty()
      : currentPage = 1,
        perPage = 10,
        total = 0,
        lastPage = 1,
        hasMorePages = false;
}

/// Model representasi data notifikasi dari API
class NotificationModel {
  final int id;
  final int? userId;
  final String title;
  final String message;
  final String recipientType;
  final NotificationCategoryModel? category;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    this.recipientType = 'CUSTOMER',
    this.category,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt;
    try {
      final rawCreated = json['created_at']?.toString();
      parsedCreatedAt = rawCreated != null ? DateTime.parse(rawCreated).toLocal() : DateTime.now();
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    DateTime? parsedReadAt;
    try {
      final rawRead = json['read_at']?.toString();
      if (rawRead != null && rawRead.isNotEmpty) {
        parsedReadAt = DateTime.parse(rawRead).toLocal();
      }
    } catch (_) {
      parsedReadAt = null;
    }

    NotificationCategoryModel? parsedCategory;
    if (json['category'] is Map<String, dynamic>) {
      parsedCategory = NotificationCategoryModel.fromJson(json['category'] as Map<String, dynamic>);
    }

    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      recipientType: json['recipient_type']?.toString() ?? 'CUSTOMER',
      category: parsedCategory,
      isRead: json['is_read'] == true,
      readAt: parsedReadAt,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'recipient_type': recipientType,
      'category': category?.toJson(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    String? recipientType,
    NotificationCategoryModel? category,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      recipientType: recipientType ?? this.recipientType,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Kode kategori notifikasi (PROMO_DISCOUNT, ORDER_STATUS_UPDATE, GENERAL_ANNOUNCEMENT, ADMIN_ALERT)
  String get categoryCode => category?.code.toUpperCase() ?? '';

  /// Nama kategori notifikasi untuk label atau badge
  String get categoryName => category?.name.isNotEmpty == true ? category!.name : 'Info';

  /// Helper format waktu relatif (misal: "5m ago", "1h ago", "Yesterday", dll)
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final day = createdAt.day.toString().padLeft(2, '0');
      final month = _monthName(createdAt.month);
      final year = createdAt.year;
      return '$day $month $year';
    }
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}

/// Struktur kelompok notifikasi berdasarkan tanggal (Today, Yesterday, Date)
class NotificationDateGroup {
  final String title;
  final DateTime date;
  final List<NotificationModel> items;

  const NotificationDateGroup({
    required this.title,
    required this.date,
    required this.items,
  });

  /// Jumlah notifikasi yang belum dibaca dalam kelompok tanggal ini
  int get unreadCount => items.where((item) => !item.isRead).length;

  /// Daftar ID notifikasi yang belum dibaca dalam kelompok ini
  List<int> get unreadNotificationIds =>
      items.where((item) => !item.isRead).map((item) => item.id).toList();

  /// Daftar seluruh ID notifikasi dalam kelompok ini
  List<int> get allNotificationIds => items.map((item) => item.id).toList();
}
