import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan ini

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); 
  
  User? _user;
  User? get user => _user;

 
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  AuthProvider() {
    _checkLoginStatus();  
    
    _auth.authStateChanges().listen((User? newUser) {
      _user = newUser;
      notifyListeners();
    });
  }

  
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    
    if (!isLoggedIn) {
      _isLoading = false;
      notifyListeners();
    } else {
        
       await Future.delayed(const Duration(milliseconds: 500));
       _isLoading = false;
       notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;
      
      if (idToken == null) {
        debugPrint("Error: ID Token tidak ditemukan.");
        return;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      await _auth.signInWithCredential(credential);
      
      // Simpan status login ke SharedPreferences 
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      
      debugPrint("Login Firebase Sukses! Nama: ${_auth.currentUser?.displayName}");
      
    } catch (e) {
      debugPrint("Error login: $e");
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    
    // Hapus status login dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }
}