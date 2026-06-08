import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'services/notification_service.dart'; 
import 'providers/review_provider.dart'; 
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  await NotificationService.initialize(); 

  // Ambil token dari penyimpanan lokal sebelum aplikasi menggambar UI
  final prefs = await SharedPreferences.getInstance();
  final String? savedToken = prefs.getString('token');

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ReviewProvider())],
      child: MyApp(token: savedToken),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String? token;
  const MyApp({super.key, this.token});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFirebase();
  }

  Future<void> _setupFirebase() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? fcmToken = await messaging.getToken();
    debugPrint("🔑 FCM TOKEN: $fcmToken");

    if (fcmToken != null) {
      try {
        // Ganti IP di bawah ini jika IP laptopmu berubah
        await http.post(
          Uri.parse('http://192.168.0.70/notifikasi-server/register_token.php'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({"user_id": "hunter_001", "fcm_token": fcmToken}),
        );
        debugPrint("✅ Token terdaftar di MySQL!");
      } catch (e) {
        debugPrint("❌ Gagal daftar token: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NemuRasa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: const Color(0xFF0058BC)),
      // Jika token ada, langsung ke Home. Jika tidak, ke Login.
      home: widget.token != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}