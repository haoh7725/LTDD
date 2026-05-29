import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel(
      uid: cred.user!.uid,
      email: email,
      fullName: fullName,
      role: role,
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (doc.data()?['isBlocked'] == true) {
      await _auth.signOut();
      throw Exception('Tài khoản đã bị khóa');
    }
    return getUserData(cred.user!.uid);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}