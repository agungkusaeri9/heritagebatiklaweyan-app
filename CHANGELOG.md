# Catatan Perubahan (Changelog)

Dokumentasi riwayat pembaruan dan pengembangan aplikasi Heritage Batik Laweyan.

---

## [0.5.0-alpha.2] - 2026-10-23

Implementasi halaman Kebijakan & Privasi (Privacy Policy) yang terintegrasi penuh dengan backend API setting, antarmuka modern yang simpel dan bersih (clean typography & bullet points), modal konfirmasi logout interaktif berbasis Bottom Sheet dengan loading state dan proteksi duplikasi, serta badge "Soon" pada menu Payment Methods dan Invites Friends.

### Fitur Baru: Kebijakan & Privasi dan Konfirmasi Logout

#### 1. Halaman Kebijakan & Privasi (Privacy Policy Screen)
- **Akses Langsung dari Menu Profil**: Menu *"Privacy Policy"* pada daftar pengaturan akun kini mengarahkan langsung ke rute `/privacy-policy`.
- **Desain Simpel, Rapi & Clean**:
  - Mengikuti standar antarmuka minimalis tanpa kontainer kartu bertumpuk (*cardless*) dan tanpa icon dekoratif berlebih di judul bagian.
  - Judul setiap bagian ditampilkan tebal dan tegas (*Plus Jakarta Sans* bold 16px).
  - Poin-poin klausul diformat rapi dengan dot abu-abu minimalis, subjudul bernomor diformat semi-bold, dan tinggi baris proporsional (`height: 1.6`) untuk kenyamanan membaca.
- **Tiga Bagian Kebijakan Terstruktur**:
  1. **Cancellation Policy**: Ditampilkan di bagian atas dan terhubung langsung ke kolom baru `cancellation_policy` dari backend API (dengan fallback cerdas ke klausul pembatalan di policy umum jika belum terisi).
  2. **Terms & Conditions**: Menampilkan syarat dan ketentuan pemesanan, karakteristik produk batik asli, kebijakan pengembalian & penukaran, serta pengiriman.
  3. **Privacy Policy**: Menampilkan aturan pengumpulan informasi pribadi, penggunaan data, keamanan data pelanggan, dan persetujuan pengguna.
- **Integrasi Penuh Backend API**:
  - Mengambil data dinamis secara real-time via `StoreRemoteDataSource.getPrivacyPolicy()` dari endpoint `/settings/privacy-policy` dan `/settings`.
  - Tidak menggunakan data hardcode atau teks lorem ipsum sebagai konten utama.
- **Penanganan Status (State Handling)**:
  - *Loading State*: Menampilkan animasi garis skeleton placeholder sederhana yang serasi dengan desain clean.
  - *Error State*: Menampilkan ikon kesalahan dengan pesan informatif dan tombol *"Coba Lagi"* (*retry*).
  - *Empty State*: Tampilan jika belum ada data kebijakan dari toko dengan tombol *"Muat Ulang"*.
  - *Pull-to-Refresh*: Pengguna dapat menarik layar ke bawah (`RefreshIndicator`) untuk memperbarui data kebijakan kapan saja.

#### 2. Modal Konfirmasi Logout Bottom Sheet (Logout Confirmation)
- **Desain Modern Bottom Sheet**:
  - Menggantikan dialog alert bawaan dengan modal bottom sheet berwarna putih dengan sudut atas melengkung (`Radius.circular(24)`), bilah pegangan abu-abu (*drag handle*) di bagian atas, dan latar belakang meredup (*dimmed semi-transparent overlay* `alpha: 0.5`).
  - Menampilkan judul terpusat **Logout**, garis pembatas tipis, dan pesan konfirmasi `Are you sure you want to log out?`.
- **Dua Tombol Aksi**:
  - **Cancel**: Tombol *outlined* dengan sudut membulat (*pill shape*) yang menutup modal secara aman tanpa memengaruhi sesi login pengguna.
  - **Yes, Logout**: Tombol utama berwarna cokelat khas Heritage Batik (`AppColors.primary`) yang memicu proses logout.
