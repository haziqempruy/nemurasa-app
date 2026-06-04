import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ExploreScreen extends StatelessWidget {
  final Map<String, dynamic>? selectedPlace;

  const ExploreScreen({super.key, this.selectedPlace});

  @override
  Widget build(BuildContext context) {
    // Mengecek apakah Laravel mengirimkan data 'latitude' dan 'longitude'
    // Jika tidak ada data, peta otomatis terpusat di Indramayu
    final double lat = selectedPlace != null && selectedPlace!['latitude'] != null 
        ? double.parse(selectedPlace!['latitude'].toString()) 
        : -6.3276326; 
        
    final double lng = selectedPlace != null && selectedPlace!['longitude'] != null 
        ? double.parse(selectedPlace!['longitude'].toString()) 
        : 108.3242221;

    final LatLng centerLocation = LatLng(lat, lng);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: Column(
        children: [
          // --- BAGIAN ATAS: PETA INTERAKTIF ASLI ---
          SizedBox(
            height: 350, 
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: centerLocation,
                initialZoom: 15.0, // Level zoom awal (bisa di-scroll pakai jari nanti)
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.nemurasa', 
                ),
                MarkerLayer(
                  markers: [
                    if (selectedPlace != null) // Hanya munculkan pin merah jika diklik dari Detail
                      Marker(
                        point: centerLocation,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 45,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // --- BAGIAN BAWAH: INFO TEMPAT ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedPlace != null 
                        ? 'Lokasi: ${selectedPlace!['name']}' 
                        : 'Eksplor Sekitarmu',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF414755)),
                  ),
                  const SizedBox(height: 8),
                  if (selectedPlace != null)
                    Text(
                      selectedPlace!['address'] ?? '-',
                      style: const TextStyle(color: Colors.grey, height: 1.5),
                    ),
                  const SizedBox(height: 20),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Daftar kuliner terdekat akan muncul di sini nanti.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}