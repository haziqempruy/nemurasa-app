import 'package:flutter/material.dart';

class ReviewProvider extends ChangeNotifier {
  // Variabel penanda apakah sedang ada aktivitas memuat data
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fungsi sakti untuk memberitahu seluruh aplikasi bahwa data berubah
  void triggerRefresh() {
    // notifyListeners() adalah kunci utama Provider. 
    // Ini yang akan menyuruh layar-layar untuk me-refresh dirinya (me-rebuild UI)
    notifyListeners(); 
  }

  // Opsional: kalau mau ada efek loading saat refresh
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}