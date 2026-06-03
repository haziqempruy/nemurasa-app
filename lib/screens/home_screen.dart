import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'detail_screen.dart';  

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // Variabel untuk menampung data dari Laravel
  List<dynamic> _places = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaces(); // Panggil fungsi ambil data saat layar pertama kali dibuka
  }

  // Fungsi Asynchronous untuk mengambil API (Bagian dari rubrik 35%)
  Future<void> _fetchPlaces() async {
    // IP fisik HP kamu
    const String apiUrl = 'http://192.168.0.77:8000/api/places'; 

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _places = data['data']; // Masukkan array dari Laravel ke variabel Flutter
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
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userName = user?.displayName?.split(' ')[0] ?? 'Tamu';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, $userName! 👋',
              style: const TextStyle(
                color: Color(0xFF414755),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Mau eksplor rasa apa hari ini?',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Keluar',
            onPressed: () {
              context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: _selectedIndex == 0 
          ? _buildHomeContent() 
          : const Center(child: Text('Halaman Eksplor/Profil Belum Tersedia')),
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
    // Tampilkan animasi loading saat data masih ditarik dari Laravel
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Tampilkan pesan jika database kosong
    if (_places.isEmpty) {
      return const Center(child: Text('Belum ada data kuliner legendaris.'));
    }

    // Bangun daftar UI (List) sesuai dengan data JSON
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        
        // --- BAGIAN INI YANG DITAMBAHKAN (InkWell untuk navigasi) ---
        return InkWell(
          onTap: () {
            // Berpindah ke DetailScreen sambil membawa data 'place'
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
                // Gambar dari Database
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
                            // Label Premium untuk Sponsored Discovery
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
                            // Nama Warung dari Database
                            Text(
                              place['name'] ?? 'Tanpa Nama',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                // Alamat dari Database
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