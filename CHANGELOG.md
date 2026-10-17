# Catatan Perubahan (Changelog)

Dokumentasi riwayat pembaruan dan pengembangan aplikasi Heritage Batik Laweyan.

---

## [0.2.0] - 2026-10-18

Pembaruan besar antarmuka pengguna (UI/UX) bertema ARBatika, penambahan alur Welcome & Onboarding interaktif, perombakan desain Sign In & Create Account dengan header melengkung modern, sistem checklist ketentuan password real-time, integrasi penuh backend Laravel Sanctum, dan modul pengaturan toko.

### Fitur Baru

#### 1. Halaman Welcome & Onboarding Interaktif (ARBatika)
- **Welcome Screen**: Tampilan awal bertema ARBatika dengan hero image, headline *"ARBatika Makes You Feel Confident And Easy"*, tombol utama *"Let's Get Started"*, dan tautan navigasi langsung ke Sign In.
- **Onboarding Flow (3 Layar)**:
  - Mockup smartphone interaktif untuk pengalaman belanja fashion batik.
  - Indikator halaman halus (*animated smooth page indicator*).
  - Navigasi bawah konsisten dengan tombol *Back* (latar putih rounded) di kiri dan tombol *Next* (latar cokelat rounded) di kanan.
  - Opsi *Skip* untuk langsung menuju halaman utama/login.
- **Splash Screen Terintegrasi**: Sinkronisasi splash screen native Android 12+ (`values-v31`) dengan Flutter SplashView.

#### 2. Desain Baru Sign In & Create Account
- **Header Melengkung Modern**: Implementasi `CurvedHeaderClipper` dengan latar warna cokelat khas ARBatika (`#704F38`) dan tipografi putih bersih.
- **Pill-shaped Input Field**: Kolom input email, nama, dan password dengan border rounded warna ungu/biru pastel (`#A5B4FC` & `#6366F1`).
- **Show/Hide Password**: Ikon toggle visibilitas kata sandi yang responsif.
- **Terms & Conditions**: Checkbox persetujuan syarat & ketentuan dengan tautan dialog interaktif.

