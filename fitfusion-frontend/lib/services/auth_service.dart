import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitfusion/models/user_model.dart';
import 'package:fitfusion/services/api_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '1001958185957-dkp35gp6vgoroiojju4mosu33v0f3pmr.apps.googleusercontent.com',
  );

  UserModel? _userModel;
  bool _isLoading = true;

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await refreshProfile();
      } else {
        _userModel = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  User? get currentUser => _auth.currentUser;
  UserModel? get userModel => _userModel;
  bool get isLoggedIn => currentUser != null;
  bool get isTrainer => _userModel?.role == 'trainer';
  bool get isAdmin => _userModel?.role == 'admin';
  bool get isLoading => _isLoading;

  Future<void> refreshProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.instance.getUserProfile();
      if (response.success && response.data != null) {
        _userModel = UserModel.fromJson(response.data!['user']);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      await refreshProfile();
      return userCredential;
    } catch (e) {
      if (kDebugMode) print('Google Sign In Error: $e');
      rethrow;
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await refreshProfile();
    return cred;
  }

  Future<UserCredential> signUp(String email, String password, String name) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user?.updateDisplayName(name);
    // Profile will be created via subsequent setup pages or API calls
    return cred;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _userModel = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_uid');
    notifyListeners();
  }

  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }
}
