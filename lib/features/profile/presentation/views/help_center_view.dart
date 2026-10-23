import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../store/data/models/faq_model.dart';
import '../../../store/data/models/store_setting_model.dart';
import '../../../store/presentation/viewmodels/store_providers.dart';
import '../widgets/profile_header.dart';

/// Model item kontak untuk tab Contact Us
class ContactChannelItem {
  final String id;
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String copyLabel;
  final bool isLink;

  const ContactChannelItem({
    required this.id,
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.copyLabel,
    this.isLink = false,
    this.iconColor = const Color(0xFF334155),
    this.iconBgColor = const Color(0xFFF8FAFC),
  });
}

/// Halaman Help Center pada Menu Account (Profile)
class HelpCenterView extends ConsumerStatefulWidget {
  const HelpCenterView({super.key});

  @override
  ConsumerState<HelpCenterView> createState() => _HelpCenterViewState();
}

class _HelpCenterViewState extends ConsumerState<HelpCenterView> {
  // Tab index: 0 = FAQ, 1 = Contact Us
  int _currentTabIndex = 0;

  // Search state (terletak di atas tabs)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // FAQ state
  String _selectedCategory = 'All';
  final Set<int> _expandedFaqIds = {};
  List<FaqModel> _faqs = [];
  List<String> _categories = ['All', 'Services', 'General', 'Account'];
  bool _isLoading = true;
  String? _errorMessage;

  // Contact Us state (Accordion - semua tertutup secara default)
  final Set<String> _expandedContactIds = {};
  StoreSettingModel? _storeSetting;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Mengambil data FAQ dan Store Setting dari backend API
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final remoteDataSource = ref.read(storeRemoteDataSourceProvider);

      // Request data secara paralel dari endpoint yang sudah ada
      final results = await Future.wait([
        remoteDataSource.getFaqs(),
        remoteDataSource.getFaqCategories(),
        remoteDataSource.getStoreSetting(),
      ]);

      final fetchedFaqs = results[0] as List<FaqModel>;
      final fetchedCategories = results[1] as List<String>;
      final fetchedStore = results[2] as StoreSettingModel;

      // Bangun daftar kategori dinamis:
      // Diawali dengan 'All', 'Services', 'General', 'Account',
      // lalu ditambahkan kategori unik lainnya dari response API
      final uniqueCategories = <String>['All', 'Services', 'General', 'Account'];

      for (final cat in fetchedCategories) {
        if (!uniqueCategories.any((c) => c.toLowerCase() == cat.toLowerCase())) {
          uniqueCategories.add(cat);
        }
      }

      for (final faq in fetchedFaqs) {
        if (faq.category.isNotEmpty &&
            !uniqueCategories.any((c) => c.toLowerCase() == faq.category.toLowerCase())) {
          uniqueCategories.add(faq.category);
        }
      }

      if (!mounted) return;

