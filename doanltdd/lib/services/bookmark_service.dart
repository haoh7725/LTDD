import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarkService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<String>> getBookmarkedJobIds(String uid) {
    return _db
        .collection('bookmarks')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists
            ? List<String>.from(doc.data()?['jobIds'] ?? [])
            : <String>[]);
  }

  Future<void> toggleBookmark(String uid, String jobId) async {
    final ref = _db.collection('bookmarks').doc(uid);
    final doc = await ref.get();
    final List<String> current =
        doc.exists ? List<String>.from(doc.data()?['jobIds'] ?? []) : [];
    if (current.contains(jobId)) {
      current.remove(jobId);
    } else {
      current.add(jobId);
    }
    await ref.set({'jobIds': current});
  }

  Future<bool> isBookmarked(String uid, String jobId) async {
    final doc = await _db.collection('bookmarks').doc(uid).get();
    if (!doc.exists) return false;
    return List<String>.from(doc.data()?['jobIds'] ?? []).contains(jobId);
  }
}