- **Loading State & Anti-Duplikasi Request**:
  - Menampilkan indikator putaran *spinner* putih pada tombol *Yes, Logout* saat proses logout sedang berlangsung.
  - Kedua tombol dinonaktifkan dan penutupan paksa melalui tombol back atau gestur swipe diblokir (`PopScope(canPop: !_isLoading)`) untuk mencegah *duplicate request*.
- **Pembersihan Sesi & Navigasi**:
  - Menjalankan mekanisme logout eksisting dari `AuthViewModel`, membersihkan token/sesi lokal, menutup modal bottom sheet, menampilkan notifikasi sukses via `AppSnackBar`, dan mengarahkan pengguna kembali ke layar Login (`/login`).
  - Penanganan kegagalan dengan menampilkan pesan kesalahan yang ramah pengguna.

#### 3. Pembaruan Menu Profil (Badge "Soon")
- **Penanda Menu Segera Hadir**:
  - Menu *Payment Methods* dan *Invites Friends* pada `ProfileMenuList` kini dilengkapi label badge berlabel *"Soon"* bernuansa amber lembut (`#FEF3C7` / `#B45309`).
  - Ikon chevron panah disembunyikan dan interaksi tap dinonaktifkan secara otomatis.

#### 4. Model Data & Pengujian Komprehensif
- **Pembaruan Model**:
  - Menambahkan properti `cancellationPolicy` pada `StoreSettingModel` lengkap dengan pemetaan `fromJson`, `toMap`, dan `fromMap`.
  - Pembuatan model parser `PolicySectionModel` untuk ekstraksi terstruktur dari respon backend.
- **Unit & Widget Testing**:
  - `policy_section_model_test.dart`: Memverifikasi parsing Cancellation Policy dari kolom khusus, pemisahan klausul, dan penanganan status kosong.
  - `store_models_test.dart`: Memverifikasi serialisasi JSON dan pemetaan SQLite untuk properti `cancellationPolicy`.
  - `logout_confirmation_bottom_sheet_test.dart`: Pengujian widget untuk memastikan kemunculan modal, teks konfirmasi, perilaku tombol *Cancel*, dan penutupan modal.

---

## [0.5.0-alpha.1] - 2026-10-20

Implementasi modul Pengaturan Akun (Settings) yang dapat diakses langsung dari menu Profil, halaman Pengelola Kata Sandi (Password Manager) lengkap dengan checklist validasi keamanan real-time & integrasi backend API, halaman Pengaturan Notifikasi (Notification Settings), dialog konfirmasi Hapus Akun permanen, serta registrasi rute navigasi terintegrasi.

### Fitur Baru: Pengaturan Akun & Keamanan (Settings & Password Manager)

#### 1. Halaman Pengaturan Akun (Settings Screen)
- **Akses Langsung dari Menu Profil**: Menu *"Settings"* pada halaman Akun/Profil pengguna kini langsung mengarahkan ke halaman `/settings`.
- **Desain Kartu Elegan**: Tampilan berlatar putih bersih dengan header judul *"Settings"*, tombol navigasi kembali, dan kartu menu ber-border halus.
- **Tiga Menu Utama**:
  - **Notification Settings**: Navigasi ke pengaturan preferensi notifikasi aplikasi (`/settings/notifications`).
  - **Password Manager**: Navigasi ke pengelolaan dan pembaruan kata sandi akun (`/settings/password`).
  - **Delete Account**: Menu beraksen merah lembut untuk opsi penghapusan akun permanen.

#### 2. Fitur Pengelola Kata Sandi (Password Manager)
- **Tiga Kolom Isian Kata Sandi**:
  - *Current Password*: Kolom isian kata sandi saat ini dengan tautan cepat *"Forgot Password?"* di bawahnya yang langsung mengarah ke alur pemulihan kata sandi (`/forgot-password`).
  - *New Password*: Kolom isian kata sandi baru.
  - *Confirm New Password*: Kolom konfirmasi pengulangan kata sandi baru.
