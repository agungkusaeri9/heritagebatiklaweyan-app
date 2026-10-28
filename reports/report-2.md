# Laporan Fitur Aplikasi Mobile ARBatik

Berikut adalah ringkasan fitur yang telah selesai dibangun pada aplikasi mobile ARBatik:

1. Layar Selamat Datang & Panduan (Welcome & Onboarding)
- Welcome Screen: Tampilan awal saat membuka aplikasi dengan logo ARBatik.
- Panduan Awal (Onboarding): Slider interaktif pengenalan aplikasi belanja batik Laweyan.
- Deteksi Otomatis: Panduan awal hanya tampil saat pertama kali aplikasi dibuka setelah diinstal.

2. Masuk, Daftar & Akun (Autentikasi)
- Registrasi Akun: Pendaftaran akun baru dengan nama, email, dan kata sandi (service email belum dibuat).
- Masuk (Login): Masuk akun menggunakan email dan kata sandi dengan validasi lengkap.
- Lupa Kata Sandi: Fitur reset kata sandi mandiri via kode OTP 6-digit ke email.
- Profil Pengguna: Melihat dan mengubah data diri (nama, nomor telepon/WhatsApp, jenis kelamin, dan foto profil).
- Keluar Akun (Logout): Tombol keluar akun yang dilengkapi dialog konfirmasi keamanan.

3. Beranda & Belanja (Home & Produk)
- Banner Promo: Tampilan banner promosi di bagian atas halaman utama (static).
- Kategori Produk: Filter koleksi produk berdasarkan kategori batik.
- Rekomendasi & Terlaris: Daftar produk unggulan dan terpopuler yang dapat digeser menyamping.
- Daftar Seluruh Produk: Memuat produk secara otomatis saat halaman digulir ke bawah (infinite scroll).
- Tambah ke Keranjang: Memasukkan barang ke keranjang belanja dengan notifikasi pesan singkat tanpa pop-up yang mengganggu.

4. Keranjang Belanja (My Cart)
- Daftar Belanja: Menampilkan foto produk, nama motif, varian ukuran, dan harga satuan.
- Atur Jumlah Barang: Tombol tambah dan kurang jumlah pesanan secara langsung.
- Hapus Barang: Menghapus item dari keranjang dengan mudah disertai konfirmasi.
- Ringkasan Biaya: Perhitungan total belanja dihitung otomatis.
- Tampilan Keranjang Kosong: Pesan dan tombol belanja saat keranjang masih belum terisi.

5. Pemesanan & Pembayaran (Checkout Flow)
- Alamat Pengiriman: Memilih alamat tersimpan atau membuat alamat baru lengkap dengan pencarian wilayah (Provinsi, Kota, Kecamatan).
- Kurir & Ongkos Kirim: Pilihan jasa pengiriman aktif dengan tarif ongkir yang dihitung akurat.
- Metode Pembayaran: Pilihan rekening transfer bank resmi toko.
- Instruksi Pembayaran: Menampilkan nomor rekening tujuan transfer dan tombol salin nomor rekening satu-klik.
- Unggah Bukti Bayar: Mengirim foto bukti transfer langsung dari kamera atau galeri HP.
- Detail Pesanan: Halaman rincian pesanan untuk melacak status transaksi.

6. Akun & Pengaturan (Settings)
- Halaman Akun: Tampilan kartu profil pengguna dan menu navigasi.
- Ganti Kata Sandi: Menu untuk memperbarui kata sandi lama ke kata sandi baru.
- Pengaturan Notifikasi: Mengatur preferensi pemberitahuan belanja dan promo.
- Kelola Alamat: Mengatur daftar alamat pengiriman yang tersimpan.
- Hapus Akun: Menu untuk privasi data pengguna jika ingin menutup akun.

7. Pusat Bantuan & Kebijakan Toko (Help Center & FAQ)
- Tanya Jawab (FAQ): Daftar jawaban pertanyaan yang sering diajukan seputar pemesanan dan pengiriman.
- Hubungi CS: Tombol cepat untuk menghubungi admin/CS lewat WhatsApp, Telepon, dan Email.
- Media Sosial Resmi: Tautan langsung ke Instagram, Facebook, dan Twitter toko.
- Syarat & Kebijakan Toko: Halaman Syarat & Ketentuan, Kebijakan Privasi, dan Ketentuan Pembatalan.

8. Pusat Notifikasi
- Notifikasi: Daftar pemberitahuan informasi promo dan pembaruan pesanan.

9. Identitas Aplikasi (Branding)
- Nama Aplikasi: ARBatik.
- Ikon Aplikasi: Ikon resmi ARBatik dengan desain logo baru yang proporsional di Android & iOS.
