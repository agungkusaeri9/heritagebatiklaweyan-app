import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/repositories/cart_repository.dart';
import 'cart_providers.dart';
import 'cart_state.dart';

class CartViewModel extends Notifier<CartState> {
  late final CartRepository _repository;

  @override
  CartState build() {
    _repository = ref.watch(cartRepositoryProvider);
    return const CartState();
  }

  /// Memuat daftar item keranjang dari API backend
  Future<void> loadCart({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      state = state.copyWith(status: CartStatus.loading, errorMessage: null);
    }

    try {
      final result = await _repository.getCart();

      state = state.copyWith(
        status: CartStatus.success,
        isRefreshing: false,
        items: result.items,
        summary: result.summary,
        errorMessage: null,
      );
    } catch (e, stack) {
      AppLogger.e('Gagal memuat keranjang belanja', error: e, stackTrace: stack);
      state = state.copyWith(
        status: CartStatus.error,
        isRefreshing: false,
        errorMessage: 'Gagal memuat keranjang belanja. Silakan periksa koneksi internet Anda.',
      );
    }
  }

  /// Menambah kuantitas produk (+1)
  Future<void> incrementQuantity(int cartId, {void Function(String message)? onError}) async {
    if (state.isItemUpdating(cartId)) return;

    final index = state.items.indexWhere((item) => item.id == cartId);
    if (index == -1) return;

    final currentItem = state.items[index];
    if (currentItem.qty >= 20) {
      onError?.call('Maksimal jumlah barang per produk adalah 20.');
      return;
    }

    if (currentItem.qty >= currentItem.stock && currentItem.stock > 0) {
      onError?.call('Jumlah melebihi stok yang tersedia (${currentItem.stock} pcs).');
      return;
    }

    final newQty = currentItem.qty + 1;
    final optimisticItem = currentItem.copyWith(
      qty: newQty,
      total: currentItem.productPrice * newQty,
      totalWeight: currentItem.weight * newQty,
    );

    // Optimistic Update
    final updatedList = List<CartItemModel>.from(state.items);
    updatedList[index] = optimisticItem;

    state = state.copyWith(
      items: updatedList,
      updatingItemIds: {...state.updatingItemIds, cartId},
    );

    try {
      final serverItem = await _repository.updateQuantity(cartId, newQty);

      final currentUpdating = Set<int>.from(state.updatingItemIds)..remove(cartId);
      final refreshedList = List<CartItemModel>.from(state.items);
      final refreshIndex = refreshedList.indexWhere((i) => i.id == cartId);
      if (refreshIndex != -1) {
        refreshedList[refreshIndex] = serverItem;
      }

      state = state.copyWith(
        items: refreshedList,
        updatingItemIds: currentUpdating,
      );
    } catch (e, stack) {
      AppLogger.e('Gagal menambah kuantitas produk id $cartId', error: e, stackTrace: stack);

      // Rollback ke kuantitas awal
      final rollbackList = List<CartItemModel>.from(state.items);
      final rollbackIndex = rollbackList.indexWhere((i) => i.id == cartId);
      if (rollbackIndex != -1) {
        rollbackList[rollbackIndex] = currentItem;
      }
      final currentUpdating = Set<int>.from(state.updatingItemIds)..remove(cartId);

      state = state.copyWith(
        items: rollbackList,
        updatingItemIds: currentUpdating,
      );
      onError?.call('Gagal memperbarui jumlah produk. Silakan coba lagi.');
    }
  }

