import '../constants/api_constants.dart';

/// Normalisasi URL media dari backend menjadi URL absolut yang dapat dimuat
/// Image.network. Backend sering mengirim path relatif (mis. `/storage/...`),
/// atau URL dengan host localhost/10.0.2.2 yang tidak valid di perangkat nyata.
String? normalizeMediaUrl(dynamic raw) {
  final str = raw?.toString().trim();
  if (str == null || str.isEmpty) return null;

  final serverUri = Uri.tryParse(ApiConstants.serverUrl);

  if (str.startsWith('http://') || str.startsWith('https://')) {
    final uri = Uri.tryParse(str);
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
    return str;
  }

  final cleanPath = str.startsWith('/') ? str : '/$str';
  return '${ApiConstants.serverUrl}$cleanPath';
}
