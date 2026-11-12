import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/home_dummy_data.dart';
import '../viewmodels/home_providers.dart';

/// Halaman Penuh (Full Screen) untuk Virtual Try-On Produk
/// Menyediakan 3 opsi utama:
/// 1. Pilih Model (Model yang tersedia dari backend)
/// 2. Foto / Galeri (Pilih dari galeri atau ambil foto langsung dari kamera)
/// 3. Model & Product (Contoh hasil Try-On produk yang sudah dibuat di backend)
class ProductVirtualTryOnView extends ConsumerStatefulWidget {
  final ProductItem product;

  const ProductVirtualTryOnView({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductVirtualTryOnView> createState() =>
      _ProductVirtualTryOnViewState();
}

class _ProductVirtualTryOnViewState
    extends ConsumerState<ProductVirtualTryOnView> {
  final ImagePicker _imagePicker = ImagePicker();

  // 0 = Pilih Model, 1 = Foto / Galeri, 2 = Model & Product (Contoh Backend)
  int _activeTab = 0;
  bool get _useGalleryPhoto => _activeTab == 1;

  // State Tab 0: Pilih Model Database
  List<VirtualTryOnModelItem> _models = [];
  bool _isLoadingModels = true;
  String? _modelsError;
  VirtualTryOnModelItem? _selectedDbModel;
  String _selectedModelGenderFilter = 'all'; // all, female, male

  // State Tab 1: Foto Galeri / Kamera Langsung
  String? _selectedGalleryPhotoPath;
  String _selectedGalleryGender = 'female';

  // State Tab 2: Contoh Model & Product dari Backend
  List<VirtualTryOnTaskItem> _defaultTryOns = [];
  bool _isLoadingDefaults = false;
  bool _defaultsLoaded = false;
  String? _defaultsError;

  // State Submit Try-On
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoadingModels = true;
      _modelsError = null;
    });
    try {
      final repo = ref.read(homeRepositoryProvider);
      final list = await repo.getVirtualTryOnModels();
      if (!mounted) return;
      setState(() {
        _models = list;
        if (list.isNotEmpty && _selectedDbModel == null) {
          _selectedDbModel = list.first;
        }
        _isLoadingModels = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingModels = false;
        _modelsError = 'Gagal memuat daftar model dari server.';
      });
    }
  }

  Future<void> _loadDefaultTryOns() async {
    final productId = int.tryParse(widget.product.id) ?? 0;
    if (productId <= 0) return;
    setState(() {
      _isLoadingDefaults = true;
      _defaultsError = null;
    });
    try {
      final repo = ref.read(homeRepositoryProvider);
      final list = await repo.getProductVirtualTryOns(productId);
      if (!mounted) return;
      setState(() {
        _defaultTryOns = list
            .where((e) => e.photoUrl != null || e.videoUrl != null)
            .toList();
        _isLoadingDefaults = false;
        _defaultsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingDefaults = false;
        _defaultsError = 'Gagal memuat contoh Model & Product dari server.';
      });
    }
  }

  void _selectTab(int index) {
    setState(() => _activeTab = index);
    if (index == 2 && !_defaultsLoaded && !_isLoadingDefaults) {
      _loadDefaultTryOns();
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1440,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() {
          _selectedGalleryPhotoPath = file.path;
          _activeTab = 1;
        });
      }
    } catch (_) {
      if (!mounted) return;
      final sourceLabel =
          source == ImageSource.camera ? 'kamera' : 'galeri perangkat';
      AppSnackBar.showError(
        context,
        'Gagal mengambil foto dari $sourceLabel.',
      );
    }
  }

  List<VirtualTryOnModelItem> get _filteredModels {
    if (_selectedModelGenderFilter == 'all') return _models;
    return _models
        .where(
          (m) =>
              m.gender.toLowerCase() == _selectedModelGenderFilter ||
              m.gender.toLowerCase() == 'unisex',
        )
        .toList();
  }

  Future<void> _handleStartTryOn() async {
    if (_isSubmitting) return;

    final productId = int.tryParse(widget.product.id) ?? 0;
    if (productId <= 0) {
      AppSnackBar.showError(context, 'ID produk tidak valid untuk Try-On.');
      return;
    }

    if (_useGalleryPhoto) {
      if (_selectedGalleryPhotoPath == null ||
          _selectedGalleryPhotoPath!.isEmpty) {
        AppSnackBar.showInfo(
          context,
          'Silakan pilih foto dari galeri atau ambil foto langsung terlebih dahulu.',
        );
        return;
      }
    } else {
      if (_selectedDbModel == null) {
        AppSnackBar.showInfo(
          context,
          'Silakan pilih salah satu model terlebih dahulu.',
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(homeRepositoryProvider);
      final task = await repo.createVirtualTryOn(
        productId: productId,
        virtualTryOnModelId: _useGalleryPhoto ? null : _selectedDbModel?.id,
        galleryPhotoPath: _useGalleryPhoto ? _selectedGalleryPhotoPath : null,
        gender: _useGalleryPhoto
            ? _selectedGalleryGender
            : _selectedDbModel?.gender,
      );

      if (!mounted) return;
      context.pop(task);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      final rawMsg = e.toString().replaceFirst('Exception: ', '').trim();
      AppSnackBar.showError(
        context,
        rawMsg.isNotEmpty
            ? rawMsg
            : 'Gagal memulai Virtual Try-On. Silakan coba lagi.',
      );
    }
  }

  void _showPhotoPreviewDialog(String imageUrl, {String? title}) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.78,
                ),
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.65),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            if (title != null && title.isNotEmpty)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: Color(0xFF0F172A),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Virtual Try-On Studio',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Coba tampilan batik secara virtual dengan AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/virtual-try-ons'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.history_rounded, size: 17),
            label: Text(
              'Riwayat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Ringkasan Produk & Tab Navigasi
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                _buildProductSummaryBanner(),
                const SizedBox(height: 14),
                _buildSegmentedTabs(),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 2. Konten Utama Sesuai Tab Aktif
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: _buildActiveTabBody(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProductSummaryBanner() {
    final product = widget.product;
    final thumbUrl = product.allImages.isNotEmpty
        ? product.allImages.first
        : product.imageUrl;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 54,
              height: 54,
              child: (thumbUrl != null && thumbUrl.isNotEmpty)
                  ? Image.network(
                      thumbUrl,
                      cacheWidth: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildProductThumbFallback(),
                    )
                  : _buildProductThumbFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.category.isNotEmpty
                            ? product.category
                            : 'Koleksi Batik',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      product.formattedDiscountedPrice,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductThumbFallback() {
    return Container(
      color: widget.product.placeholderColor,
      child: const Icon(
        Icons.checkroom_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    final defaultCount = _defaultTryOns.length;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildTabButton(
            index: 0,
            icon: Icons.people_alt_rounded,
            label: 'Pilih Model',
          ),
          _buildTabButton(
            index: 1,
            icon: Icons.add_a_photo_rounded,
            label: 'Foto / Galeri',
          ),
          _buildTabButton(
            index: 2,
            icon: Icons.auto_awesome_mosaic_rounded,
            label: 'Model & Product',
            badgeCount: defaultCount > 0 ? defaultCount : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    int? badgeCount,
  }) {
    final bool active = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: active ? Colors.white : const Color(0xFF64748B),
                  ),
                  if (badgeCount != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.22)
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabBody() {
    if (_activeTab == 0) {
      return _buildDatabaseModelsSection();
    } else if (_activeTab == 1) {
      return _buildGalleryAndCameraSection();
    } else {
      return _buildDefaultTryOnsSection();
    }
  }

  /// TAB 0: Pilih Model dari Database
  Widget _buildDatabaseModelsSection() {
    if (_isLoadingModels) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_modelsError != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              _modelsError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadModels,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Muat Ulang Model'),
            ),
          ],
        ),
      );
    }

    if (_models.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 42,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            Text(
              'Belum Ada Model Tersedia',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Silakan gunakan tab Foto / Galeri untuk mengunggah foto dari galeri atau mengambil foto langsung.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _selectTab(1),
              icon: const Icon(Icons.add_a_photo_rounded, size: 16),
              label: const Text('Gunakan Foto Sendiri'),
            ),
          ],
        ),
      );
    }

    final modelsToShow = _filteredModels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + Filter Gender
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Karakter Model AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ketuk salah satu model untuk mencoba produk ini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _buildGenderFilterChip('all', 'Semua'),
                const SizedBox(width: 6),
                _buildGenderFilterChip('female', 'Wanita'),
                const SizedBox(width: 6),
                _buildGenderFilterChip('male', 'Pria'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (modelsToShow.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Tidak ada model untuk filter ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modelsToShow.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final model = modelsToShow[index];
              final isSelected = _selectedDbModel?.id == model.id;

              return GestureDetector(
                onTap: () => setState(() => _selectedDbModel = model),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2.4 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.16)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: isSelected ? 14 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15.5),
                              ),
                              child: (model.photoUrl != null &&
                                      model.photoUrl!.isNotEmpty)
                                  ? Image.network(
                                      model.photoUrl!,
                                      cacheWidth: 420,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        color: const Color(0xFFF1F5F9),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          size: 46,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 46,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                            ),
                            // Gender Badge
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.62),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  model.genderLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // Preview Zoom Button
                            if (model.photoUrl != null &&
                                model.photoUrl!.isNotEmpty)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _showPhotoPreviewDialog(
                                    model.photoUrl!,
                                    title:
                                        '${model.name} (${model.genderLabel})',
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.zoom_in_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            // Selected Indicator
                            if (isSelected)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Dipilih',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Text(
                          model.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        _buildBackgroundProcessNotice(),
      ],
    );
  }

  Widget _buildGenderFilterChip(String value, String label) {
    final active = _selectedModelGenderFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedModelGenderFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  /// TAB 1: Foto dari Galeri atau Ambil Foto Langsung (Kamera)
  Widget _buildGalleryAndCameraSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gunakan Foto Anda Sendiri',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Pilih foto dari galeri perangkat atau ambil foto langsung menggunakan kamera.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),

        if (_selectedGalleryPhotoPath != null) ...[
          // Preview Foto yang Sudah Dipilih / Diambil
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Container(
                        height: 310,
                        width: double.infinity,
                        color: const Color(0xFFF1F5F9),
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 3.0,
                          child: Image.file(
                            File(_selectedGalleryPhotoPath!),
                            cacheWidth: 720,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Foto Siap Digunakan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedGalleryPhotoPath = null;
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          foregroundColor: Colors.white,
                        ),
                        tooltip: 'Hapus Foto',
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickPhoto(ImageSource.gallery),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.photo_library_rounded,
                            size: 17,
                          ),
                          label: Text(
                            'Ganti dari Galeri',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickPhoto(ImageSource.camera),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.camera_alt_rounded,
                            size: 17,
                          ),
                          label: Text(
                            'Foto Langsung',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Kartu Pilihan Ambil dari Galeri atau Kamera Langsung
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                width: 1.4,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_a_photo_rounded,
                    size: 34,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unggah atau Ambil Foto Anda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gunakan foto berdiri menghadap depan dengan pencahayaan yang jelas (Maks. 5MB)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.photo_library_rounded,
                          size: 18,
                        ),
                        label: Text(
                          'Pilih Galeri',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.05),
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.4,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.camera_alt_rounded,
                          size: 18,
                        ),
                        label: Text(
                          'Foto Langsung',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Pemilih Gender untuk Foto Galeri / Kamera
        Container(
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
                'Kategori Fitting Model',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'membantu AI menyesuaikan potongan busana batik pada foto Anda',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildGalleryGenderOption(
                      value: 'female',
                      label: 'Wanita',
                      icon: Icons.woman_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGalleryGenderOption(
                      value: 'male',
                      label: 'Pria',
                      icon: Icons.man_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Panduan Singkat Foto
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_rounded,
                    size: 17,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Tips Hasil Try-On Maksimal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTipItem(
                'Pastikan tubuh terlihat dari atas hingga pinggang/lutut dan menghadap ke depan.',
              ),
              const SizedBox(height: 4),
              _buildTipItem(
                'Gunakan pencahayaan yang terang dan latar belakang yang tidak terlalu ramai.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _buildBackgroundProcessNotice(),
      ],
    );
  }

  Widget _buildGalleryGenderOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _selectedGalleryGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGalleryGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 14,
            color: Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// TAB 2: Contoh "Model & Product" yang sudah dibuat di Backend
  Widget _buildDefaultTryOnsSection() {
    if (_isLoadingDefaults || (!_defaultsLoaded && _defaultsError == null)) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_defaultsError != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              _defaultsError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadDefaultTryOns,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    if (_defaultTryOns.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_mosaic_rounded,
                size: 34,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum Ada Contoh Model & Product',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Contoh hasil perpaduan model & produk dari sistem belum tersedia untuk produk ini. Anda dapat langsung mencoba menggunakan tab Pilih Model atau Foto / Galeri.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _selectTab(0),
                  icon: const Icon(Icons.people_alt_rounded, size: 16),
                  label: const Text('Pilih Model'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _selectTab(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                  label: const Text('Foto Sendiri'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contoh Hasil Model & Product',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Referensi hasil Virtual Try-On produk ini pada model yang telah disiapkan di sistem.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),
        ..._defaultTryOns.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _DefaultTryOnMediaCard(
              item: item,
              onZoomTap: (item.photoUrl != null && item.photoUrl!.isNotEmpty)
                  ? () => _showPhotoPreviewDialog(
                        item.photoUrl!,
                        title: item.modelName ?? 'Contoh Model & Product',
                      )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundProcessNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Proses generasi foto Try-On berjalan otomatis di background. Anda dapat tetap menjelajahi produk sementara indikator progress tampil di pojok kanan bawah.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF92400E),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      child: _activeTab == 2
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTab(0),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.4,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.people_alt_rounded, size: 18),
                    label: Text(
                      'Coba Pilih Model',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectTab(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                    label: Text(
                      'Pakai Foto Sendiri',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('product_detail_confirm_try_on_button'),
                onPressed: _isSubmitting ? null : _handleStartTryOn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                  _isSubmitting
                      ? 'Memulai Proses...'
                      : _useGalleryPhoto
                          ? 'Mulai Try On dengan Foto Saya'
                          : 'Mulai Try On Sekarang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }
}

/// Kartu hasil try-on default (Model & Product) dengan toggle Foto / Video & Zoom
class _DefaultTryOnMediaCard extends StatefulWidget {
  final VirtualTryOnTaskItem item;
  final VoidCallback? onZoomTap;

  const _DefaultTryOnMediaCard({
    required this.item,
    this.onZoomTap,
  });

  @override
  State<_DefaultTryOnMediaCard> createState() => _DefaultTryOnMediaCardState();
}

class _DefaultTryOnMediaCardState extends State<_DefaultTryOnMediaCard> {
  bool _showVideo = false;
  VideoPlayerController? _videoController;
  bool _videoError = false;

  bool get _hasPhoto =>
      widget.item.photoUrl != null && widget.item.photoUrl!.isNotEmpty;
  bool get _hasVideo =>
      widget.item.videoUrl != null && widget.item.videoUrl!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasPhoto && _hasVideo) {
      _showVideo = true;
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    if (_videoController != null || !_hasVideo) return;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.item.videoUrl!),
    );
    _videoController = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _videoError = true);
    }
  }

  void _toggle(bool video) {
    setState(() => _showVideo = video);
    if (video) {
      _initVideo();
      _videoController?.play();
    } else {
      _videoController?.pause();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Widget _placeholder(IconData icon) => Container(
        color: const Color(0xFFF1F5F9),
        child: Center(
          child: Icon(icon, size: 42, color: const Color(0xFF94A3B8)),
        ),
      );

  Widget _buildMedia() {
    if (_showVideo) {
      final c = _videoController;
      if (_videoError) return _placeholder(Icons.videocam_off_rounded);
      if (c == null || !c.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      }
      return GestureDetector(
        onTap: () {
          setState(() {
            c.value.isPlaying ? c.pause() : c.play();
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            ),
            if (!c.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
          ],
        ),
      );
    }

    if (!_hasPhoto) return _placeholder(Icons.image_not_supported_outlined);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          widget.item.photoUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
          errorBuilder: (_, _, _) =>
              _placeholder(Icons.broken_image_rounded),
        ),
        if (widget.onZoomTap != null)
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: widget.onZoomTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.zoom_out_map_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Perbesar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final genderLabel = item.gender == 'male'
        ? 'Pria'
        : item.gender == 'female'
            ? 'Wanita'
            : 'Unisex';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 360,
            color: const Color(0xFFF8FAFC),
            child: _buildMedia(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.modelName ?? 'Contoh Model & Product',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Kategori: $genderLabel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasPhoto)
                  _chip(
                    'Foto',
                    Icons.photo_rounded,
                    !_showVideo,
                    () => _toggle(false),
                  ),
                if (_hasPhoto && _hasVideo) const SizedBox(width: 6),
                if (_hasVideo)
                  _chip(
                    'Video',
                    Icons.videocam_rounded,
                    _showVideo,
                    () => _toggle(true),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