  /// Mengurangi kuantitas produk (-1) atau memicu konfirmasi hapus jika qty == 1
  Future<void> decrementQuantity(
    int cartId, {
    required VoidCallback onDeleteConfirm,
    void Function(String message)? onError,
  }) async {
    if (state.isItemUpdating(cartId)) return;

    final index = state.items.indexWhere((item) => item.id == cartId);
    if (index == -1) return;

    final currentItem = state.items[index];

    // Jika kuantitas sudah 1, pemicu dialog konfirmasi hapus
    if (currentItem.qty <= 1) {
      onDeleteConfirm();
      return;
    }

    final newQty = currentItem.qty - 1;
    final optimisticItem = currentItem.copyWith(
      qty: newQty,
      total: currentItem.productPrice * newQty,
      totalWeight: currentItem.weight * newQty,
    );

    // Optimistic Update
    final updatedList = List<CartItemModel>.from(state.items);
    updatedList[index] = optimisticItem;

    state = state.copyWith(
      items: updatedList,
      updatingItemIds: {...state.updatingItemIds, cartId},
    );

    try {
      final serverItem = await _repository.updateQuantity(cartId, newQty);

      final currentUpdating = Set<int>.from(state.updatingItemIds)..remove(cartId);
      final refreshedList = List<CartItemModel>.from(state.items);
      final refreshIndex = refreshedList.indexWhere((i) => i.id == cartId);
      if (refreshIndex != -1) {
        refreshedList[refreshIndex] = serverItem;
      }

      state = state.copyWith(
        items: refreshedList,
        updatingItemIds: currentUpdating,
      );
    } catch (e, stack) {
      AppLogger.e('Gagal mengurangi kuantitas produk id $cartId', error: e, stackTrace: stack);

      // Rollback
      final rollbackList = List<CartItemModel>.from(state.items);
      final rollbackIndex = rollbackList.indexWhere((i) => i.id == cartId);
      if (rollbackIndex != -1) {
        rollbackList[rollbackIndex] = currentItem;
      }
      final currentUpdating = Set<int>.from(state.updatingItemIds)..remove(cartId);

      state = state.copyWith(
        items: rollbackList,
        updatingItemIds: currentUpdating,
      );
      onError?.call('Gagal memperbarui jumlah produk. Silakan coba lagi.');
    }
  }

  /// Menghapus item dari keranjang dengan optimistic update
  Future<void> deleteItem(int cartId, {void Function(String message)? onError}) async {
    if (state.isItemDeleting(cartId)) return;

    final removedItemIndex = state.items.indexWhere((i) => i.id == cartId);
    if (removedItemIndex == -1) return;
    final removedItem = state.items[removedItemIndex];

    // Optimistic removal
    final updatedList = state.items.where((item) => item.id != cartId).toList();

    state = state.copyWith(
      items: updatedList,
      deletingItemIds: {...state.deletingItemIds, cartId},
    );

    try {
      await _repository.deleteItem(cartId);

      final currentDeleting = Set<int>.from(state.deletingItemIds)..remove(cartId);
      state = state.copyWith(deletingItemIds: currentDeleting);
    } catch (e, stack) {
      AppLogger.e('Gagal menghapus item keranjang id $cartId', error: e, stackTrace: stack);

      // Kembalikan item ke daftar jika request gagal
      final rollbackList = List<CartItemModel>.from(state.items);
      if (removedItemIndex <= rollbackList.length) {
        rollbackList.insert(removedItemIndex, removedItem);
      } else {
        rollbackList.add(removedItem);
      }
      final currentDeleting = Set<int>.from(state.deletingItemIds)..remove(cartId);

      state = state.copyWith(
        items: rollbackList,
        deletingItemIds: currentDeleting,
      );
      onError?.call('Gagal menghapus item dari keranjang.');
    }
  }

  /// Menambahkan produk ke keranjang belanja
  Future<bool> addToCart(
    int productId, {
    int quantity = 1,
    String? variantInfo,
    void Function(String message)? onError,
  }) async {
    try {
      final newItem = await _repository.addToCart(
        productId,
        quantity,
        variantInfo: variantInfo,
      );

      final existingIndex = state.items.indexWhere((item) => item.productId == productId);
      final List<CartItemModel> updatedList = List.from(state.items);

      if (existingIndex != -1) {
        updatedList[existingIndex] = newItem;
      } else {
        updatedList.insert(0, newItem);
      }

      state = state.copyWith(
        items: updatedList,
      );

      // Muat ulang keranjang agar ringkasan ter-update
      loadCart(isRefresh: true);

      return true;
    } catch (e, stack) {
      AppLogger.e('Gagal menambahkan produk ke keranjang', error: e, stackTrace: stack);
      final message = e is ApiException ? e.message : 'Gagal menambahkan produk ke keranjang.';
      onError?.call(message);
      return false;
    }
  }
}
