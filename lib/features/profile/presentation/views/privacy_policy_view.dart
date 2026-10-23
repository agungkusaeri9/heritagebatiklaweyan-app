import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../store/presentation/viewmodels/store_providers.dart';
import '../../data/models/policy_section_model.dart';
import '../widgets/profile_header.dart';

/// Halaman Kebijakan & Privasi (Privacy Policy)
/// Tampilan simpel, bersih, tanpa card/icon, dengan judul dan poin-poin terstruktur.
class PrivacyPolicyView extends ConsumerStatefulWidget {
  const PrivacyPolicyView({super.key});

  @override
  ConsumerState<PrivacyPolicyView> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends ConsumerState<PrivacyPolicyView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<PolicySectionModel> _policies = [];

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  /// Mengambil data kebijakan dari API setting backend
  Future<void> _loadPolicies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final remoteDataSource = ref.read(storeRemoteDataSourceProvider);
      final storeSetting = await remoteDataSource.getPrivacyPolicy();

      final parsedSections = PolicySectionModel.fromStoreSetting(storeSetting);

      if (!mounted) return;

      setState(() {
        _policies = parsedSections;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Gagal memuat data kebijakan dan privasi. Silakan periksa koneksi internet Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. App Bar Header dengan judul "Privacy Policy" dan tombol Back
            ProfileHeader(
              title: 'Privacy Policy',
              onBackTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/profile');
                }
              },
            ),

            // 2. Konten Kebijakan
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.white,
                onRefresh: _loadPolicies,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_policies.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render setiap bagian kebijakan secara urut, simpel dan clean
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _policies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 28),
            itemBuilder: (context, index) {
              final section = _policies[index];
              return _buildPolicySection(section);
            },
          ),
        ],
      ),
    );
  }

  /// Bagian kebijakan simpel & clean (Judul + Poin-poin)
  Widget _buildPolicySection(PolicySectionModel section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul Bagian Kebijakan
        Text(
          section.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 10),

        // Poin-poin konten terstruktur
        _buildFormattedContent(section.content),
      ],
    );
  }

  /// Render isi konten dengan membedakan paragraf biasa, subjudul bernomor, dan poin daftar
  Widget _buildFormattedContent(String rawContent) {
    final lines = rawContent.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Deteksi Subjudul bernomor (misal: "1. KETENTUAN PEMESANAN", "2. PENGGUNAAN INFORMASI")
      final isNumberedHeader =
          RegExp(r'^\d+[\.\)]\s+[A-Z]').hasMatch(trimmed) ||
          (RegExp(r'^\d+[\.\)]\s+.*:?$').hasMatch(trimmed) && trimmed.length < 60);

      // Deteksi Poin Bullet (misal: "- ...", "• ...", "* ...")
      final isBullet =
          trimmed.startsWith('-') ||
          trimmed.startsWith('•') ||
          trimmed.startsWith('*');

      if (isNumberedHeader) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              trimmed,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
                height: 1.5,
              ),
            ),
          ),
        );
      } else if (isBullet) {
        final bulletText = trimmed.replaceFirst(RegExp(r'^[-•*]\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 10),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF64748B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    bulletText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: const Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              trimmed,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: const Color(0xFF475569),
                height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Tampilan Loading State Simpel (Skeleton tanpa card/border)
  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 28),
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 220,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Tampilan Error State dengan tombol Coba Lagi
  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Gagal Memuat Data',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Terjadi kesalahan saat memuat kebijakan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadPolicies,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Coba Lagi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// Tampilan Empty State jika data kosong
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 32,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Kebijakan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Informasi kebijakan dan privasi toko belum tersedia.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadPolicies,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Muat Ulang',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            ),
          ),
        ],
      ),
    );
  }
}
