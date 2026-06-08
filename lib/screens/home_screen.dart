import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/review_provider.dart'; 
import 'explore_screen.dart';
import 'profile_screen.dart';
import 'detail_screen.dart'; 
import 'login_screen.dart'; 

class HomeScreen extends StatefulWidget {
  final int initialIndex; 
  final Map<String, dynamic>? selectedPlace; 

  const HomeScreen({super.key, this.initialIndex = 0, this.selectedPlace});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex; 
  List<dynamic> _places = [];
  bool _isLoading = true;
  String _userName = 'Tamu'; 

  // ⚠️ PASTIKAN IP INI SESUAI DENGAN IP LAPTOPMU SAAT INI
  final String _baseUrl = 'http://192.168.0.70:8000/api'; 

  // --- VARIABEL UNTUK SEARCH & FILTER ---
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Makanan Berat', 'Cemilan', 'Minuman'];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; 
    
    _loadUserSession(); 
    _fetchPlaces(); 
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewProvider>(context, listen: false).addListener(() {
        if (mounted) _fetchPlaces(); 
      });
    });
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Hunter';
    });
  }

  Future<void> _fetchPlaces() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/places'));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            final decodedData = json.decode(response.body);
            
            // LOGIKA PINTAR PEMBACA JSON YANG SUDAH DIPERBAIKI
            if (decodedData is List) {
              _places = decodedData; 
            } else if (decodedData is Map && decodedData.containsKey('data')) {
              _places = decodedData['data']; 
            } else {
              _places = []; 
            }
            
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- FUNGSI LOGOUT UTAMA ---
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, 
      );
    }
  }

  // --- FUNGSI POP-UP KONFIRMASI LOGOUT ---
  Future<void> _showLogoutConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Memaksa user untuk menekan salah satu tombol
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Konfirmasi Keluar', 
            style: TextStyle(fontWeight: FontWeight.bold)
          ),
          content: const Text('Apakah kamu yakin ingin keluar dari aplikasi NemuRasa?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog, batalkan logout
              },
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog dulu
                _logout(); // Baru jalankan fungsi logout yang asli
              },
              child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  List<dynamic> get _filteredPlaces {
    return _places.where((place) {
      final name = place['name']?.toString().toLowerCase() ?? '';
      final category = place['category']?.toString() ?? 'Makanan Berat'; 
      
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
        scrolledUnderElevation: 0, 
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset('assets/images/nemurasa-logo.png'),
            ),
            const SizedBox(width: 12),
            const Text(
              'NemuRasa',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF0058BC),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // --- TOMBOL NOTIFIKASI UNTUK TUBES ---
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF0058BC)),
            tooltip: 'Notifikasi',
            onPressed: () {
              // TODO: Masukkan logika pemanggilan Notifikasi (Local/FCM) di sini nanti
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu Notifikasi belum diimplementasikan.')),
              );
            },
          ),
          // --- TOMBOL LOGOUT ---
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Keluar',
            onPressed: _showLogoutConfirmation, // <-- Memanggil Pop-up Konfirmasi
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _selectedIndex == 0 
          ? _buildHomeContent() 
          : _selectedIndex == 1 
              ? ExploreScreen(selectedPlace: widget.selectedPlace) 
              : const ProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF0058BC),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Eksplor'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final placesToShow = _filteredPlaces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
          child: Text(
            'Mau hunting kuliner apa hari ini, $_userName?',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari nama kuliner...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0058BC),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0058BC) : Colors.grey.shade300,
                    ),
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text('Rekomendasi NemuRasa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : placesToShow.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada kuliner yang cocok dengan "$_searchQuery"\natau kategori "$_selectedCategory".',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: placesToShow.length,
                      itemBuilder: (context, index) {
                        final place = placesToShow[index];
                        
                        double rating = 5.0;
                        if (place['reviews'] != null && place['reviews'].length > 0) {
                          double total = 0;
                          for (var r in place['reviews']) {
                            total += (r['rating_keaslian'] ?? 5);
                          }
                          rating = total / place['reviews'].length;
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailScreen(place: place),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(
                                    place['main_image'] ?? 'https://via.placeholder.com/600x400',
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(height: 150, color: Colors.grey, child: const Icon(Icons.broken_image)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place['name'] ?? 'Tanpa Nama',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              place['category'] ?? 'Makanan Berat', 
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF0058BC), fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              place['address'] ?? '-',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}