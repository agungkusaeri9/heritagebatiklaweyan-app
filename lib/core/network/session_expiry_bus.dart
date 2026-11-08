import 'dart:async';

/// Bus global untuk menandai sesi autentikasi berakhir (mis. 401 yang tak
/// bisa di-refresh). Sengaja bebas dari Riverpod agar [AuthInterceptor] tidak
/// bergantung pada provider auth (mencegah CircularDependencyError).
///
/// Lapisan auth/app melakukan `listen` lalu memanggil `logout()` sehingga
/// state berubah ke unauthenticated dan router guard mengarahkan ke /login.
class SessionExpiryBus {
  SessionExpiryBus._();

  static final _controller = StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notifyExpired() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