- **Toggle Show/Hide Password**: Ikon mata interaktif pada setiap kolom input untuk melihat atau menyembunyikan kata sandi secara independen.
- **Checklist Kriteria Kata Sandi Real-Time**:
  - Menampilkan 4 indikator keamanan: Minimal 8 karakter, memuat huruf besar & huruf kecil, memuat angka, serta memuat karakter khusus/simbol.
  - Indikator otomatis berubah warna menjadi hijau dengan ikon ceklis (`✔`) secara interaktif saat kriteria terpenuhi.
- **Validasi Komprehensif Sebelum Kirim**:
  - Memastikan seluruh kolom wajib diisi.
  - Memastikan seluruh kriteria keamanan kata sandi baru terpenuhi.
  - Memastikan kata sandi baru tidak boleh sama dengan kata sandi saat ini.
  - Memastikan konfirmasi kata sandi cocok secara persis.
- **Tombol Aksi Melayang di Bawah (Fixed Bottom Button)**:
  - Tombol *"Change Password"* bertema cokelat sogan khas ARBatika di bagian bawah layar yang selalu mudah dijangkau.
  - Indikator putaran *loading* saat proses pengiriman data berlangsung.
- **Integrasi Backend API**:
  - Terhubung langsung ke endpoint `PUT /user/password` menggunakan `DioClient`.
  - Penanganan respon sukses dengan pesan konfirmasi, pembersihan form otomatis, dan notifikasi SnackBar.
  - Penanganan respon gagal dengan ekstraksi pesan kesalahan spesifik dari server (misalnya: kata sandi lama tidak cocok).

#### 3. Menu Pengaturan Notifikasi (Notification Settings - Segera Hadir)
- **Badge Indikator "Soon"**: Penambahan lencana berlabel *"Soon"* bernuansa amber lembut pada baris menu Notification Settings di halaman Settings.
- **Proteksi Non-Aktif**: Menu dinonaktifkan dan tidak dapat diklik (*disabled*) selama fitur masih bertanda *Soon*.
- **Halaman Pengaturan Notifikasi Tersedia**: Antarmuka preferensi notifikasi (*Push Notification*, *Order Status*, *Promos & Discounts*, *Payment Alerts*) dengan sakelar toggle bertema cokelat Heritage Batik siap diintegrasikan.

#### 4. Fitur Hapus Akun (Delete Account) & Proteksi Keamanan
- **Dialog Modal Konfirmasi Tegas**: Menampilkan pertanyaan konfirmasi *"Apakah Anda benar-benar yakin ingin menghapus akun?"* dengan ikon peringatan merah (*destructive*).
- **Pemberitahuan Transparan**: Penjelasan bahwa penghapusan bersifat permanen dan seluruh data profil, alamat, keranjang, serta riwayat pesanan akan dinonaktifkan dari sistem.
- **Integrasi Penuh Backend API**: Terhubung langsung ke endpoint `DELETE /user/account` melalui `DioClient`.
- **Penanganan Sesi & Umpan Balik**: Dilengkapi status indikator putaran loading, penanganan pesan error dari server, pembersihan sesi token (*logout*), dan pengalihan otomatis ke layar Sign In (`/login`).

