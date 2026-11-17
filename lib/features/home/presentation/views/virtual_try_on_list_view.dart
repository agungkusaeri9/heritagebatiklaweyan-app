import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../profile/presentation/widgets/profile_header.dart';
import '../../data/models/home_dummy_data.dart';
import '../viewmodels/home_providers.dart';

/// Halaman Riwayat & Koleksi Virtual Try-On Pengguna
class VirtualTryOnListView extends ConsumerStatefulWidget {
  final VoidCallback? onBackTap;
  final bool embedded;
  final int refreshTrigger;

  const VirtualTryOnListView({
    super.key,
    this.onBackTap,
    this.embedded = false,
    this.refreshTrigger = 0,
  });

  @override
  ConsumerState<VirtualTryOnListView> createState() =>
      _VirtualTryOnListViewState();
}

class _VirtualTryOnListViewState extends ConsumerState<VirtualTryOnListView> {
  List<VirtualTryOnTaskItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _retryingId;

  @override
  void initState() {
    super.initState();
    _loadTryOns();
  }

  @override
  void didUpdateWidget(covariant VirtualTryOnListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _loadTryOns();
    }
  }

  Future<void> _loadTryOns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(homeRepositoryProvider);
      final list = await repo.getUserVirtualTryOns();
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleRetry(VirtualTryOnTaskItem item) async {
    setState(() {
      _retryingId = item.id;
    });

    try {
      final repo = ref.read(homeRepositoryProvider);
      final retried = await repo.retryVirtualTryOn(item.id);
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        'Mencoba ulang generasi Try-On #${retried.id}...',
      );
      _loadTryOns();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'Gagal mencoba ulang: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _retryingId = null;
        });
      }
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final local = dt.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = local.day;
    final month = months[local.month - 1];
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        ProfileHeader(
          title: 'Virtual Try-On Batik',
          onBackTap: widget.onBackTap ??
              () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTryOns,
            color: AppColors.primary,
            child: _buildBody(),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: const Color(0xFFF8FAFC), child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: content,
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

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 54,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gagal Memuat Riwayat',
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
                  onPressed: _loadTryOns,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF704F38).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum Ada Riwayat Try-On',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anda belum pernah mencoba fitur Virtual Try-On.\nPilih busana batik favorit Anda dan coba kenakan dengan teknologi AI!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: widget.onBackTap ?? () => context.go('/home'),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Jelajahi Produk Batik'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildTryOnCard(item);
      },
    );
  }

  Widget _buildTryOnCard(VirtualTryOnTaskItem item) {
    final bool isCompleted = item.isCompleted;
    final bool isFailed = item.isFailed;
    final bool isProcessing = item.isActive;
    final bool hasVideo = item.videoUrl != null && item.videoUrl!.isNotEmpty;

    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;
    IconData statusIcon;

    if (isCompleted) {
      statusBgColor = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF166534);
      statusLabel = 'Selesai';
      statusIcon = Icons.check_circle_rounded;
    } else if (isFailed) {
      statusBgColor = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFF991B1B);
      statusLabel = 'Gagal';
      statusIcon = Icons.error_rounded;
    } else {
      statusBgColor = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFF92400E);
      statusLabel = 'Memproses ${item.progress}%';
      statusIcon = Icons.sync_rounded;
    }

    final displayImageUrl = item.photoUrl ?? item.productImageUrl ?? item.modelPhotoUrl;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () {
          context.push('/virtual-try-ons/${item.id}', extra: item);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Preview / Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 84,
                      height: 104,
                      color: const Color(0xFFF1F5F9),
                      child: displayImageUrl != null && displayImageUrl.isNotEmpty
                          ? Image.network(
                              displayImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported_outlined,
                                color: Color(0xFF94A3B8),
                                size: 28,
                              ),
                            )
                          : const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                    ),
                  ),
                  if (hasVideo)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.videocam_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Detail Produk & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                size: 12,
                                color: statusTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: statusTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (hasVideo)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_circle_filled_rounded,
                                  size: 12,
                                  color: Color(0xFF4F46E5),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Video AI',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF4F46E5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Nama Produk
                    Text(
                      item.productName ?? 'Produk Batik #${item.productId ?? '-'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Info Model
                    if (item.modelName != null && item.modelName!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 13,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${item.modelName} (${item.gender == 'male' ? 'Pria' : 'Wanita'})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),

                    // Tanggal Pembuatan
                    Text(
                      _formatDateTime(item.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (isProcessing) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item.progress.clamp(5, 100)) / 100,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFF59E0B),
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],

                    if (isFailed) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 28,
                            child: OutlinedButton.icon(
                              onPressed: _retryingId == item.id
                                  ? null
                                  : () => _handleRetry(item),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFEF4444),
                                  width: 1,
                                ),
                                foregroundColor: const Color(0xFFEF4444),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: _retryingId == item.id
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Color(0xFFEF4444),
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh_rounded,
                                      size: 13,
                                    ),
                              label: Text(
                                _retryingId == item.id
                                    ? 'Mencoba...'
                                    : 'Coba Ulang',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

