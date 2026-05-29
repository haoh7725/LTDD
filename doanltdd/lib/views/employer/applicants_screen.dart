import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/job_viewmodel.dart';

class ApplicantsScreen extends StatelessWidget {
  final String jobId;
  final String jobTitle;
  const ApplicantsScreen({super.key, required this.jobId, required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    final jobVM = context.read<JobViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text('Ứng viên - $jobTitle')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: jobVM.getApplicationsByJob(jobId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final apps = snap.data!;
          if (apps.isEmpty) return const Center(child: Text('Chưa có ứng viên nào'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: apps.length,
            itemBuilder: (_, i) {
              final app = apps[i];
              final status = app['status'] ?? 'pending';
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(app['candidateName'] ?? ''),
                  subtitle: Text('Ngày nộp: ${app['appliedAt']?.toDate().toString().substring(0, 10) ?? ''}'),
                  trailing: status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => jobVM.updateApplicationStatus(app['id'], 'accepted'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => jobVM.updateApplicationStatus(app['id'], 'rejected'),
                            ),
                          ],
                        )
                      : Chip(
                          label: Text(status == 'accepted' ? 'Đã duyệt' : 'Từ chối'),
                          backgroundColor: status == 'accepted' ? Colors.green.shade100 : Colors.red.shade100,
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}