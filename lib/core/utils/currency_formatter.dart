/// Helper formatter mata uang Rupiah (contoh: 150000 -> "Rp 150.000")
String formatRupiah(num amount) {
  final int val = amount.round();
  final String str = val.toString();
  final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  final result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  return 'Rp $result';
}
