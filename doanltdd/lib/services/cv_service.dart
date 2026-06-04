import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CvService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _cloudName = 'dfa3ihj5u';
  static const _uploadPreset = 'cv_unsigned'; // unsigned preset

  /// Upload CV bytes lên Cloudinary dùng unsigned preset
  /// URL trả về là public — không cần auth khi xem/download
  Future<String?> uploadCvBytes(
      String uid, Uint8List bytes, String fileName) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/raw/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'cvs/$uid'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
          'Cloudinary upload failed: ${json['error']?['message'] ?? body}');
    }

    final url = json['secure_url'] as String;
    final publicId = json['public_id'] as String;

    await _db.collection('users').doc(uid).update({
      'cvUrl': url,
      'cvName': fileName,
      'cvPath': publicId,
      'cvUploadedAt': FieldValue.serverTimestamp(),
    });

    return url;
  }

  /// Xóa CV khỏi Firestore (không xóa trên Cloudinary vì unsigned)
  Future<void> deleteCv(String uid, String cvPath) async {
    try {
      await _db.collection('users').doc(uid).update({
        'cvUrl': FieldValue.delete(),
        'cvName': FieldValue.delete(),
        'cvPath': FieldValue.delete(),
        'cvUploadedAt': FieldValue.delete(),
      });
    } catch (_) {}
  }

  /// Lấy thông tin CV hiện tại
  Future<Map<String, String?>> getCvInfo(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return {
      'cvUrl': doc.data()?['cvUrl'],
      'cvName': doc.data()?['cvName'],
      'cvPath': doc.data()?['cvPath'],
    };
  }
}