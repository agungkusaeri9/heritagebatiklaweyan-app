import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/home_dummy_data.dart';
import '../viewmodels/tryon_progress_provider.dart';

class FloatingTryOnProgress extends ConsumerWidget {
  const FloatingTryOnProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(tryOnProgressProvider);

    if (!progressState.hasActiveTasks) return const SizedBox.shrink();

    if (progressState.isMinimized) {
      return _MinimizedBubble(state: progressState);
    }

    return _ExpandedCard(state: progressState);
  }
}

class _MinimizedBubble extends ConsumerWidget {
  final TryOnProgressState state;
  const _MinimizedBubble({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActive = state.activeTasks.any((t) => t.isActive);
    final hasCompleted = state.activeTasks.any((t) => t.isCompleted);
    final hasFailed = state.activeTasks.any((t) => t.isFailed);

    Color ringColor;
    if (hasFailed && !hasActive) {
      ringColor = const Color(0xFFEF4444);
    } else if (hasCompleted && !hasActive) {
      ringColor = const Color(0xFF10B981);
    } else {
      ringColor = const Color(0xFFF59E0B);
    }

    return GestureDetector(
      onTap: () => ref.read(tryOnProgressProvider.notifier).setMinimized(false),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0F172A),
          border: Border.all(color: ringColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasActive)
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: state.totalProgress / 100,
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                ),
              ),
            Icon(
              hasCompleted && !hasActive
                  ? Icons.check_rounded
                  : hasFailed && !hasActive
                      ? Icons.error_outline_rounded
                      : Icons.auto_awesome_rounded,
              size: 18,
              color: ringColor,
            ),
            if (state.activeTasks.length > 1)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF59E0B),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${state.activeTasks.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedCard extends ConsumerWidget {
  final TryOnProgressState state;
  const _ExpandedCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 260,
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Virtual Try-On',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => ref
                      .read(tryOnProgressProvider.notifier)
                      .setMinimized(true),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.minimize_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: state.activeTasks.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              itemBuilder: (context, index) {
                final task = state.activeTasks[index];
                return _TaskRow(task: task);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  final VirtualTryOnTaskItem task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = task.isCompleted;
    final isFailed = task.isFailed;
    final isActive = task.isActive;
    final progress = isCompleted ? 100 : task.progress.clamp(5, 99);

    return InkWell(
      onTap: () {
        context.push('/virtual-try-ons/${task.id}', extra: task);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isCompleted && task.photoUrl != null && task.photoUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      task.photoUrl!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                  )
                else if (isFailed)
                  const Icon(
                    Icons.error_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  )
                else
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress / 100,
                          strokeWidth: 2.2,
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFF59E0B),
                          ),
                        ),
                        Text(
                          '$progress',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.productName ?? 'Produk #${task.productId ?? '-'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isCompleted
                            ? 'Selesai · Ketuk untuk lihat'
                            : isFailed
                                ? 'Gagal · Ketuk untuk detail'
                                : (task.stepLabel?.isNotEmpty == true
                                    ? task.stepLabel!
                                    : 'Memproses AI... $progress%'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: isCompleted
                              ? const Color(0xFF34D399)
                              : isFailed
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => ref
                      .read(tryOnProgressProvider.notifier)
                      .removeTask(task.id),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
