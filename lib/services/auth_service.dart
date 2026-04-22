import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('Грешка при вход: ${e.code}');
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  static Future<User?> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('Грешка при регистрация: ${e.code}');
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}