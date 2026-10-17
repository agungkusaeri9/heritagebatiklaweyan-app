# Catatan Perubahan (Changelog)

Dokumentasi riwayat pembaruan dan pengembangan aplikasi Heritage Batik Laweyan.

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
