import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/job_viewmodel.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final jobVM = context.read<JobViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đơn ứng tuyển của tôi')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: jobVM.getMyApplications(auth.userModel!.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = snap.data ?? [];
          if (apps.isEmpty) {
            return const Center(child: Text('Bạn chưa ứng tuyển công việc nào'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: apps.length,
            itemBuilder: (_, i) {
              final app = apps[i];
              final status = app['status'] ?? 'pending';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.work, color: Colors.blue),
                  title: Text(app['jobId'] ?? ''),
                  subtitle: Text('Ngày nộp: ${app['appliedAt']?.toDate().toString().substring(0, 10) ?? ''}'),
                  trailing: Chip(
                    label: Text(status == 'pending' ? 'Chờ duyệt' : status),
                    backgroundColor: status == 'pending' ? Colors.orange.shade100 : Colors.green.shade100,
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