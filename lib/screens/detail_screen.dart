import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:provider/provider.dart'; // Tambahan Import Provider
import '../providers/review_provider.dart'; // Tambahan Import ReviewProvider

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
  String _selectedFilter = 'Terbaru'; 
  int _currentImageIndex = 0;

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
    const String apiUrl = 'http://192.168.0.70:8000/api/reviews';

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('user_id') ?? 1; 
      final currentUserName = prefs.getString('user_name') ?? 'Hunter (Saya)';
      final currentUserAvatar = prefs.getString('avatar_url'); 

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
          setState(() {
            if (widget.place['reviews'] == null) {
              widget.place['reviews'] = [];
            }

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
            _selectedFilter = 'Terbaru'; 
          });
          
          _reviewController.clear();

          // --- TRIGGER NOTIFIKASI FCM DI SINI ---
          await Provider.of<ReviewProvider>(context, listen: false)
              .triggerNotification(widget.place['name'] ?? 'Tempat Kuliner', currentUserName);

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

    List<dynamic> sortedReviews = List.from(place['reviews'] ?? []);
    
    sortedReviews.sort((a, b) {
      if (_selectedFilter == 'Terbaru') {
        DateTime dateA = DateTime.tryParse(a['created_at'].toString()) ?? DateTime.now();
        DateTime dateB = DateTime.tryParse(b['created_at'].toString()) ?? DateTime.now();
        return dateB.compareTo(dateA); 
      } else if (_selectedFilter == 'Tertinggi') {
        int ratingA = a['rating_keaslian'] ?? 0;
        int ratingB = b['rating_keaslian'] ?? 0;
        return ratingB.compareTo(ratingA); 
      } else { 
        int ratingA = a['rating_keaslian'] ?? 0;
        int ratingB = b['rating_keaslian'] ?? 0;
        return ratingA.compareTo(ratingB); 
      }
    });

    List<String> imageUrls = [];
    imageUrls.add(place['main_image'] ?? 'https://via.placeholder.com/600x400');
    if (place['foto_depan'] != null && place['foto_depan'].toString().isNotEmpty) {
      imageUrls.add(place['foto_depan']);
    }
    if (place['foto_menu'] != null && place['foto_menu'].toString().isNotEmpty) {
      imageUrls.add(place['foto_menu']);
    }

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
              centerTitle: false, 
              titlePadding: const EdgeInsets.only(left: 48.0, bottom: 16.0), 
              title: Text(
                place['name'] ?? 'Detail Kuliner',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: imageUrls.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey, child: const Icon(Icons.broken_image, size: 50, color: Colors.white)),
                      );
                    },
                  ),
                  IgnorePointer(
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  if (imageUrls.length > 1)
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imageUrls.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                height: 8.0,
                                width: _currentImageIndex == index ? 24.0 : 8.0,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index ? Colors.white : Colors.white54,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                            initialIndex: 1, 
                            selectedPlace: place, 
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
                              "${place['address'] ?? '-'} (Lihat Peta)",
                              style: const TextStyle(
                                color: Color(0xFF0058BC), 
                                fontSize: 14, 
                                height: 1.5,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline, 
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ulasan Hunter Lainnya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFilter,
                            icon: const Icon(Icons.filter_list, size: 18, color: Color(0xFF0058BC)),
                            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedFilter = newValue; 
                                });
                              }
                            },
                            items: <String>['Terbaru', 'Tertinggi', 'Terendah']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (sortedReviews.isNotEmpty)
                    ...sortedReviews.map<Widget>((review) {
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
                            ClipOval(
                              child: Image.network(
                                avatarUrl ?? 'https://ui-avatars.com/api/?name=$reviewerName&background=0058BC&color=fff',
                                width: 44, 
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.network(
                                    'https://ui-avatars.com/api/?name=$reviewerName&background=0058BC&color=fff',
                                    width: 44,
                                    height: 44,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            
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