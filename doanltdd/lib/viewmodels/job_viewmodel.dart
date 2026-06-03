import 'package:flutter/material.dart';
import '../models/job_model.dart';
// FIX: Thêm `hide JobModel` để tránh conflict
// job_service.dart import job_model.dart nên Dart thấy JobModel từ 2 nguồn
import '../services/job_service.dart' hide JobModel;

class JobViewModel extends ChangeNotifier {
  final JobService _jobService = JobService();

  List<JobModel> jobs = [];
  bool isLoading = false;
  String selectedCategory = '';

  final List<String> categories = [
    'Tất cả', 'IT', 'Marketing', 'Kế toán', 'Kinh doanh', 'Thiết kế', 'Khác'
  ];

  Stream<List<JobModel>> getJobs() {
    return _jobService.getJobs(
      category: selectedCategory == 'Tất cả' ? '' : selectedCategory,
    );
  }

  Stream<List<JobModel>> getJobsByEmployer(String employerId) {
    return _jobService.getJobsByEmployer(employerId);
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  Future<void> addJob(JobModel job) async {
    await _jobService.addJob(job);
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    await _jobService.updateJob(jobId, data);
  }

  Future<void> deleteJob(String jobId) async {
    await _jobService.deleteJob(jobId);
  }

  Future<void> applyJob(
      String jobId, String candidateId, String candidateName) async {
    await _jobService.applyJob(jobId, candidateId, candidateName);
  }

  Stream<List<Map<String, dynamic>>> getMyApplications(String candidateId) {
    return _jobService.getMyApplications(candidateId);
  }

  Stream<List<Map<String, dynamic>>> getApplicationsByJob(String jobId) {
    return _jobService.getApplicationsByJob(jobId);
  }

  Future<void> updateApplicationStatus(
      String applicationId, String status) async {
    await _jobService.updateApplicationStatus(applicationId, status);
  }
}