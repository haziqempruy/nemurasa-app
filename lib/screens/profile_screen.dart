import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahan import brankas

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  
  // Kosongkan nilai default-nya agar memuat dari brankas
  String _userName = 'Memuat...';
  String? _avatarUrl;

  // Sesuaikan dengan IP laptopmu
  final String _baseUrl = 'http://192.168.0.77:8000/api';
  
  // Ubah dari 'final int = 1' menjadi variabel dinamis
  int _currentUserId = 0; 

  @override
  void initState() {
    super.initState();
    _loadUserSession(); // Panggil fungsi pembongkar brankas
  }

  // --- FUNGSI BARU: Ambil Sesi User ---
  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Ambil data yang disimpan saat Login/Register tadi
      _currentUserId = prefs.getInt('user_id') ?? 0;
      _userName = prefs.getString('user_name') ?? 'Hunter';
    });
    
    // Setelah ID didapatkan, baru tembak API Laravel
    if (_currentUserId != 0) {
      _fetchUserInfo();
      _fetchMyReviews();
    } else {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI MANAJEMEN USER & AVATAR ---

  // Mengambil data User beserta URL fotonya
  Future<void> _fetchUserInfo() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users/$_currentUserId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userName = data['data']['name'];
          _avatarUrl = data['avatar_url']; // URL dari Laravel storage
        });
      }
    } catch (e) {
      debugPrint("Error ambil data user: $e");
    }
  }

  // Memilih gambar dari Galeri dan langsung mengunggahnya
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Kompres ukuran agar tidak terlalu besar
    );

    if (pickedFile != null) {
      _uploadAvatar(File(pickedFile.path));
    }
  }

  // Mengirim file gambar ke Laravel (Multipart Request)
  Future<void> _uploadAvatar(File imageFile) async {
    setState(() => _isLoading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/users/$_currentUserId/avatar'));
      request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
      
      var response = await request.send();
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil diperbarui!')));
        }
        _fetchUserInfo(); // Refresh gambar
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengunggah foto.'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      debugPrint("Error upload foto: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Menghapus foto profil
  Future<void> _deleteAvatarProcess() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/users/$_currentUserId/avatar'));
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil dihapus!')));
        }
        _fetchUserInfo(); // Refresh gambar menjadi default
      }
    } catch (e) {
      debugPrint("Error hapus foto: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Menampilkan Pop-up Pilihan (Upload atau Hapus)
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0058BC)),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage();
                },
              ),
              if (_avatarUrl != null) // Tombol hapus hanya muncul jika ada fotonya
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteAvatarProcess();
                  },
                ),
            ],
          ),
        );
      }
    );
  }

  // --- FUNGSI RIWAYAT ULASAN ---

  Future<void> _fetchMyReviews() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/reviews/user/$_currentUserId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _reviews = data['data'];
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReview(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ulasan?'),
        content: const Text('Ulasan yang dihapus tidak bisa dikembalikan lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(Uri.parse('$_baseUrl/reviews/$id'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ulasan berhasil dihapus')));
        _fetchMyReviews(); 
      }
    } catch (e) {
      debugPrint("Error hapus: $e");
    }
  }

  void _showEditDialog(Map<String, dynamic> review) {
    final TextEditingController editController = TextEditingController(text: review['review_text']);
    int tempRating = review['rating_keaslian'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit Ulasan', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          index < tempRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setStateDialog(() => tempRating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: editController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'Perbarui ulasanmu...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Batal', style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); 
                    await _updateReview(review['id'], tempRating, editController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0058BC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      }
    );
  }

  Future<void> _updateReview(int id, int rating, String text) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/reviews/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rating_keaslian': rating, 'review_text': text}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ulasan berhasil diperbarui')));
        _fetchMyReviews(); 
      }
    } catch (e) {
      debugPrint("Error update: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER PROFIL ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12, 
                    blurRadius: 10, 
                    offset: Offset(0, 4)
                  )
                ]
              ),
              child: Row(
                children: [
                  // Avatar Interaktif (Bisa Ditekan)
                  GestureDetector(
                    onTap: _showAvatarOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _avatarUrl != null 
                              ? NetworkImage(_avatarUrl!) 
                              // URL Avatar dibuat dinamis mengikuti _userName
                              : NetworkImage('https://ui-avatars.com/api/?name=$_userName&background=0058BC&color=fff&size=120') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0058BC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // Informasi Teks
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName, 
                          style: const TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF414755)
                          )
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'HUNTER', 
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.white,
                              letterSpacing: 1.2
                            )
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // --- JUDUL BAGIAN BAWAH ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Riwayat Ulasan', 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF414755)
                  )
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // --- KONTEN LIST VIEW ---
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                  ? const Center(child: Text('Kamu belum memberikan ulasan apapun.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200)
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // 1. Bungkus Text dengan Expanded agar tidak egois memakan tempat
    Expanded(
      child: Text(
        review['place'] != null ? review['place']['name'] : 'Kuliner',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 1, // Batasi maksimal 1 baris
        overflow: TextOverflow.ellipsis, // Tambahkan titik-titik (...) jika teks kepanjangan
      ),
    ),
    
    const SizedBox(width: 8), // Jarak napas antara teks dan bintang
    
    // 2. Jejeran Bintang
    Row(
      children: List.generate(
        5, 
        (starIndex) => Icon(
          starIndex < review['rating_keaslian'] ? Icons.star : Icons.star_border,
          color: Colors.amber, size: 16,
        )
      ),
    ),
  ],
),
                                const SizedBox(height: 12),
                                Text(
                                  review['review_text'] ?? '',
                                  style: const TextStyle(color: Colors.black87, height: 1.5),
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showEditDialog(review),
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      label: const Text('Edit'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _deleteReview(review['id']),
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}