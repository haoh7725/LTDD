import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Dành cho ứng viên: lọc theo category
  Stream<List<JobModel>> getJobs({String? category}) {
    Query query = _db.collection('jobs').orderBy('createdAt', descending: true);
    if (category != null && category.isNotEmpty) {
      query = _db
          .collection('jobs')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // Dành cho employer: chỉ lấy job của mình — query trực tiếp, không filter client
  Stream<List<JobModel>> getJobsByEmployer(String employerId) {
    return _db
        .collection('jobs')
        .where('employerId', isEqualTo: employerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<void> addJob(JobModel job) async {
    await _db.collection('jobs').add(job.toMap());
  }

  Future<void> deleteJob(String jobId) async {
    await _db.collection('jobs').doc(jobId).delete();
  }

  Future<void> applyJob(
      String jobId, String candidateId, String candidateName) async {
    // Kiểm tra đã ứng tuyển chưa
    final existing = await _db
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .where('candidateId', isEqualTo: candidateId)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Bạn đã ứng tuyển công việc này rồi');
    }
    await _db.collection('applications').add({
      'jobId': jobId,
      'candidateId': candidateId,
      'candidateName': candidateName,
      'status': 'pending',
      'appliedAt': DateTime.now(),
    });
  }

  Stream<List<Map<String, dynamic>>> getMyApplications(String candidateId) {
    return _db
        .collection('applications')
        .where('candidateId', isEqualTo: candidateId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Stream<List<Map<String, dynamic>>> getApplicationsByJob(String jobId) {
    return _db
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> updateApplicationStatus(
      String applicationId, String status) async {
    await _db
        .collection('applications')
        .doc(applicationId)
        .update({'status': status});
  }
}