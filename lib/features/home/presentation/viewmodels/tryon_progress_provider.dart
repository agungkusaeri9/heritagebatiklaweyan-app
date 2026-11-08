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

  @override
  TryOnProgressState build() {
    ref.onDispose(_stopPolling);
    return const TryOnProgressState();
  }

  void addTask(VirtualTryOnTaskItem task) {
    final current = List<VirtualTryOnTaskItem>.from(state.activeTasks);
    final idx = current.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      current[idx] = task;
    } else {
      current.insert(0, task);
    }
    state = state.copyWith(activeTasks: current, isMinimized: false);
    _startPolling();
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

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollAll(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollAll() async {
    final tasks = state.activeTasks;
    final activeTasks = tasks.where((t) => t.isActive).toList();
    if (activeTasks.isEmpty) {
      _stopPolling();
      return;
    }

    final repo = ref.read(homeRepositoryProvider);
    final updated = List<VirtualTryOnTaskItem>.from(tasks);

    for (final task in activeTasks) {
      try {
        final fresh = await repo.getVirtualTryOnProgress(task.id);
        final idx = updated.indexWhere((t) => t.id == task.id);
        if (idx >= 0) {
          updated[idx] = fresh;
        }
      } catch (_) {}
    }

    state = state.copyWith(activeTasks: updated);

    if (!updated.any((t) => t.isActive)) {
      _stopPolling();
    }
  }
}

final tryOnProgressProvider =
    NotifierProvider<TryOnProgressNotifier, TryOnProgressState>(
  () => TryOnProgressNotifier(),
);
