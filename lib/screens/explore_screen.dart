import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // Import package baru

class ExploreScreen extends StatelessWidget {
  final Map<String, dynamic>? selectedPlace;

  const ExploreScreen({super.key, this.selectedPlace});

  // --- FUNGSI MEMBUKA GOOGLE MAPS ---
  Future<void> _bukaGoogleMaps(BuildContext context, double lat, double lng) async {
    // Format URL untuk membuka mode "Direction" (Rute) di Google Maps
    final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng";
    final Uri uri = Uri.parse(googleMapsUrl);

    try {
      // Buka URL di aplikasi eksternal (Google Maps)
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Gagal membuka peta.';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // --- BAGIAN ATAS: PETA INTERAKTIF ---
          SizedBox(
            height: 350, 
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: centerLocation,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.nemurasa', 
                ),
                MarkerLayer(
                  markers: [
                    if (selectedPlace != null)
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
          
          // --- BAGIAN BAWAH: INFO & TOMBOL RUTE ---
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
                  
                  if (selectedPlace != null) ...[
                    Text(
                      selectedPlace!['address'] ?? '-',
                      style: const TextStyle(color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    
                    // --- TOMBOL RUTE (DIRECTION) ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _bukaGoogleMaps(context, lat, lng),
                        icon: const Icon(Icons.directions),
                        label: const Text(
                          'Rute ke Sini',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0058BC), // Warna biru tema aplikasimu
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (selectedPlace == null)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Pilih kuliner dari Beranda untuk melihat rute.',
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