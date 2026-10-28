import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/notification_providers.dart';
import '../viewmodels/notification_state.dart';
import '../widgets/notification_date_section.dart';
import '../widgets/notification_detail_bottom_sheet.dart';
import '../widgets/notification_skeleton.dart';

/// Halaman Notifikasi Pengguna
/// Menampilkan daftar notifikasi yang dikelompokkan berdasarkan tanggal,
/// badge unread count, aksi mark all as read per seksi, loading skeleton, empty state,
/// pagination infinite scroll, dan pull-to-refresh.
class NotificationView extends ConsumerStatefulWidget {
  const NotificationView({super.key});

  @override
  ConsumerState<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends ConsumerState<NotificationView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Refresh data saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationViewModelProvider.notifier).loadNotifications();
    });

    // Pasang listener untuk pagination (infinite scroll)
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      // Muat halaman berikutnya bila user mendekati 150px dari bawah
      if (currentScroll >= (maxScroll - 150)) {
        ref.read(notificationViewModelProvider.notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. App Bar Header dengan Judul "Notification", Tombol Back, dan Badge Unread (misal: "2 NEW")
            _buildAppBar(context, state.unreadCount),

            // 2. Konten Halaman: Skeleton / Error / Empty / List Notifikasi
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  await ref
                      .read(notificationViewModelProvider.notifier)
                      .loadNotifications(isRefresh: true);
                },
                child: _buildBody(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// App Bar kustom dengan tombol kembali, judul tengah, dan badge NEW di kanan
  Widget _buildAppBar(BuildContext context, int unreadCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Kembali
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/home');
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),

          // Judul Halaman
          Text(
            'Notification',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),

          // Badge Unread Count (misal: "2 NEW")
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7), // Amber 100
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFDE68A), // Amber 200
                  width: 1.0,
                ),
              ),
              child: Text(
                '$unreadCount NEW',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB45309), // Amber 700
                  letterSpacing: 0.2,
                ),
              ),
            )
          else
            const SizedBox(
              width: 42,
              height: 42,
            ),
        ],
      ),
    );
  }

  /// Memilih widget isi sesuai status state
  Widget _buildBody(NotificationState state) {
    if (state.isLoading) {
      return const NotificationSkeleton();
    }

    if (state.isError) {
      return _buildErrorState(state.errorMessage ?? 'Terjadi kesalahan saat memuat notifikasi.');
    }

    if (state.isEmpty) {
      return _buildEmptyState();
    }

    final dateGroups = state.dateGroups;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: dateGroups.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Tampilkan loading spinner di bawah saat fetching halaman baru
        if (index == dateGroups.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          );
        }

        final group = dateGroups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: NotificationDateSection(
            group: group,
            onMarkAllRead: () {
              ref.read(notificationViewModelProvider.notifier).markSectionAsRead(group);
            },
            onItemTap: (notificationItem) {
              // Tandai sebagai dibaca di API & state
              ref
                  .read(notificationViewModelProvider.notifier)
                  .markSingleAsRead(notificationItem.id);

              // Tampilkan bottom sheet detail
              NotificationDetailBottomSheet.show(context, notificationItem);
            },
          ),
        );
      },
    );
  }

  /// Empty State jika tidak ada notifikasi
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 44,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Notifications Yet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are all caught up! We will notify you when there are order updates, vouchers, or promos.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        height: 1.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(notificationViewModelProvider.notifier)
                            .loadNotifications(isRefresh: true);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'Refresh',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Error State jika gagal memuat notifikasi
  Widget _buildErrorState(String message) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF1F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 38,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Failed to Load Notifications',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(notificationViewModelProvider.notifier)
                            .loadNotifications();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'Try Again',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
