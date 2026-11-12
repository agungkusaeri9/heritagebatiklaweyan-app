import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/home_dummy_data.dart';
import 'home_providers.dart';

class TryOnProgressState {
  final List<VirtualTryOnTaskItem> activeTasks;
  final bool isMinimized;

  const TryOnProgressState({
    this.activeTasks = const [],
    this.isMinimized = false,
  });

  bool get hasActiveTasks => activeTasks.isNotEmpty;

  int get totalProgress {
    if (activeTasks.isEmpty) return 0;
    final sum = activeTasks.fold<int>(0, (s, t) => s + t.progress);
    return (sum / activeTasks.length).round();
  }

  TryOnProgressState copyWith({
    List<VirtualTryOnTaskItem>? activeTasks,
    bool? isMinimized,
  }) {
    return TryOnProgressState(
      activeTasks: activeTasks ?? this.activeTasks,
      isMinimized: isMinimized ?? this.isMinimized,
    );
  }
}

class TryOnProgressNotifier extends Notifier<TryOnProgressState> {
  Timer? _pollTimer;
  bool _isPolling = false;

  @override
  TryOnProgressState build() {
    ref.onDispose(_stopPolling);
    return const TryOnProgressState();
  }

  void addTask(VirtualTryOnTaskItem task, {bool expand = true}) {
    final current = List<VirtualTryOnTaskItem>.from(state.activeTasks);
    final idx = current.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      final old = current[idx];
      current[idx] = _mergeTask(old, task);
    } else {
      current.insert(0, task);
    }
    state = state.copyWith(
      activeTasks: current,
      isMinimized: expand ? false : state.isMinimized,
    );
    if (current.any((t) => t.isActive)) {
      _ensurePollingStarted();
    } else {
      _stopPolling();
    }
  }

  VirtualTryOnTaskItem _mergeTask(
    VirtualTryOnTaskItem oldTask,
    VirtualTryOnTaskItem fresh,
  ) {
    return VirtualTryOnTaskItem(
      id: fresh.id,
      productId: fresh.productId ?? oldTask.productId,
      productName: fresh.productName ?? oldTask.productName,
      productPrice: fresh.productPrice ?? oldTask.productPrice,
      productSku: fresh.productSku ?? oldTask.productSku,
      productImageUrl: fresh.productImageUrl ?? oldTask.productImageUrl,
      virtualTryOnModelId:
          fresh.virtualTryOnModelId ?? oldTask.virtualTryOnModelId,
      modelName: fresh.modelName ?? oldTask.modelName,
      modelPhotoUrl: fresh.modelPhotoUrl ?? oldTask.modelPhotoUrl,
      gender: fresh.gender ?? oldTask.gender,
      status: fresh.status,
      progress: fresh.progress,
      stepLabel: fresh.stepLabel ?? oldTask.stepLabel,
      photoUrl: fresh.photoUrl ?? oldTask.photoUrl,
      videoUrl: fresh.videoUrl ?? oldTask.videoUrl,
      generateVideo: fresh.generateVideo,
      errorMessage: fresh.errorMessage,
      createdAt: fresh.createdAt ?? oldTask.createdAt,
    );
  }

  void removeTask(int taskId) {
    final current = state.activeTasks.where((t) => t.id != taskId).toList();
    state = state.copyWith(activeTasks: current);
    if (!state.hasActiveTasks || !current.any((t) => t.isActive)) {
      _stopPolling();
    }
  }

  void dismissAll() {
    _stopPolling();
    state = const TryOnProgressState();
  }

  void toggleMinimized() {
    state = state.copyWith(isMinimized: !state.isMinimized);
  }

  void setMinimized(bool value) {
    state = state.copyWith(isMinimized: value);
  }

  void _ensurePollingStarted() {
    if (_pollTimer != null && _pollTimer!.isActive) return;
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollAll(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  Future<void> _pollAll() async {
    if (_isPolling) return;

    final tasks = state.activeTasks;
    final activeTasks = tasks.where((t) => t.isActive).toList();
    if (activeTasks.isEmpty) {
      _stopPolling();
      return;
    }

    _isPolling = true;
    try {
      final repo = ref.read(homeRepositoryProvider);
      final updated = List<VirtualTryOnTaskItem>.from(state.activeTasks);

      for (final task in activeTasks) {
        try {
          final fresh = await repo.getVirtualTryOnProgress(task.id);
          final idx = updated.indexWhere((t) => t.id == task.id);
          if (idx >= 0) {
            updated[idx] = _mergeTask(updated[idx], fresh);
          }
        } catch (_) {}
      }

      state = state.copyWith(activeTasks: updated);

      if (!updated.any((t) => t.isActive)) {
        _stopPolling();
      }
    } finally {
      _isPolling = false;
    }
  }
}

final tryOnProgressProvider =
    NotifierProvider<TryOnProgressNotifier, TryOnProgressState>(
  () => TryOnProgressNotifier(),
);