#### 5. Fitur Baru: Pusat Bantuan (Help Center) & Desain Contact Us Accordion
- **Hierarki Layout Terstruktur**: Tata letak persis mengikuti desain referensi: **Header → Search Bar → Tabs → Content**.
- **Search Bar Global di Atas Tabs**: Terletak sebelum tab selector, dengan placeholder dinamis dan tombol hapus cepat (`X`) yang berfungsi memfilter FAQ maupun saluran Contact Us secara real-time.
- **Tab FAQ & Contact Us Segmented**: Kontrol tab pill modern dengan animasi perpindahan mulus dan indikator tab aktif beraksen cokelat sogan.
- **Accordion Kontak Lengkap (6 Saluran Resmi)**:
  - Tab *Contact Us* menampilkan 6 item kontak: *Customer Service*, *WhatsApp*, *Website*, *Facebook*, *Twitter*, dan *Instagram*.
  - Setiap saluran kontak disajikan dalam bentuk accordion kartu mandiri dengan icon monokrom netral (tanpa warna mencolok), animasi putar chevron (`AnimatedRotation`), deskripsi operasional, tombol salin (*one-tap copy*) khusus untuk No. Telepon Customer Service, serta tombol *"Kunjungi"* yang langsung membuka aplikasi masing-masing (WhatsApp ke aplikasi WhatsApp/WhatsApp Business, Facebook ke aplikasi Facebook, Twitter ke aplikasi Twitter/X, Instagram ke aplikasi Instagram, dan Website ke browser default) tanpa menyalin ke papan klip.
  - Seluruh accordion (termasuk Customer Service dan WhatsApp) berada dalam kondisi tertutup (*collapsed*) secara default saat halaman dimuat, dan dapat dibuka atau ditutup secara independen oleh pengguna.
- **Integrasi Backend API**: Terhubung ke endpoint `/api/v1/faqs` untuk daftar FAQ dan `/api/v1/settings` untuk informasi kontak resmi toko (`StoreSettingModel`).
- **Kategori FAQ & Filter Chips**: Horizontal filter chips (*All*, *Services*, *General*, *Account*, dan kategori dinamis dari respon API) yang tersinkronisasi dengan kata kunci pencarian.
- **Penanganan Status Komprehensif**: Mendukung animasi *shimmer skeleton loading*, pesan kesalahan dengan tombol coba lagi (*retry*), status kosong (*empty state*) dengan tombol reset pencarian, serta *pull-to-refresh*.

#### 6. Registrasi Rute & Navigasi Terpusat
- Pendaftaran rute baru pada `AppRouter` (`lib/core/router/app_router.dart`):
  - `/settings`: Mengarah ke `SettingsView`.
  - `/settings/notifications`: Mengarah ke `NotificationSettingsView`.
  - `/settings/password`: Mengarah ke `PasswordManagerView`.
  - `/help-center`: Mengarah ke `HelpCenterView`.
- Pembaruan model `ProfileMenuItemModel` dan widget `ProfileMenuList` agar item menu Settings dan Help Center terhubung langsung ke rute masing-masing.

---

## [0.4.0] - 2026-10-19

Implementasi antarmuka (UI) Halaman Utama (Home Screen) Flutter berdesain modern, elegan, dan terstruktur dengan komponen reusable, banner promo carousel, kartu informasi toko & URBatik Points, kategori produk interaktif, daftar rekomendasi batik dengan badge diskon & strikethrough, serta navigasi 4 tab responsif.

### Fitur Baru: Halaman Utama (Home Screen)

#### 1. Header & Search Bar
- **Header Lokasi Pengiriman**: Menampilkan alamat aktif pengiriman (`Deliver to`) dengan dropdown interaktif untuk mengganti lokasi secara mudah.
- **Ikon Keranjang (Cart) & Notifikasi Ber-Badge**: Menampilkan badge merah penanda jumlah item belanjaan dan notifikasi terbaru.
- **Search Bar Modern**: Dilengkapi ikon pencarian, placeholder `Search here ...`, dan tombol filter cepat bertema cokelat sogan.

#### 2. Banner Promo Carousel
- **Banner Promosi Elegan**: Menampilkan judul promo, deskripsi singkat, tag diskon menarik (hingga 50% OFF), dan tombol aksi cepat.
- **Indikator Titik Dinamis**: Dilengkapi animasi dots halus di bawah banner untuk menandai slide promo yang sedang aktif.
- **Dukungan Swipe & Auto-Scroll**: Berpindah secara halus menggunakan data dummy lokal.

