import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<JobModel>> getJobs({String? keyword, String? category}) {
    Query query = _db.collection('jobs');
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList());
  }

  Future<void> addJob(JobModel job) async {
    await _db.collection('jobs').add(job.toMap());
  }

  Future<void> applyJob(String jobId, String candidateId, String candidateName) async {
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
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }
    Stream<List<Map<String, dynamic>>> getApplicationsByJob(String jobId) {
    return _db
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> updateApplicationStatus(String applicationId, String status) async {
    await _db.collection('applications').doc(applicationId).update({'status': status});
  }
}

