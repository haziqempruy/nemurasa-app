import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 

// --- TAMBAHAN IMPORT PROVIDER ---
import 'package:provider/provider.dart'; 
import '../providers/review_provider.dart'; 
// --------------------------------

import 'detail_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart'; 
import 'explore_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex; // Tambahkan ini
  final Map<String, dynamic>? selectedPlace; // Tambahkan ini

  // Beri nilai default index 0 (Beranda) agar jika dibuka biasa tidak error
  const HomeScreen({super.key, this.initialIndex = 0, this.selectedPlace});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex; // Ubah menjadi late
  
  List<dynamic> _places = [];
  bool _isLoading = true;
  String _userName = 'Tamu'; 

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Set index sesuai titipan
    
    _loadUserSession(); 
    _fetchPlaces(); 
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewProvider>(context, listen: false).addListener(() {
        if (mounted) _fetchPlaces(); 
      });
    });
  }
  // --- FUNGSI BARU: Ambil Nama dari Brankas ---
  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Ambil nama dari brankas, jika kosong default ke 'Hunter'
      String fullName = prefs.getString('user_name') ?? 'Hunter';
      // Potong agar yang tampil hanya kata pertama (nama panggilan)
      _userName = fullName.split(' ')[0];
    });
  }

// --- FUNGSI 1: Proses Eksekusi Logout ---
  Future<void> _executeLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus token dan semua data di brankas
    
    if (mounted) {
      // Lempar kembali ke halaman Login dan hapus histori rute
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- FUNGSI 2: Menampilkan Pop-up Konfirmasi ---
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Apakah kamu yakin ingin keluar dari NemuRasa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Tutup dialog jika Batal
              child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog dulu
                _executeLogout(); // Baru jalankan proses logout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  // Fungsi Asynchronous untuk mengambil API
  Future<void> _fetchPlaces() async {
    // Pastikan IP ini selalu sama dengan IP yang sedang aktif ya!
    const String apiUrl = 'http://192.168.0.136:8000/api/places'; 

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _places = data['data']; 
          _isLoading = false;
        });
      } else {
        debugPrint("Gagal mengambil data. Status code: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

 void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    
    if (index == 0) {
      _fetchPlaces(); 
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/nemurasa-logo.png', // Logo kamu aman di sini
              height: 36, 
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12), 
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $_userName! 👋', // Menggunakan variabel state yang baru
                    style: const TextStyle(
                      color: Color(0xFF414755),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, 
                  ),
                  const Text(
                    'Mau eksplor rasa apa hari ini?',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Keluar',
            onPressed: _showLogoutConfirmation, 
          ),
        ],
      ),
body: _selectedIndex == 0 
       ? _buildHomeContent() 
       : _selectedIndex == 1 // Jika index 1, panggil ExploreScreen
           ? ExploreScreen(selectedPlace: widget.selectedPlace) 
           : const ProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF0058BC),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Eksplor'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_places.isEmpty) {
      return const Center(child: Text('Belum ada data kuliner legendaris.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(place: place),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  place['main_image'] ?? 'https://via.placeholder.com/600x400',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      Container(height: 180, color: Colors.grey, child: const Icon(Icons.broken_image)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (place['is_premium'] == 1)
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'SPONSORED',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            Text(
                              place['name'] ?? 'Tanpa Nama',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    place['address'] ?? '-', 
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}