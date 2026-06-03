import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  // Wajib dipanggil sebelum mengecek data bawaan sistem (SharedPreferences)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Buka brankas untuk mengecek apakah ada token yang tersimpan
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  // Jalankan aplikasi dengan membawa status token tersebut
  runApp(MyApp(token: token));
}

class MyApp extends StatelessWidget {
  final String? token;
  const MyApp({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NemuRasa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0058BC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0058BC)),
      ),
      // Logika Penentuan Halaman Pertama:
      // Jika token tidak kosong (null), langsung ke Home. Jika kosong, arahkan ke Login.
      home: token != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}