#### 3. Information Card (Toko & Poin)
- **Informasi Toko Terdekat**: Menampilkan nama toko *"Heritage Batik Store"* dan estimasi jarak (1.2 km).
- **Poin Loyalitas URBatik**: Menampilkan saldo poin belanja (*2.450 Pts*) dengan aksen bintang emas.
- **Pembatas Vertikal Proporsional**: Layout rapi yang menyesuaikan berbagai ukuran layar ponsel tanpa overflow.

#### 4. Kategori Produk (Category Section)
- **5 Kategori Batik Pilihan**: Sarung, Kain, Tunik, Anak-Anak, dan All.
- **Umpan Balik Visual Interaktif**: Kategori yang dipilih otomatis mendapatkan sorotan border dan latar belakang aksen cokelat sogan secara lokal.

#### 5. Rekomendasi Produk (Recommendation Section)
- **Kartu Produk Scroll Horizontal**: Menampilkan visual kain/busana batik autentik, nama produk, rating bintang, dan jumlah penjualan.
- **Penetapan Harga Diskon**: Menampilkan harga setelah diskon yang jelas serta harga asli dengan coretan garis (*strikethrough*).
- **Badge Diskon & Aksi Cepat**: Dilengkapi lencana persentase diskon (`-25%`), tombol favorit (*wishlist*), dan tombol tambah ke keranjang mini.

#### 6. Bilah Navigasi Bawah (Bottom Navigation)
- **4 Menu Utama**: Home, Wishlist, History, dan Account dengan status visual aktif yang tegas.
- **Perpindahan Tab Halus**: Navigasi antar tab berbasis state lokal dengan tampilan placeholder bersih untuk Wishlist dan History, serta tab Account terintegrasi.

---

### Fitur Baru: Halaman Profil Pengguna (Profile Screen)

#### 1. Header Profil
- **Tombol Kembali (Back)**: Tombol melingkar dengan ikon panah di sudut kiri atas untuk navigasi kembali yang responsif.
- **Judul Terpusat**: Teks judul *"Profile"* yang proporsional di tengah header.

#### 2. Informasi Profil (Profile Information)
- **Foto Profil Melingkar**: Avatar foto profil pengguna dengan border halus dan bayangan elegan.
- **Tombol Edit Pena (Pencil Icon)**: Tombol melingkar cokelat sogan dengan ikon pena (`Icons.edit_rounded`) di sudut kanan bawah foto untuk memicu perubahan foto profil.
- **Nama Pengguna Terpusat**: Tampilan nama pengguna yang tegas dan jelas di bawah foto profil.

#### 3. Daftar Menu Pengaturan Akun (Profile Menu List)
- **8 Menu Pilihan Lengkap**: *Your profile*, *Payment Methods*, *My Orders*, *Settings*, *Help Center*, *Privacy Policy*, *Invites Friends*, dan *Log out*.
- **Ikon, Label & Chevron Konsisten**: Setiap baris menu dilengkapi ikon khusus berlatar lingkaran lembut, label yang jelas, panah chevron kanan, serta pembatas tipis (*divider*).
- **Aksi Khusus & Simulasi Log Out**: Menu *Log out* memiliki warna merah (*destructive*) dengan dialog modal konfirmasi keluar akun yang bersahabat.

