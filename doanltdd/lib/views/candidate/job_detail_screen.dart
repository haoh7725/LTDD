import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../chat/chat_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final JobModel job;
  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final jobVM = context.read<JobViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(job.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(job.company, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const Divider(height: 24),
            _infoRow(Icons.location_on, job.location),
            _infoRow(Icons.attach_money, job.salary),
            _infoRow(Icons.category, job.category),
            const SizedBox(height: 16),
            const Text('Mô tả công việc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(job.description),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Ứng tuyển ngay'),
              onPressed: () async {
                await jobVM.applyJob(
                  job.id,
                  auth.userModel!.uid,
                  auth.userModel!.fullName,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ứng tuyển thành công!')),
                  );
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('Nhắn tin với nhà tuyển dụng'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserId: job.employerId,
                    otherUserName: job.company,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}