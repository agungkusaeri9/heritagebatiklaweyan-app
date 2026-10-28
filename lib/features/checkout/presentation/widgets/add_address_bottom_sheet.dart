import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/region_model.dart';
import '../viewmodels/checkout_providers.dart';

/// Modal Bottom Sheet untuk menambahkan alamat pengiriman baru
/// Lengkap dengan pemilihan Provinsi, Kota/Kabupaten, dan Kecamatan dinamis dari API
class AddAddressBottomSheet extends ConsumerStatefulWidget {
  final Future<bool> Function(Map<String, dynamic> data) onSave;

  const AddAddressBottomSheet({
    super.key,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<bool> Function(Map<String, dynamic> data) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (sheetContext) => AddAddressBottomSheet(onSave: onSave),
    );
  }

  @override
  ConsumerState<AddAddressBottomSheet> createState() =>
      _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends ConsumerState<AddAddressBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController(text: 'Rumah');
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalController = TextEditingController(text: '57148');
  bool _isPrimary = true;
  bool _isSaving = false;

  // Region State
  List<ProvinceModel> _provinces = [];
  List<CityModel> _cities = [];
  List<SubdistrictModel> _subdistricts = [];

  ProvinceModel? _selectedProvince;
  CityModel? _selectedCity;
  SubdistrictModel? _selectedSubdistrict;

  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;
  bool _isLoadingSubdistricts = false;

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _fetchProvinces() async {
    setState(() => _isLoadingProvinces = true);
    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final list = await repo.getProvinces();
      if (mounted) {
        setState(() {
          _provinces = list.isNotEmpty ? list : _fallbackProvinces();
          _isLoadingProvinces = false;
          // Set default ke Jawa Tengah jika ada
          final defaultProv = _provinces.firstWhere(
            (p) => p.id == 10 || p.name.toLowerCase().contains('jawa tengah'),
            orElse: () => _provinces.first,
          );
          _onSelectProvince(defaultProv);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _provinces = _fallbackProvinces();
          _isLoadingProvinces = false;
          _onSelectProvince(_provinces.first);
        });
      }
    }
  }

  Future<void> _onSelectProvince(ProvinceModel province) async {
    setState(() {
      _selectedProvince = province;
      _selectedCity = null;
      _selectedSubdistrict = null;
      _cities = [];
      _subdistricts = [];
      _isLoadingCities = true;
    });

    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final list = await repo.getCities(province.id);
      if (mounted) {
        setState(() {
          _cities = list.isNotEmpty
              ? list
              : (province.id == 10 ? _fallbackCities() : []);
          _isLoadingCities = false;
          // Set default Surakarta jika Jateng
          if (province.id == 10 && _cities.isNotEmpty) {
            final defaultCity = _cities.firstWhere(
              (c) => c.id == 445 || c.name.toLowerCase().contains('surakarta'),
              orElse: () => _cities.first,
            );
            _onSelectCity(defaultCity);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cities = province.id == 10 ? _fallbackCities() : [];
          _isLoadingCities = false;
          if (_cities.isNotEmpty) {
            _onSelectCity(_cities.first);
          }
        });
      }
    }
  }

  Future<void> _onSelectCity(CityModel city) async {
    setState(() {
      _selectedCity = city;
      _selectedSubdistrict = null;
      _subdistricts = [];
      _isLoadingSubdistricts = true;
      if (city.postalCode != null && city.postalCode!.isNotEmpty) {
        _postalController.text = city.postalCode!;
      }
    });

    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final list = await repo.getSubdistricts(city.id);
      if (mounted) {
        setState(() {
          _subdistricts = list.isNotEmpty
              ? list
              : (city.id == 445 ? _fallbackSubdistricts() : []);
          _isLoadingSubdistricts = false;
          // Set default Laweyan jika Surakarta
          if (city.id == 445 && _subdistricts.isNotEmpty) {
            final defaultSub = _subdistricts.firstWhere(
              (s) => s.id == 6164 || s.name.toLowerCase().contains('laweyan'),
              orElse: () => _subdistricts.first,
            );
            _selectedSubdistrict = defaultSub;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _subdistricts = city.id == 445 ? _fallbackSubdistricts() : [];
          _isLoadingSubdistricts = false;
          if (_subdistricts.isNotEmpty) {
            _selectedSubdistrict = _subdistricts.first;
          }
        });
      }
    }
  }

  List<ProvinceModel> _fallbackProvinces() => const [
        ProvinceModel(id: 10, name: 'Jawa Tengah'),
        ProvinceModel(id: 9, name: 'Jawa Barat'),
        ProvinceModel(id: 11, name: 'Jawa Timur'),
        ProvinceModel(id: 5, name: 'DI Yogyakarta'),
        ProvinceModel(id: 6, name: 'DKI Jakarta'),
        ProvinceModel(id: 3, name: 'Banten'),
        ProvinceModel(id: 1, name: 'Bali'),
      ];

  List<CityModel> _fallbackCities() => const [
        CityModel(
          id: 445,
          provinceId: 10,
          name: 'Kota Surakarta (Solo)',
          postalCode: '57113',
        ),
        CityModel(
          id: 433,
          provinceId: 10,
          name: 'Kabupaten Sukoharjo',
          postalCode: '57514',
        ),
        CityModel(
          id: 427,
          provinceId: 10,
          name: 'Kabupaten Sragen',
          postalCode: '57211',
        ),
        CityModel(
          id: 497,
          provinceId: 10,
          name: 'Kabupaten Wonogiri',
          postalCode: '57619',
        ),
        CityModel(
          id: 37,
          provinceId: 10,
          name: 'Kabupaten Banjarnegara',
          postalCode: '53419',
        ),
      ];

  List<SubdistrictModel> _fallbackSubdistricts() => const [
        SubdistrictModel(id: 6164, cityId: 445, name: 'Laweyan'),
        SubdistrictModel(id: 6162, cityId: 445, name: 'Banjarsari'),
        SubdistrictModel(id: 6163, cityId: 445, name: 'Jebres'),
        SubdistrictModel(id: 6165, cityId: 445, name: 'Pasar Kliwon'),
        SubdistrictModel(id: 6166, cityId: 445, name: 'Serengan'),
      ];

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih provinsi')),
      );
      return;
    }

    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kota/kabupaten')),
      );
      return;
    }

    if (_selectedSubdistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kecamatan')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'label': _labelController.text.trim(),
      'recipient_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'full_address': _addressController.text.trim(),
      'province_id': _selectedProvince!.id,
      'city_id': _selectedCity!.id,
      'subdistrict_id': _selectedSubdistrict!.id,
      'postal_code': _postalController.text.trim().isNotEmpty
          ? _postalController.text.trim()
          : '57148',
      'is_primary': _isPrimary,
    };

    final success = await widget.onSave(payload);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  void _openSearchablePicker<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelExtractor,
    required ValueChanged<T> onSelected,
    T? currentItem,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (pickerCtx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setPickerState) {
            final filtered = items.where((item) {
              final label = labelExtractor(item).toLowerCase();
              return label.contains(query.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(pickerCtx),
                        icon: const Icon(Icons.close_rounded,
                            size: 22, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Input
                  TextField(
                    onChanged: (val) {
                      setPickerState(() => query = val);
                    },
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // List
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ditemukan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (ctx, idx) {
                              final item = filtered[idx];
                              final isSelected = item == currentItem;
                              final label = labelExtractor(item);

                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                title: Text(
                                  label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle_rounded,
                                        size: 20, color: AppColors.primary)
                                    : null,
                                onTap: () {
                                  Navigator.pop(pickerCtx);
                                  onSelected(item);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 16),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add New Address',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          size: 22, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // Label Alamat (Rumah / Kantor)
                _buildTextField(
                  controller: _labelController,
                  label: 'Address Label',
                  hint: 'Contoh: Rumah, Kantor, Toko',
                ),

                const SizedBox(height: 12),

                // Nama Penerima
                _buildTextField(
                  controller: _nameController,
                  label: 'Recipient Name',
                  hint: 'Nama Lengkap Penerima',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),

                const SizedBox(height: 12),

                // Nomor Telepon
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Contoh: 08123456789',
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),

                const SizedBox(height: 12),

                // 3. Pemilih Provinsi (Province)
                _buildSelectorField(
                  label: 'Provinsi *',
                  value: _selectedProvince?.name,
                  placeholder: 'Pilih Provinsi',
                  isLoading: _isLoadingProvinces,
                  onTap: () {
                    _openSearchablePicker<ProvinceModel>(
                      title: 'Pilih Provinsi',
                      items: _provinces,
                      labelExtractor: (p) => p.name,
                      currentItem: _selectedProvince,
                      onSelected: (prov) => _onSelectProvince(prov),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 4. Pemilih Kota / Kabupaten (City)
                _buildSelectorField(
                  label: 'Kota / Kabupaten *',
                  value: _selectedCity?.name,
                  placeholder: _selectedProvince == null
                      ? 'Pilih provinsi terlebih dahulu'
                      : 'Pilih Kota / Kabupaten',
                  isLoading: _isLoadingCities,
                  enabled: _selectedProvince != null,
                  onTap: () {
                    if (_selectedProvince == null) return;
                    _openSearchablePicker<CityModel>(
                      title: 'Pilih Kota / Kabupaten',
                      items: _cities,
                      labelExtractor: (c) => c.name,
                      currentItem: _selectedCity,
                      onSelected: (city) => _onSelectCity(city),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 5. Pemilih Kecamatan (Subdistrict)
                _buildSelectorField(
                  label: 'Kecamatan *',
                  value: _selectedSubdistrict?.name,
                  placeholder: _selectedCity == null
                      ? 'Pilih kota terlebih dahulu'
                      : 'Pilih Kecamatan',
                  isLoading: _isLoadingSubdistricts,
                  enabled: _selectedCity != null,
                  onTap: () {
                    if (_selectedCity == null) return;
                    _openSearchablePicker<SubdistrictModel>(
                      title: 'Pilih Kecamatan',
                      items: _subdistricts,
                      labelExtractor: (s) => s.name,
                      currentItem: _selectedSubdistrict,
                      onSelected: (sub) {
                        setState(() => _selectedSubdistrict = sub);
                      },
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Alamat Lengkap
                _buildTextField(
                  controller: _addressController,
                  label: 'Full Address',
                  hint: 'Nama jalan, RT/RW, nomor rumah, patokan',
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),

                const SizedBox(height: 12),

                // Kode Pos
                _buildTextField(
                  controller: _postalController,
                  label: 'Postal Code',
                  hint: 'Contoh: 57148',
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 10),

                // Set Sebagai Alamat Utama Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _isPrimary,
                      activeColor: AppColors.primary,
                      onChanged: (val) =>
                          setState(() => _isPrimary = val ?? false),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isPrimary = !_isPrimary),
                      child: Text(
                        'Set as primary address',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Tombol Simpan
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Save Address',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorField({
    required String label,
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
    bool isLoading = false,
    bool enabled = true,
  }) {
    final hasValue = value != null && value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled && !isLoading ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value : placeholder,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