#### 4. Bilah Navigasi Bawah Melayang (Rounded Pill Bottom Navigation)
- **Desain Rounded Pill Melayang**: Background gelap elegan (`#231B15`) melayang dengan sudut melengkung sempurna (*radius 36*).
- **5 Menu Utama Reusable**: Home, Bag, Wishlist, Messages, dan Account.
- **Indikator Aktif Lingkaran Putih**: Menu aktif memiliki latar lingkaran putih dengan ikon cokelat khas Heritage Batik (`#704F38`), sedangkan menu non-aktif berwarna terang transparan.
- **Komponen Inti Reusable (`AppBottomNavigation`)**: Dibuat sebagai widget reusable terpusat di `lib/core/widgets/app_bottom_navigation.dart`, digunakan bersama oleh Dashboard/Home (`HomeBottomNavigation`) dan Halaman Profil/Akun (`ProfileBottomNavigation`).
- **Integrasi Menu Account di Dashboard/Home**: Tab ke-5 (index 4) pada Dashboard/Home kini langsung menampilkan halaman Akun lengkap (foto profil melingkar, tombol edit pena, nama, email, serta 8 menu pengaturan akun).
- **Dukungan Rute Ganda**: Menambahkan rute `/account` di samping `/profile` untuk navigasi langsung ke halaman akun pengguna.

---

## [0.3.0] - 2026-10-18

Pembaruan fitur baru sistem pemulihan akun (Lupa Kata Sandi & verifikasi 6 kotak kode OTP interaktif), fitur pemilihan lokasi pengguna (GPS perangkat & input manual), serta halaman Lengkapi Profil (Complete Your Profile) otomatis setelah masuk akun.

### Fitur Baru: Pemulihan Akun & Kata Sandi

#### 1. Alur Lupa Kata Sandi (Forgot Password)
- **Halaman Masukkan Email**: Tautan *"Forgot Password?"* di layar Sign In kini langsung mengarahkan ke halaman pemulihan akun dengan kolom isian email terdaftar dan tombol *"Kirim Kode OTP"* bertema cokelat ARBatika.
- **Validasi Otomatis**: Memeriksa format email sebelum mengirim permintaan ke server toko online.

#### 2. Input 6 Kotak Kode OTP Interaktif
- **Desain 6 Kotak Khusus**: Tampilan verifikasi menggunakan **6 kotak angka individual terpisah** (bukan kolom teks biasa), dengan border melengkung halus dan efek sorotan saat aktif.
- **Otomatis Pindah Kotak**: Kursor otomatis berpindah ke kotak berikutnya saat satu angka diketik.
- **Mundur Otomatis saat Backspace**: Jika tombol hapus ditekan pada kotak kosong, kursor otomatis kembali ke kotak sebelumnya.
- **Dukungan Tempel (Paste)**: Mendukung tempel langsung kode 6 digit dari SMS atau email, seluruh kotak langsung terisi otomatis.
- **Hitung Mundur Kirim Ulang (60 Detik)**: Tombol kirim ulang kode OTP dilengkapi batas waktu tunggu 60 detik agar pengiriman tetap aman dan teratur.

#### 3. Halaman Buat Kata Sandi Baru
- **Integrasi Verifikasi Kode**: Setelah 6 kotak OTP diverifikasi oleh server, pengguna langsung diarahkan ke layar pembuatan kata sandi baru dengan membawa token keamanan.
- **Checklist 4 Syarat Kata Sandi**: Dilengkapi panduan keamanan (minimal 8 karakter, huruf besar & kecil, angka, dan simbol khusus) yang otomatis berubah hijau ketika terpenuhi secara real-time.
- **Kembali Otomatis ke Sign In**: Setelah kata sandi berhasil diperbarui, muncul notifikasi sukses dan pengguna langsung diarahkan kembali ke layar Sign In.

---

### Fitur Baru: Pemilihan Lokasi & Sinkronisasi (Location Selection)

#### 1. Deteksi Lokasi Otomatis via GPS
- **Tombol *"Allow Location Access"***: Mengambil koordinat lokasi pengguna (latitude & longitude) secara langsung dan akurat dalam satu kali sentuh.
- **Hemat Daya Baterai**: Lokasi hanya diambil satu kali saat diminta (one-shot), tanpa proses pelacakan terus-menerus di latar belakang yang menguras baterai.
- **Penanganan Izin yang Ramah**: Menangani kondisi jika sensor GPS mati, izin lokasi ditolak sementara, atau ditolak permanen dengan tombol langsung ke Pengaturan Perangkat (*Open Settings*).

