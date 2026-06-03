import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CvService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Upload file CV lên Firebase Storage và lưu URL vào Firestore
  Future<String?> uploadCv(String uid, File file, String fileName) async {
    final ref = _storage.ref().child('cvs/$uid/$fileName');
    final task = await ref.putFile(file);
    final url = await task.ref.getDownloadURL();
    await _db.collection('users').doc(uid).update({
      'cvUrl': url,
      'cvName': fileName,
      'cvUploadedAt': FieldValue.serverTimestamp(),
    });
    return url;
  }

  /// Lấy thông tin CV hiện tại của user
  Future<Map<String, String?>> getCvInfo(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return {
      'cvUrl': doc.data()?['cvUrl'],
      'cvName': doc.data()?['cvName'],
    };
  }

  /// Xóa CV khỏi Storage và Firestore
  Future<void> deleteCv(String uid, String fileName) async {
    try {
      await _storage.ref().child('cvs/$uid/$fileName').delete();
    } catch (_) {}
    await _db.collection('users').doc(uid).update({
      'cvUrl': FieldValue.delete(),
      'cvName': FieldValue.delete(),
      'cvUploadedAt': FieldValue.delete(),
    });
  }
} 