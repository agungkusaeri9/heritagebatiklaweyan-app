import '../../../../core/constants/api_constants.dart';

/// Model data untuk Pengaturan Toko (Store Settings)
class StoreSettingModel {
  final int id;
  final String name;
  final String? logoUrl;
  final String? description;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? website;
  final String? facebookUrl;
  final String? twitterUrl;
  final String? instagramUrl;
  final String? address;
  final String? privacyPolicy;
  final String? policy;
  final String? cancellationPolicy;
  final String? updatedAt;

  const StoreSettingModel({
    this.id = 1,
    required this.name,
    this.logoUrl,
    this.description,
    this.phone,
    this.whatsapp,
    this.email,
    this.website,
    this.facebookUrl,
    this.twitterUrl,
    this.instagramUrl,
    this.address,
    this.privacyPolicy,
    this.policy,
    this.cancellationPolicy,
    this.updatedAt,
  });

  static String? _normalizeImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      final serverUri = Uri.tryParse(ApiConstants.serverUrl);
      if (uri != null && serverUri != null) {
        if (uri.path.contains('/storage/') ||
            uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host == '10.0.2.2') {
          return uri
              .replace(
                scheme: serverUri.scheme,
                host: serverUri.host,
                port: serverUri.port,
              )
              .toString();
        }
      }
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '${ApiConstants.serverUrl}$cleanPath';
  }

  /// Factory untuk parsing dari JSON response backend API
  factory StoreSettingModel.fromJson(Map<String, dynamic> json) {
    final contact = json['contact'] is Map<String, dynamic>
        ? json['contact'] as Map<String, dynamic>
        : null;
    final socialMedia = json['social_media'] is Map<String, dynamic>
        ? json['social_media'] as Map<String, dynamic>
        : null;
    final policies = json['policies'] is Map<String, dynamic>
        ? json['policies'] as Map<String, dynamic>
        : null;

    return StoreSettingModel(
      id: (json['id'] as num?)?.toInt() ?? 1,
      name: (json['name'] as String?)?.isNotEmpty == true
          ? json['name'] as String
          : 'Heritage Batik Laweyan',
      logoUrl: _normalizeImageUrl(json['logo_url']?.toString()),
      description: json['description'] as String?,
      phone: contact?['phone'] as String? ?? json['phone'] as String?,
      whatsapp: contact?['whatsapp'] as String? ?? json['whatsapp'] as String?,
      email: contact?['email'] as String? ?? json['email'] as String?,
      website: contact?['website'] as String? ?? json['website'] as String?,
      facebookUrl:
          socialMedia?['facebook_url'] as String? ??
          json['facebook_url'] as String?,
      twitterUrl:
          socialMedia?['twitter_url'] as String? ??
          json['twitter_url'] as String?,
      instagramUrl:
          socialMedia?['instagram_url'] as String? ??
          json['instagram_url'] as String?,
      address: json['address'] as String?,
      privacyPolicy:
          policies?['privacy_policy'] as String? ??
          json['privacy_policy'] as String?,
      policy: policies?['policy'] as String? ?? json['policy'] as String?,
      cancellationPolicy:
          policies?['cancellation_policy'] as String? ??
          json['cancellation_policy'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  /// Konversi ke Map untuk SQLite database local
  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'name': name,
      'logo_url': logoUrl,
      'description': description,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'website': website,
      'facebook_url': facebookUrl,
      'twitter_url': twitterUrl,
      'instagram_url': instagramUrl,
      'address': address,
      'privacy_policy': privacyPolicy,
      'policy': policy,
      'cancellation_policy': cancellationPolicy,
      'updated_at': updatedAt,
    };
  }

  /// Factory untuk membaca dari SQLite database local
  factory StoreSettingModel.fromMap(Map<String, dynamic> map) {
    return StoreSettingModel(
      id: map['id'] as int? ?? 1,
      name: map['name'] as String? ?? 'Heritage Batik Laweyan',
      logoUrl: map['logo_url'] as String?,
      description: map['description'] as String?,
      phone: map['phone'] as String?,
      whatsapp: map['whatsapp'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      facebookUrl: map['facebook_url'] as String?,
      twitterUrl: map['twitter_url'] as String?,
      instagramUrl: map['instagram_url'] as String?,
      address: map['address'] as String?,
      privacyPolicy: map['privacy_policy'] as String?,
      policy: map['policy'] as String?,
      cancellationPolicy: map['cancellation_policy'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