#### 2. Pengisian Lokasi Manual
- **Formulir Alamat Mandiri**: Pengguna dapat memasukkan detail nama jalan, kelurahan, atau kota tanpa perlu menyalakan GPS perangkat.
- **Pilihan Label Cepat (Chips)**: Dilengkapi tombol label instan seperti *"Rumah"*, *"Kantor"*, *"Toko"*, dan *"Laweyan"* untuk menandai tempat favorit dengan mudah.
- **Bebas Ketergantungan Layanan Luar**: Lokasi tersimpan langsung tanpa memerlukan layanan peta/geocoding pihak ketiga yang berbayar.

#### 3. Penyimpanan Lokal (Cache Offline) & Sinkronisasi Server
- **Muat Instan dari Memori HP**: Lokasi terakhir yang pernah dipilih langsung ditampilkan saat halaman dibuka tanpa menunggu jaringan internet.
- **Sinkronisasi Otomatis ke Backend**: Saat perangkat online dan pengguna telah masuk akun, lokasi disinkronkan ke server secara otomatis melalui endpoint resmi (`/api/v1/user/location`).
- **Tahan Gangguan Jaringan**: Aplikasi tetap berjalan lancar dan tidak keluar mendadak (crash) meski koneksi internet sedang lambat atau offline.

#### 4. Akses Cepat di Beranda & Pengaturan
- **Kartu Lokasi di Dasbor Utama**: Menampilkan ringkasan lokasi aktif pengguna di bagian atas beranda belanja dengan tombol pembaruan cepat.
- **Tautan Menu Izin (Permissions)**: Menu izin perangkat kini dapat langsung membuka layar pemilihan lokasi untuk memudahkan pengguna.

---

### Fitur Baru: Halaman Lengkapi Profil (Complete Your Profile)

#### 1. Tampilan Header & Avatar Elegan
- **Header Cokelat Melengkung ARBatika**: Bagian atas bertema cokelat khas Batik Laweyan (`#704F38`) dengan sudut melengkung halus dan pesan ramah kepada pembeli.
- **Avatar Interaktif dengan Pilihan Galeri**: Menampilkan foto profil melayang dengan tombol galeri cepat untuk memilih foto dari galeri perangkat, preview langsung, serta opsi menggunakan avatar bawaan ARBatika.

#### 2. Formulir Identitas Pengguna yang Rapi
- **Kolom Nama Lengkap (Full Name)**: Kolom isian nama dengan ikon profil, otomatis terisi data awal, dan validasi minimal 2 karakter.
- **Kolom Nomor Telepon (+62 Indonesia)**: Dilengkapi kode negara (`+62`), pemformatan hanya angka, dan validasi panjang digit standar nomor ponsel.
- **Pilihan Jenis Kelamin (Gender)**: Dropdown pilihan *Laki-laki (Male)* atau *Perempuan (Female)* dengan gaya border oval selaras aplikasi.

#### 3. Alur Otomatis & Terintegrasi
- **Loading Stabil di Halaman Profil**: Indikator loading tetap berada di tombol profil selama proses penyimpanan tanpa berpindah atau berkedip ke layar masuk (login).
- **Alur Bertahap (Profil -> Lokasi -> Dasbor)**:
  - Setelah profil berhasil disimpan, jika pengguna belum pernah memilih lokasi/alamat, aplikasi langsung mengarahkan ke layar Pemilihan Lokasi (`/location`) untuk perizinan GPS atau input manual.
  - Jika pengguna sudah pernah menyimpan lokasi sebelumnya, sinkronisasi lokasi berjalan otomatis di latar belakang (*background sync*) dan aplikasi langsung menuju halaman utama (Dashboard).
