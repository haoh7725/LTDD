import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// FIX #4: Chỉ import dart:io khi không phải Web
// dart:io File không tồn tại trên Flutter Web
import 'dart:io' if (dart.library.html) 'dart:html' as io;

class CvService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Upload CV - hỗ trợ cả Mobile (File) và Web (Uint8List)
  Future<String?> uploadCvBytes(
      String uid, Uint8List bytes, String fileName) async {
    final ref = _storage.ref().child('cvs/$uid/$fileName');
    final metadata = SettableMetadata(
      contentType: fileName.endsWith('.pdf') ? 'application/pdf' : 'application/octet-stream',
    );
    final task = await ref.putData(bytes, metadata);
    final url = await task.ref.getDownloadURL();
    await _db.collection('users').doc(uid).update({
      'cvUrl': url,
      'cvName': fileName,
      'cvUploadedAt': FieldValue.serverTimestamp(),
    });
    return url;
  }

  /// Upload CV từ File path (chỉ dùng trên Mobile/Desktop)
  Future<String?> uploadCv(String uid, dynamic file, String fileName) async {
    if (kIsWeb) {
      throw UnsupportedError(
          'Dùng uploadCvBytes() trên Web. Truyền Uint8List thay vì File.');
    }
    // Chỉ compile path này khi không phải Web
    final ref = _storage.ref().child('cvs/$uid/$fileName');
    final task = await ref.putFile(file as io.File);
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