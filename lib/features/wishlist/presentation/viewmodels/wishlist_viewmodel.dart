import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/repositories/wishlist_repository.dart';
import 'wishlist_providers.dart';
import 'wishlist_state.dart';

class WishlistViewModel extends Notifier<WishlistState> {
  late WishlistRepository _repository;

  @override
  WishlistState build() {
    _repository = ref.watch(wishlistRepositoryProvider);

    // Muat data hanya bila sesi sudah authenticated. Guest tidak memicu
    // request yang akan berujung 401.
    Future.microtask(() {
      if (ref.read(authViewModelProvider).isAuthenticated) {
        loadWishlist();
      }
    });

    return const WishlistState();
  }

  Future<void> loadWishlist() async {
    if (!ref.read(authViewModelProvider).isAuthenticated) {
      state = state.copyWith(
        status: WishlistStatus.success,
        items: const [],
        clearError: true,
      );
      return;
    }

    state = state.copyWith(status: WishlistStatus.loading, clearError: true);
    try {
      final items = await _repository.getWishlist();
      state = state.copyWith(
        status: WishlistStatus.success,
        items: items,
        clearError: true,
      );
    } on ApiException catch (e) {
      AppLogger.w('WishlistViewModel load failure: ${e.message}');
      state = state.copyWith(
        status: WishlistStatus.error,
        errorMessage: e.message,
      );
    } catch (e, stack) {
      AppLogger.e('WishlistViewModel load error', error: e, stackTrace: stack);
      state = state.copyWith(
        status: WishlistStatus.error,
        errorMessage: 'Gagal memuat wishlist.',
      );
    }
  }

  bool isWishlisted(dynamic productId) => state.containsProductId(productId);

  /// Toggle status wishlist untuk satu produk. Mengembalikan status akhir
  /// (true = kini ada di wishlist). Melempar pesan error via [onError].
  Future<bool> toggleWishlist(
    int productId, {
    void Function(String message)? onError,
  }) async {
    const loginMsg = 'Silakan login terlebih dahulu untuk menyimpan ke wishlist.';
    if (!ref.read(authViewModelProvider).isAuthenticated) {
      onError?.call(loginMsg);
      return false;
    }

    if (state.isToggling) return isWishlisted(productId);
    final wasWishlisted = isWishlisted(productId);

    state = state.copyWith(isToggling: true, clearError: true);
    try {
      if (wasWishlisted) {
        await _repository.removeFromWishlist(productId);
        final items = state.items
            .where((e) => e.productId != productId)
            .toList();
        state = state.copyWith(
          isToggling: false,
          status: WishlistStatus.success,
          items: items,
        );
        return false;
      }

      final added = await _repository.addToWishlist(productId);
      final items = [
        added,
        ...state.items.where((e) => e.productId != productId),
      ];
      state = state.copyWith(
        isToggling: false,
        status: WishlistStatus.success,
        items: items,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isToggling: false, errorMessage: e.message);
      onError?.call(e.message);
      return wasWishlisted;
    } catch (e, stack) {
      AppLogger.e('WishlistViewModel toggle error', error: e, stackTrace: stack);
      const msg = 'Gagal memperbarui wishlist.';
      state = state.copyWith(isToggling: false, errorMessage: msg);
      onError?.call(msg);
      return wasWishlisted;
    }
  }
}