      setState(() {
        _faqs = fetchedFaqs;
        _categories = uniqueCategories;
        _storeSetting = fetchedStore;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data Help Center. Periksa jaringan Anda.';
      });
    }
  }

  /// Daftar saluran kontak untuk tab Contact Us
  List<ContactChannelItem> get _contactChannels {
    final store = _storeSetting;

    final phone = (store?.phone != null && store!.phone!.trim().isNotEmpty)
        ? store.phone!.trim()
        : '0812-3456-7890';

    final whatsapp = (store?.whatsapp != null && store!.whatsapp!.trim().isNotEmpty)
        ? store.whatsapp!.trim()
        : '+62 812-3456-7890';

    final website = (store?.website != null && store!.website!.trim().isNotEmpty)
        ? store.website!.trim()
        : 'https://heritagebatiklaweyan.com';

    final facebook = (store?.facebookUrl != null && store!.facebookUrl!.trim().isNotEmpty)
        ? store.facebookUrl!.trim()
        : 'https://facebook.com/heritagebatiklaweyan';

    final twitter = (store?.twitterUrl != null && store!.twitterUrl!.trim().isNotEmpty)
        ? store.twitterUrl!.trim()
        : '@heritagebatik';

    final instagram = (store?.instagramUrl != null && store!.instagramUrl!.trim().isNotEmpty)
        ? store.instagramUrl!.trim()
        : '@heritagebatiklaweyan';

    return [
      ContactChannelItem(
        id: 'customer_service',
        title: 'Customer Service',
        value: phone,
        description:
            'Layanan panggilan telepon resmi. Siap melayani konsultasi pemesanan dan bantuan teknis pada hari kerja Senin - Sabtu (08.00 - 17.00 WIB).',
        icon: Icons.headset_mic_rounded,
        copyLabel: 'Nomor Customer Service',
        isLink: false,
      ),
      ContactChannelItem(
        id: 'whatsapp',
        title: 'WhatsApp',
        value: whatsapp,
        description:
            'Respon cepat via chat WhatsApp untuk informasi ketersediaan motif, pemesanan seragam batik custom, dan konfirmasi pesanan.',
        icon: Icons.chat_bubble_outline_rounded,
        copyLabel: 'Nomor WhatsApp',
        isLink: true,
      ),
      ContactChannelItem(
        id: 'website',
        title: 'Website',
        value: website,
        description:
            'Kunjungi portal resmi Heritage Batik Laweyan untuk melihat katalog busana batik autentik, ulasan pelanggan, dan artikel budaya batik.',
        icon: Icons.language_rounded,
        copyLabel: 'Tautan Website',
        isLink: true,
      ),
      ContactChannelItem(
        id: 'facebook',
        title: 'Facebook',
        value: facebook,
        description:
            'Ikuti halaman Facebook resmi kami untuk mendapatkan berita pameran batik, liputan acara budaya, dan promo eksklusif komunitas.',
        icon: Icons.facebook_rounded,
        copyLabel: 'Tautan Facebook',
        isLink: true,
      ),
      ContactChannelItem(
        id: 'twitter',
        title: 'Twitter',
        value: twitter,
        description:
            'Dapatkan informasi cepat seputar promo akhir pekan, cuitan kilat, dan pengumuman terbaru melalui akun Twitter/X resmi kami.',
        icon: Icons.alternate_email_rounded,
        copyLabel: 'Username Twitter',
        isLink: true,
      ),
      ContactChannelItem(
        id: 'instagram',
        title: 'Instagram',
        value: instagram,
        description:
            'Lihat inspirasi padu padan OOTD busana batik nusantara, katalog koleksi motif terbaru, serta video proses pembuatan batik cap & tulis.',
        icon: Icons.camera_alt_outlined,
        copyLabel: 'Akun Instagram',
        isLink: true,
      ),
    ];
  }

  /// Filter FAQ berdasarkan keyword dan kategori
  List<FaqModel> get _filteredFaqs {
    return _faqs.where((faq) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          faq.title.toLowerCase().contains(query) ||
          faq.description.toLowerCase().contains(query);

      final cat = _selectedCategory.toLowerCase();
      bool matchesCategory = false;

      if (cat == 'all') {
        matchesCategory = true;
      } else if (cat == 'services') {
        matchesCategory = faq.category.toLowerCase().contains('service') ||
            faq.category.toLowerCase().contains('pesan') ||
            faq.category.toLowerCase().contains('layanan');
      } else if (cat == 'general') {
        matchesCategory = faq.category.toLowerCase().contains('general') ||
            faq.category.toLowerCase().contains('umum') ||
            faq.category.toLowerCase().contains('produk');
      } else if (cat == 'account') {
        matchesCategory = faq.category.toLowerCase().contains('account') ||
            faq.category.toLowerCase().contains('akun') ||
            faq.category.toLowerCase().contains('profil');
      } else {
        matchesCategory = faq.category.toLowerCase() == cat;
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  /// Filter saluran kontak berdasarkan search bar
  List<ContactChannelItem> get _filteredContacts {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return _contactChannels;

    return _contactChannels.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.value.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  static const _launcherChannel = MethodChannel('com.heritagebatik.app/launcher');

  /// Salin teks ke papan klip dengan SnackBar
  void _copyToClipboard(String text, String label) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text.trim()));
    AppSnackBar.showSuccess(context, '$label berhasil disalin ke papan klip.');
  }

  /// Membuka tautan eksternal untuk Website dan Media Sosial (Kunjungi)
  /// Mengarahkan Facebook ke aplikasi Facebook, Twitter ke Twitter/X, Instagram ke Instagram, dan Web ke Browser
  Future<void> _openContactLink(ContactChannelItem item) async {
    String url = item.value.trim();

    // Normalisasi nomor WhatsApp atau username/domain media sosial menjadi URL lengkap
    if (item.id == 'whatsapp') {
      var cleanNumber = url.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanNumber.startsWith('0')) {
        cleanNumber = '62${cleanNumber.substring(1)}';
      }
      url = 'https://wa.me/$cleanNumber';
    } else if (url.startsWith('@')) {
      final username = url.substring(1);
      if (item.id == 'instagram') {
        url = 'https://instagram.com/$username';
      } else if (item.id == 'twitter') {
        url = 'https://x.com/$username';
      } else {
        url = 'https://$username';
      }
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (item.id == 'instagram') {
        url = 'https://instagram.com/$url';
      } else if (item.id == 'twitter') {
        url = 'https://x.com/$url';
      } else {
        url = 'https://$url';
      }
    }

    bool opened = false;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final res = await _launcherChannel.invokeMethod<bool>('openUrl', {
          'url': url,
          'type': item.id,
        });
        opened = res ?? false;
      } else if (!kIsWeb && Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
        opened = true;
      } else if (!kIsWeb && Platform.isMacOS) {
        await Process.run('open', [url]);
        opened = true;
      } else if (!kIsWeb && Platform.isLinux) {
        await Process.run('xdg-open', [url]);
        opened = true;
      }
    } catch (_) {
      opened = false;
    }

    if (!mounted) return;

    if (!opened) {
      AppSnackBar.showError(context, 'Tidak dapat membuka ${item.title}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Kembali & Judul Help Center)
            ProfileHeader(
              title: 'Help Center',
              onBackTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/profile');
                }
              },
            ),

            // 2. Search Bar (Terletak di ATAS tab FAQ & Contact Us)
            _buildSearchBar(),

            // 3. Tab Selector (FAQ & Contact Us) dengan Indikator Aktif
            _buildTabSelector(),

            const SizedBox(height: 8),

            // 4. Content (FAQ atau Contact Us)
            Expanded(
              child: _currentTabIndex == 0 ? _buildFaqTab() : _buildContactUsTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. SEARCH BAR (DI ATAS TAB)
  // ==========================================

  Widget _buildSearchBar() {
    final hint = _currentTabIndex == 0
        ? 'Search FAQ, questions...'
        : 'Search contacts, social media...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 2. TAB SELECTOR DENGAN INDIKATOR AKTIF
  // ==========================================

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTabItem(index: 0, label: 'FAQ'),
          _buildTabItem(index: 1, label: 'Contact Us'),
        ],
      ),
    );
  }

  Widget _buildTabItem({required int index, required String label}) {
    final isSelected = _currentTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentTabIndex != index) {
            setState(() {
              _currentTabIndex = index;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. TAB 1: FAQ CONTENT
  // ==========================================

  Widget _buildFaqTab() {
    return Column(
      children: [
        // Horizontal Category Chips
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 6),

        // List FAQ dengan Accordion
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: _buildFaqListOrState(),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqListOrState() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!, _loadData);
    }

    final faqs = _filteredFaqs;

    if (faqs.isEmpty) {
      return _buildEmptyState(
        title: 'Tidak ada FAQ ditemukan',
        subtitle: 'Coba ubah kata kunci pencarian atau pilih kategori lain.',
        onReset: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
            _selectedCategory = 'All';
          });
        },
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        final isExpanded = _expandedFaqIds.contains(faq.id);

        return _buildFaqAccordionCard(
          faq: faq,
          isExpanded: isExpanded,
          onToggle: () {
            setState(() {
              if (isExpanded) {
                _expandedFaqIds.remove(faq.id);
              } else {
                _expandedFaqIds.add(faq.id);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildFaqAccordionCard({
    required FaqModel faq,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        faq.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isExpanded
                              ? AppColors.primary
                              : const Color(0xFF0F172A),
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: isExpanded
                              ? AppColors.primary
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFF1F5F9),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  faq.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: const Color(0xFF64748B),
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 4. TAB 2: CONTACT US CONTENT (ACCORDION)
  // ==========================================

  Widget _buildContactUsTab() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!, _loadData);
    }

    final contacts = _filteredContacts;

    if (contacts.isEmpty) {
      return _buildEmptyState(
        title: 'Kontak tidak ditemukan',
        subtitle: 'Tidak ada saluran kontak yang sesuai dengan kata kunci pencarian Anda.',
        onReset: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
          });
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final item = contacts[index];
          final isExpanded = _expandedContactIds.contains(item.id);

          return _buildContactAccordionCard(
            item: item,
            isExpanded: isExpanded,
            onToggle: () {
              setState(() {
                if (isExpanded) {
                  _expandedContactIds.remove(item.id);
                } else {
                  _expandedContactIds.add(item.id);
                }
              });
            },
          );
        },
      ),
    );
  }

  /// Kartu Accordion Saluran Kontak (Customer Service, WhatsApp, Website, Facebook, Twitter, Instagram)
  Widget _buildContactAccordionCard({
    required ContactChannelItem item,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Baris Accordion Kontak
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Container Icon Netral Minimalis (Monochrome, tanpa warna mencolok)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(
                        item.icon,
                        color: const Color(0xFF334155),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Judul Saluran Kontak
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    // Chevron Animasi Rotasi
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: isExpanded
                              ? AppColors.primary
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body Detail Kontak saat Accordion Terbuka
          if (isExpanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFF1F5F9),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Box Nilai Kontak & Tombol Aksi (Salin untuk HP & WA, Kunjungi untuk Web & Media Sosial)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            item.value,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!item.isLink)
                          // Tombol Salin untuk No HP dan WhatsApp
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _copyToClipboard(item.value, item.copyLabel),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.copy_rounded,
                                      size: 13,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Salin',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          // Tombol Kunjungi untuk Website, Facebook, Twitter, Instagram
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openContactLink(item),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Kunjungi',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_outward_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Deskripsi & Panduan Kontak
                  Text(
                    item.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 5. HELPER STATES (LOADING, EMPTY, ERROR)
  // ==========================================

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required VoidCallback onReset,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 36),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'Reset Filter',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 36),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 36,
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
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Coba Lagi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
