import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 
import 'home_screen.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> place;

  const DetailScreen({super.key, required this.place});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false; 

  String formatTanggal(dynamic dateData) {
    if (dateData == null || dateData.toString().isEmpty) return '';
    try {
      DateTime parsedDate = DateTime.parse(dateData.toString()).toLocal();
      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = parsedDate.month.toString().padLeft(2, '0');
      String year = parsedDate.year.toString();
      String hour = parsedDate.hour.toString().padLeft(2, '0');
      String minute = parsedDate.minute.toString().padLeft(2, '0');
      
      return '$day-$month-$year $hour:$minute';
    } catch (e) {
      return ''; 
    }
  }

  Future<void> _submitReview() async {
    // Pastikan IP ini sesuai dengan komputermu ya
    const String apiUrl = 'http://192.168.0.136:8000/api/reviews';

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('user_id') ?? 1; 
      final currentUserName = prefs.getString('user_name') ?? 'Hunter (Saya)';
      final currentUserAvatar = prefs.getString('avatar_url'); // Opsional jika kamu menyimpan URL avatar di brankas

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'place_id': widget.place['id'],
          'user_id': currentUserId, 
          'rating_keaslian': _selectedRating,
          'review_text': _reviewController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          // --- OPTIMISTIC UI UPDATE ---
          setState(() {
            if (widget.place['reviews'] == null) {
              widget.place['reviews'] = [];
            }

            // Sisipkan ke paling atas dengan format yang mendukung Avatar
            widget.place['reviews'].insert(0, {
              'user': {
                'name': currentUserName,
                'avatar_url': currentUserAvatar,
              },
              'created_at': DateTime.now().toIso8601String(),
              'rating_keaslian': _selectedRating,
              'review_text': _reviewController.text,
            });
            
            _selectedRating = 5;
          });
          
          _reviewController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ulasan Keaslian Rasa berhasil dikirim!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim ulasan (Status: ${response.statusCode})'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan jaringan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF0058BC),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                place['name'] ?? 'Detail Kuliner',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              background: Image.network(
                place['main_image'] ?? 'https://via.placeholder.com/600x400',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey, child: const Icon(Icons.broken_image)),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          place['name'] ?? 'Tanpa Nama',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (place['is_premium'] == 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SPONSORED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 12),
                 InkWell(
  onTap: () {
    // Saat alamat diklik, lemparkan user kembali ke HomeScreen
    // TAPI paksa buka tab Eksplor (index 1) dan bawa data tempatnya!
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          initialIndex: 1, 
          selectedPlace: place, // Titipkan data kuliner ini
        ),
      ),
      (route) => false,
    );
  },
  borderRadius: BorderRadius.circular(8),
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "${place['address'] ?? '-'} (Lihat Peta)", // Tambah hint teks
            style: const TextStyle(
              color: Color(0xFF0058BC), // Warna biru layaknya link aktif
              fontSize: 14, 
              height: 1.5,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline, // Beri garis bawah
            ),
          ),
        ),
      ],
    ),
  ),
),
                  const SizedBox(height: 24),
                  
                  const Text('Cerita Rasa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    place['description'] ?? 'Belum ada cerita untuk tempat ini.',
                    style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF414755)),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // --- FORM KIRIM ULASAN ---
                  const Text('Beri Penilaian "Keaslian Rasa"', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  
                  TextField(
                    controller: _reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ceritakan pengalamanmu makan di sini...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0058BC),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Kirim Ulasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // --- DAFTAR ULASAN DENGAN DESAIN ALA MEDSOS ---
                  const Text('Ulasan Hunter Lainnya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  if (place['reviews'] != null && place['reviews'].isNotEmpty)
                    ...place['reviews'].map<Widget>((review) {
                      
                      // Ambil nama user dan URL avatar (kalau ada)
                      String reviewerName = review['user'] != null ? review['user']['name'] : 'Hunter Anonim';
                      String? avatarUrl = review['user'] != null ? review['user']['avatar_url'] : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. BAGIAN FOTO PROFIL (AVATAR)
                          // 1. BAGIAN FOTO PROFIL (AVATAR)
                            ClipOval(
                              child: Image.network(
                                avatarUrl ?? 'https://ui-avatars.com/api/?name=$reviewerName&background=0058BC&color=fff',
                                width: 44, // Lebar sama dengan radius 22 x 2
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // PERISAI: Jika gambar 404 (zombie/terhapus), 
                                  // otomatis ganti ke gambar inisial UI-Avatars, aplikasi aman dari layar merah!
                                  return Image.network(
                                    'https://ui-avatars.com/api/?name=$reviewerName&background=0058BC&color=fff',
                                    width: 44,
                                    height: 44,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // 2. BAGIAN KONTEN KOMENTAR
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          reviewerName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        formatTanggal(review['created_at']),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (index) => Icon(
                                        index < (review['rating_keaslian'] ?? 5) ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    review['review_text'] ?? '-',
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF414755), height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                  else
                    const Center(
                      child: Text(
                        'Belum ada ulasan untuk tempat ini.\nJadilah Hunter pertama yang mengulas!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}