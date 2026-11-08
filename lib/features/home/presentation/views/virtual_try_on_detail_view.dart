import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/home_dummy_data.dart';
import '../viewmodels/home_providers.dart';

/// Halaman Detail Hasil Virtual Try-On
/// Memenuhi spesifikasi: Ketika di-back, navigasi berpindah ke daftar riwayat Try-On (/virtual-try-ons).
class VirtualTryOnDetailView extends ConsumerStatefulWidget {
  final int tryOnId;
  final VirtualTryOnTaskItem? initialTask;

  const VirtualTryOnDetailView({
    super.key,
    required this.tryOnId,
    this.initialTask,
  });

  @override
  ConsumerState<VirtualTryOnDetailView> createState() =>
      _VirtualTryOnDetailViewState();
}

class _VirtualTryOnDetailViewState
    extends ConsumerState<VirtualTryOnDetailView> {
  VirtualTryOnTaskItem? _task;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;
  bool _isRetrying = false;
  int _activeMediaTab = 0; // 0 = Foto AI, 1 = Video AI

  VideoPlayerController? _videoController;
  String? _initializedVideoUrl;
  bool _isVideoInitializing = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    _task = widget.initialTask;
    _fetchDetail(showLoading: _task == null);
  }

  @override
  void dispose() {
    _stopPolling();
    _disposeVideoController();
    super.dispose();
  }

  void _disposeVideoController() {
    final old = _videoController;
    _videoController = null;
    _initializedVideoUrl = null;
    old?.dispose();
  }

  Future<void> _ensureVideoInitialized(
    String videoUrl, {
    bool forceReload = false,
  }) async {
    if (videoUrl.isEmpty) return;

    if (!forceReload &&
        _initializedVideoUrl == videoUrl &&
        _videoController != null &&
        !_hasVideoError) {
      if (_videoController!.value.isInitialized &&
          !_videoController!.value.isPlaying) {
        await _videoController!.play();
      }
      return;
    }

    _disposeVideoController();
    _initializedVideoUrl = videoUrl;
    if (mounted) {
      setState(() {
        _isVideoInitializing = true;
        _hasVideoError = false;
      });
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoController = controller;

    try {
      await controller.initialize();
      if (!mounted || _videoController != controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.play();
      if (mounted) {
        setState(() {
          _isVideoInitializing = false;
        });
      }
    } catch (_) {
      if (mounted && _videoController == controller) {
        setState(() {
          _isVideoInitializing = false;
          _hasVideoError = true;
        });
      }
    }
  }

  void _selectMediaTab(int tabIndex) {
    if (_activeMediaTab == tabIndex) return;
    setState(() {
      _activeMediaTab = tabIndex;
    });
    if (tabIndex == 1) {
      final url = _task?.videoUrl;
      if (url != null && url.isNotEmpty) {
        _ensureVideoInitialized(url);
      }
    } else {
      _videoController?.pause();
    }
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollProgress();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchDetail({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final repo = ref.read(homeRepositoryProvider);
      final detail = await repo.getVirtualTryOnDetail(widget.tryOnId);
      if (!mounted) return;
      setState(() {
        _task = detail;
        _isLoading = false;
      });

      if (_activeMediaTab == 1 &&
          detail.videoUrl != null &&
          detail.videoUrl!.isNotEmpty) {
        _ensureVideoInitialized(detail.videoUrl!);
      }

      if (detail.isActive) {
        _startPolling();
      } else {
        _stopPolling();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pollProgress() async {
    if (!mounted) return;
    try {
      final repo = ref.read(homeRepositoryProvider);
      final updated = await repo.getVirtualTryOnProgress(widget.tryOnId);
      if (!mounted) return;
      setState(() {
        if (_task != null) {
          _task = VirtualTryOnTaskItem(
            id: _task!.id,
            productId: _task!.productId ?? updated.productId,
            productName: _task!.productName ?? updated.productName,
            productPrice: _task!.productPrice ?? updated.productPrice,
            productSku: _task!.productSku ?? updated.productSku,
            productImageUrl: _task!.productImageUrl ?? updated.productImageUrl,
            virtualTryOnModelId:
                _task!.virtualTryOnModelId ?? updated.virtualTryOnModelId,
            modelName: _task!.modelName ?? updated.modelName,
            modelPhotoUrl: _task!.modelPhotoUrl ?? updated.modelPhotoUrl,
            gender: _task!.gender ?? updated.gender,
            status: updated.status,
            progress: updated.progress,
            stepLabel: updated.stepLabel ?? _task!.stepLabel,
            photoUrl: updated.photoUrl ?? _task!.photoUrl,
            videoUrl: updated.videoUrl ?? _task!.videoUrl,
            generateVideo: updated.generateVideo,
            errorMessage: updated.errorMessage ?? _task!.errorMessage,
            createdAt: _task!.createdAt,
          );
        } else {
          _task = updated;
        }
      });

      if (updated.isCompleted || updated.isFailed) {
        _stopPolling();
        // Ambil detail lengkap jika baru saja selesai
        _fetchDetail(showLoading: false);
      }
    } catch (_) {
      // Ignored during polling
    }
  }

  Future<void> _handleRetry() async {
    if (_task == null) return;
    setState(() {
      _isRetrying = true;
    });

    try {
      final repo = ref.read(homeRepositoryProvider);
      final retried = await repo.retryVirtualTryOn(_task!.id);
      if (!mounted) return;
      setState(() {
        _task = retried;
      });
      AppSnackBar.showSuccess(
        context,
        'Mencoba ulang proses Virtual Try-On...',
      );
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'Gagal mencoba ulang: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  /// Sesuai instruksi: Ketika di-back, navigasi berpindah ke daftar riwayat Try-On
  void _navigateBackToList() {
    _stopPolling();
    _videoController?.pause();
    context.go('/virtual-try-ons');
  }

  String _formatPrice(double? price) {
    if (price == null) return '-';
    final parts = price.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    int count = 0;
    for (int i = parts.length - 1; i >= 0; i--) {
      buffer.write(parts[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateBackToList();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF0F172A),
            ),
            onPressed: _navigateBackToList,
          ),
          title: Text(
            'Detail Virtual Try-On',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.list_alt_rounded,
                color: Color(0xFF0F172A),
              ),
              tooltip: 'Daftar Try-On',
              onPressed: _navigateBackToList,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: const Color(0xFFE2E8F0),
              height: 1,
            ),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null && _task == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal Memuat Detail',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _fetchDetail(showLoading: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final task = _task!;
    final bool hasVideo = task.videoUrl != null && task.videoUrl!.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Status (jika sedang memproses atau gagal)
          if (task.isActive) _buildProcessingCard(task),
          if (task.isFailed) _buildFailedCard(task),

          if (task.isActive || task.isFailed) const SizedBox(height: 16),

          // Tab Switcher Media (Foto AI vs Video AI jika video tersedia atau diminta)
          if (hasVideo) ...[
            _buildMediaTabSwitcher(),
            const SizedBox(height: 12),
          ],

          // Preview Media Utama (Foto atau Video)
          if (!hasVideo || _activeMediaTab == 0)
            _buildPhotoPreviewCard(task)
          else
            _buildVideoPreviewCard(task),

          const SizedBox(height: 16),

          // Info Kartu Produk
          _buildProductCard(task),

          const SizedBox(height: 16),

          // Info Model Avatar
          _buildModelInfoCard(task),

          const SizedBox(height: 16),

          // Detail Teknis Generasi
          _buildTechnicalInfoCard(task),
        ],
      ),
    );
  }

  Widget _buildMediaTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectMediaTab(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeMediaTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _activeMediaTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_rounded,
                      size: 16,
                      color: _activeMediaTab == 0
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Foto Hasil AI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _activeMediaTab == 0
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectMediaTab(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeMediaTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _activeMediaTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      size: 16,
                      color: _activeMediaTab == 1
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Video AI Simulasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _activeMediaTab == 1
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingCard(VirtualTryOnTaskItem task) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFFD97706)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sedang Memproses Try-On (${task.progress}%)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.stepLabel ?? 'Memproses di antrean latar belakang...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFFB45309),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: task.progress / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFFDE68A),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFD97706)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedCard(VirtualTryOnTaskItem task) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proses Try-On Gagal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.errorMessage ??
                      task.stepLabel ??
                      'Terjadi kendala saat menghasilkan gambar dengan AI.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _handleRetry,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(_isRetrying ? 'Mencoba...' : 'Coba Ulang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreviewCard(VirtualTryOnTaskItem task) {
    final photoUrl = task.photoUrl ?? task.productImageUrl;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 380,
                width: double.infinity,
                color: const Color(0xFF0F172A),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? InteractiveViewer(
                        panEnabled: true,
                        minScale: 1.0,
                        maxScale: 3.0,
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 48,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 54,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.zoom_in_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cubit / Zoom Foto',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dihasilkan menggunakan AI Model Batik Laweyan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreviewCard(VirtualTryOnTaskItem task) {
    final videoUrl = task.videoUrl;
    final controller = _videoController;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 380,
            width: double.infinity,
            color: const Color(0xFF0F172A),
            child: _buildVideoViewport(task, videoUrl, controller),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.videocam_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Video simulasi gerakan model AI Batik Laweyan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoViewport(
    VirtualTryOnTaskItem task,
    String? videoUrl,
    VideoPlayerController? controller,
  ) {
    if (videoUrl == null || videoUrl.isEmpty) {
      return const Center(
        child: Icon(
          Icons.videocam_off_rounded,
          size: 48,
          color: Color(0xFF64748B),
        ),
      );
    }

    if (_hasVideoError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                size: 46,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 10),
              Text(
                'Gagal memuat video simulasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    _ensureVideoInitialized(videoUrl, forceReload: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Muat Ulang Video'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isVideoInitializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (task.photoUrl != null && task.photoUrl!.isNotEmpty)
            Opacity(
              opacity: 0.35,
              child: Image.network(
                task.photoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Memuat video...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final isPlaying = value.isPlaying;
        final isMuted = value.volume == 0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            isPlaying ? controller.pause() : controller.play();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio:
                      value.aspectRatio > 0 ? value.aspectRatio : (9 / 16),
                  child: VideoPlayer(controller),
                ),
              ),
              if (!isPlaying)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          colors: const VideoProgressColors(
                            playedColor: AppColors.primary,
                            bufferedColor: Colors.white38,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              isPlaying
                                  ? controller.pause()
                                  : controller.play();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              controller.setVolume(isMuted ? 1.0 : 0.0);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(VirtualTryOnTaskItem task) {
    final hasProduct = task.productId != null && task.productId! > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produk Batik Terkait',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 58,
                  height: 58,
                  color: const Color(0xFFF1F5F9),
                  child: task.productImageUrl != null &&
                          task.productImageUrl!.isNotEmpty
                      ? Image.network(
                          task.productImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF94A3B8),
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF94A3B8),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.productName ?? 'Produk #${task.productId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatPrice(task.productPrice),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if (task.productSku != null && task.productSku!.isNotEmpty)
                      Text(
                        'SKU: ${task.productSku}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (hasProduct) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                onPressed: () {
                  _videoController?.pause();
                  context.push('/products/${task.productId}');
                },
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Lihat Detail Produk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModelInfoCard(VirtualTryOnTaskItem task) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 50,
              height: 50,
              color: const Color(0xFFF1F5F9),
              child: task.modelPhotoUrl != null &&
                      task.modelPhotoUrl!.isNotEmpty
                  ? Image.network(
                      task.modelPhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    )
                  : const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF94A3B8),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Model Virtual yang Digunakan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.modelName ?? 'Model Pilihan Pengguna',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.gender == 'male' ? 'Laki-laki (Pria)' : 'Perempuan (Wanita)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalInfoCard(VirtualTryOnTaskItem task) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Generasi AI',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow('ID Tugas', '#${task.id}'),
          _buildInfoRow(
            'Status',
            task.isCompleted
                ? 'Selesai (100%)'
                : task.isFailed
                    ? 'Gagal'
                    : 'Memproses (${task.progress}%)',
          ),
          _buildInfoRow(
            'Generasi Video',
            task.generateVideo ? 'Ya (Foto + Video AI)' : 'Hanya Foto',
          ),
          if (task.videoUrl != null && task.videoUrl!.isNotEmpty)
            _buildInfoRow('Status Video', 'Tersedia & Siap Diputar'),
          if (task.createdAt != null)
            _buildInfoRow(
              'Waktu Dibuat',
              task.createdAt!.toLocal().toString().split('.').first,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

