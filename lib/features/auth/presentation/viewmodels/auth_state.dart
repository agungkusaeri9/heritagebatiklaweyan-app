import '../../domain/entities/user_entity.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// State representasi untuk MVVM Auth toko online
class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final List<String> logs;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.logs = const [],
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasError => status == AuthStatus.error && errorMessage != null;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    List<String>? logs,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      logs: logs ?? this.logs,
    );
  }

  AuthState addLog(String log) {
    final updatedLogs = List<String>.from(logs)..add(log);
    if (updatedLogs.length > 20) {
      updatedLogs.removeAt(0);
    }
    return copyWith(logs: updatedLogs);
  }
}