- **Tombol *"Complete Profile"***: Dilengkapi proteksi cegah klik ganda dan feedback notifikasi kartu lembut saat berhasil disimpan.
#### 4. Perbaikan Alur Keluar Akun (Logout)
- **Langsung Kembali ke Halaman Masuk**: Memperbaiki pembersihan data sesi dan status autentikasi saat logout sehingga aplikasi langsung berpindah seketika ke layar Sign In secara responsif.

---

## [0.2.1] - 2026-10-18

Pembaruan kenyamanan tampilan pada layar pembuka, halaman masuk, dan pendaftaran akun. Pesan peringatan kini hadir dengan warna yang lembut di mata, ketentuan kata sandi lebih ringkas, serta pengaturan koneksi ke server yang lebih stabil dan langsung.

### Kenyamanan & Tampilan Baru

#### 1. Layar Pembuka (Splash Screen) Lebih Bersih
- **Indikator Menghubungkan Lebih Rapi**: Tulisan dan putaran animasi saat menghubungkan ke server kini berada di bagian bawah layar dengan ukuran lebih kecil, sehingga tidak menutupi keindahan logo utama.
- **Pesan Gangguan yang Mudah Dipahami**: Jika koneksi internet terputus atau lambat, pesan ditampilkan dengan kalimat yang jelas dan bersahabat (misalnya: *"Koneksi melebihi batas waktu. Periksa jaringan Anda."*).
- **Tampilan Bebas Gangguan**: Menghilangkan tombol coba lagi yang menutupi layar agar tampilan tetap bersih dan elegan.

#### 2. Pesan Peringatan & Notifikasi Lebih Lembut di Mata
- **Warna Merah Pastel (Soft)**: Mengubah warna kotak pesan kesalahan dari yang sebelumnya merah menyala terang menjadi merah pastel lembut yang nyaman dan tidak silau di mata.
- **Teks Jelas & Mudah Dibaca**: Tulisan pada pesan tetap menggunakan warna marun pekat sehingga sangat mudah dibaca.
- **Desain Kartu Melayang**: Notifikasi berhasil maupun gagal kini tampil rapi berbentuk kartu melengkung di bagian bawah layar.

#### 3. Halaman Pendaftaran Akun (Daftar Akun) Lebih Ramping
- **Ketentuan Kata Sandi Ringkas**: Daftar syarat kata sandi kini ditata rapi menyamping (2 kolom), sehingga tidak memakan banyak tempat di layar HP.
- **Tombol Masuk Langsung Terlihat**: Bagian bawah halaman kini langsung memuat tautan *"Already have an account? Sign In"* tanpa harus digeser/scroll ke bawah.

#### 4. Halaman Masuk (Login) Lebih Pas di Tengah Layar
- **Header Cokelat Lebih Pas**: Bagian atas warna cokelat bertuliskan *"Sign In"* diperluas ke bawah secara proporsional.
- **Posisi Form di Tengah**: Kolom email dan kata sandi kini tepat berada di tengah layar HP, membuat ruang kosong di bagian bawah layar berkurang dan tampilan terlihat seimbang.
- **Jarak Kolom yang Rapi**: Jarak antara nama kolom, kotak isian, dan tombol tetap rapat dan nyaman digunakan.

### Kestabilan Sistem & Koneksi

#### 5. Pengenalan Pengguna Baru yang Lebih Cerdas
- **Tidak Mengulang Layar Sambutan**: Pengguna yang sudah pernah melihat panduan awal (onboarding) atau sudah pernah masuk akun tidak akan ditampilkan layar sambutan lagi saat membuka aplikasi.

#### 6. Koneksi Langsung ke Toko Online
- **Selalu Mengambil Data Asli**: Aplikasi kini langsung terhubung ke server toko online untuk mengambil produk, kategori, dan pengaturan toko terbaru tanpa menggunakan data tiruan offline.
- **Pengaturan Alamat Server Lebih Fleksibel**: Alamat koneksi server toko online kini dapat diatur dengan mudah melalui berkas konfigurasi (.env) agar stabil saat dicoba di berbagai jaringan.

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