#### 3. Checklist Ketentuan Password Real-time
- Indikator interaktif langsung di bawah input password pada halaman registrasi:
  - Minimal 8 karakter.
  - Mengandung huruf besar (A-Z) dan huruf kecil (a-z).
  - Mengandung angka (0-9).
  - Mengandung karakter khusus / simbol (!@#$%^&*...).
- Indikator dinamis: Berubah seketika menjadi ikon ceklis hijau (`✔`) saat kriteria terpenuhi atau tanda silang merah (`✖`) saat kriteria belum lengkap.
- Validasi form mencegah pengiriman data sebelum seluruh kriteria password terpenuhi.

#### 4. Integrasi Backend Autentikasi (Laravel Sanctum)
- Dukungan login dan register langsung ke backend server Laravel (`10.0.2.2:8000`).
- Mekanisme fallback endpoint otomatis (`/auth/login`, `/login`, dan endpoint API standar).
- Penanganan token otentikasi Sanctum (`plainTextToken`) dan ID pengguna tipe integer/string yang kompatibel.
- **Sanitasi Username**: Konversi otomatis nama lengkap menjadi format `alpha_dash` untuk parameter `username` server guna menghindari penolakan validasi 422, sambil mempertahankan nama asli di field `name`.

#### 5. Modul Pengaturan Toko, FAQ & Metode Pembayaran
- Penambahan model data `StoreSettingModel`, `PaymentMethodModel`, dan `FaqModel`.
- Integrasi `StoreRemoteDataSource` dan `StoreViewModel` berbasis Riverpod untuk mengelola informasi toko, FAQ, dan metode pembayaran.

### Peningkatan & Perbaikan Sistem

- **Ekstraksi Error Validasi Spesifik (422)**: `DioClient` kini memprioritaskan ekstraksi pesan dari struktur `responseData['errors']` sehingga pesan error spesifik dari Laravel (misal format username, email duplikat) langsung ditampilkan ke pengguna melalui SnackBar, bukan lagi sekadar pesan umum *"Validasi gagal."*.
- **Perbaikan Navigasi GoRouter**: Memperbaiki masalah reset navigasi ke splash saat terjadi perubahan status autentikasi/error dengan memisahkan lifecycle notifier dari deklarasi router dan menerapkan route guards yang aman.
- **Penyempurnaan Umpan Balik Error**: Menghapus kotak error merah di atas form dan menggantikannya dengan floating SnackBar yang bersih dan tidak merusak tata letak antarmuka.

---

## [0.1.0] - 2026-10-17

Rilis versi awal aplikasi toko online Heritage Batik Laweyan. Versi ini menyiapkan fondasi aplikasi, alur masuk dan pendaftaran akun, sistem keamanan data, serta kesiapan integrasi perangkat.

### Fitur Baru

#### 1. Halaman Masuk (Login) dan Pendaftaran (Register)
- Halaman masuk untuk pelanggan dengan validasi alamat email dan kata sandi.
- Halaman pendaftaran akun baru untuk pembeli baru.
- Pesan petunjuk yang jelas saat data yang dimasukkan belum lengkap atau salah.
- Tombol keluar akun (logout) untuk mengakhiri sesi belanja dengan aman.

#### 2. Beranda dan Dasbor Pelanggan
- Tampilan informasi akun pelanggan dan status keanggotaan.
- Ringkasan poin belanja, status pesanan aktif, dan kupon diskon.
- Panel informasi status keamanan penyimpanan data pada perangkat.

#### 3. Sistem Izin Perangkat untuk Belanja
- Kamera: Digunakan untuk mengambil foto bukti transfer pembayaran, scan QRIS, dan scan barcode produk batik.
- Galeri Foto: Digunakan untuk memilih struk pembayaran dari galeri HP dan mengunggah foto ulasan produk.
- Lokasi (GPS): Digunakan untuk mendeteksi alamat pengiriman secara tepat dan menghitung perkiraan ongkos kirim kurir.
- Notifikasi: Digunakan untuk mengirimkan info nomor resi kurir, status pesanan terbaru, dan promo belanja.
- Halaman kelola izin untuk melihat status izin yang aktif dan membuka menu pengaturan HP jika izin terkunci.

#### 4. Keamanan dan Penyimpanan Data
- Penyimpanan data rahasia (token sesi akun) menggunakan ruang penyimpanan terenkripsi pada perangkat sehingga aman dari penyalahgunaan.
- Penyimpanan data umum (nama pengguna terakhir dan preferensi aplikasi) agar pengguna tidak perlu mengetik ulang saat membuka aplikasi kembali.

#### 5. Koneksi Server dan Penanganan Kendala
- Pengaturan jalur komunikasi data ke server toko online yang stabil dengan batas waktu tunggu otomatis.
- Pembaruan sesi masuk secara otomatis di latar belakang tanpa mengganggu pengguna saat berbelanja.
- Pencatatan riwayat koneksi dan laporan error otomatis untuk memudahkan perbaikan sistem jika terjadi gangguan jaringan.

#### 6. Tampilan dan Kenyamanan Pengguna
- Desain antarmuka toko online bernuansa batik modern dengan kombinasi warna biru dongker, emas sogan, dan latar bersih.
- Teks yang mudah dibaca menggunakan jenis huruf Plus Jakarta Sans.
- Komponen tampilan yang responsif dan menyesuaikan dengan baik di berbagai ukuran layar ponsel.

#### 7. Kestabilan Sistem Android
- Penyesuaian target sistem Android SDK versi 37 agar mendukung fitur perizinan versi Android terbaru.
- Optimalisasi proses pembuatan aplikasi agar lancar dan bebas dari kendala cache sistem.

#### 8. Otomatisasi Pembuatan APK (CI/CD GitHub Actions)
- Penambahan alur kerja otomatisasi di GitHub Actions yang langsung membuat berkas `heritage_batik.apk` setiap kali ada pembaruan di branch `main`.
- Pengiriman berkas `heritage_batik.apk` secara otomatis sebagai lampiran ke alamat email yang telah ditentukan.
- Penyimpanan berkas APK di tab Artifacts GitHub Actions selama 14 hari sehingga selalu dapat diunduh kapan saja.
