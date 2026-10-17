/// Domain Entity untuk Token Autentikasi (Access Token & Refresh Token)
class AuthTokenEntity {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int expiresIn;

  const AuthTokenEntity({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 3600,
  });
}
