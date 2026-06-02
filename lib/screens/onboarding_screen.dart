import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1000&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Gradient Overlay (Tanpa withOpacity agar terhindar dari warning)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color.fromRGBO(0, 88, 188, 0.9), // Primary 0xFF0058BC
                    Color.fromRGBO(0, 88, 188, 0.4),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // 3. Konten Teks & Tombol
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'NemuRasa',
                    style: TextStyle(
                      color: Color(0xFFADC6FF),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Jelajahi Rasa yang\nTak Terpetakan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Temukan kuliner autentik yang tersembunyi di setiap sudut nusantara.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromRGBO(173, 198, 255, 0.9), // 0xFFADC6FF
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Tombol Google
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthProvider>().signInWithGoogle();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(255, 255, 255, 0.9),
                      foregroundColor: const Color(0xFF414755),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.g_mobiledata, size: 32, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Sign in with Google',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Guest
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'MULAI SEBAGAI TAMU',
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}