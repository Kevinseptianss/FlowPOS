import 'package:flutter/material.dart';

class AppPallete {
  static const Color primary = Color(
    0xFFC0392B,
  ); // Tombol utama, AppBar, aksen merah
  static const Color primaryDark = Color(
    0xFF922B21,
  ); // Pressed state, gradasi gelap
  static const Color secondary = Color(
    0xFFE67E22,
  ); // Aksen oranye, badge, highlight
  static const Color secondaryLight = Color(
    0xFFF39C12,
  ); // Hover state, gambar aktif
  static const Color surface = Color(0xFFFFFFFF); // Background card dan panel
  static const Color background = Color(0xFFF5F5F5); // Background halaman
  static const Color error = Color(0xFFE74C3C); // Pesan error, konfirmasi hapus
  static const Color onPrimary = Color(
    0xFFFFFFFF,
  ); // Teks di atas warna primary
  static const Color textPrimary = Color(0xFF2C3E50); // Teks utama
  static const Color textSecondary = Color(
    0xFF7F8C8D,
  ); // Teks sekunder / placeholder
  static const Color divider = Color(0xFFECEFF1);
  static const Color success = Color(0xFF27AE60); // Status berhasil, order paid
  static const Color warning = Color(0xFFF39C12); // Status pending, perhatian
}
