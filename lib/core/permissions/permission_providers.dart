import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'permission_service.dart';

/// Provider PermissionService singleton
final permissionServiceProvider = Provider<IPermissionService>((ref) {
  return PermissionService();
});

/// State untuk tracking izin yang aktif di aplikasi
class PermissionsState {
  final Map<AppPermissionType, PermissionResult> permissions;
  final bool isLoading;

  const PermissionsState({
    this.permissions = const {},
    this.isLoading = false,
  });

  PermissionsState copyWith({
    Map<AppPermissionType, PermissionResult>? permissions,
    bool? isLoading,
  }) {
    return PermissionsState(
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier untuk mengelola state permission di UI
class PermissionsNotifier extends Notifier<PermissionsState> {
  late final IPermissionService _service;

  @override
  PermissionsState build() {
    _service = ref.watch(permissionServiceProvider);
    // Inisialisasi cek status awal izin
    Future.microtask(() => checkAllPermissions());
    return const PermissionsState(isLoading: true);
  }

  Future<void> checkAllPermissions() async {
    state = state.copyWith(isLoading: true);
    final results = <AppPermissionType, PermissionResult>{};
    for (final type in AppPermissionType.values) {
      results[type] = await _service.checkPermission(type);
    }
    state = state.copyWith(permissions: results, isLoading: false);
  }

  Future<PermissionResult> request(AppPermissionType type) async {
    final result = await _service.requestPermission(type);
    final updated = Map<AppPermissionType, PermissionResult>.from(state.permissions);
    updated[type] = result;
    state = state.copyWith(permissions: updated);
    return result;
  }

  Future<bool> openSettings() => _service.openSettings();
}

final permissionsNotifierProvider =
    NotifierProvider<PermissionsNotifier, PermissionsState>(() {
  return PermissionsNotifier();
});
