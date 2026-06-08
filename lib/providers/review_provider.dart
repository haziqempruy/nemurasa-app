import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReviewProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // FUNGSI BARU: Ini yang menghubungkan Flutter ke server notifikasi PHP 
  Future<void> triggerNotification(String placeName, String userName) async {
    try {
      // PENTING: Pastikan IP ini sama dengan IP server PHP kamu
      final response = await http.post(
        Uri.parse('http://192.168.0.70/notifikasi-server/new_review.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "place_name": placeName,
          "user_name": userName
        }),
      );
      debugPrint("Notifikasi Server Respon: ${response.statusCode}");
    } catch (e) {
      debugPrint("Error trigger notif: $e");
    }
  }

  void triggerRefresh() {
    notifyListeners(); 
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}