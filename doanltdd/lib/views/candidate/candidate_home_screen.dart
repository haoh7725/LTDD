import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../models/job_model.dart';
import 'job_detail_screen.dart';
import 'my_applications_screen.dart';
import '../chat/chat_list_screen.dart';

class CandidateHomeScreen extends StatefulWidget {
  const CandidateHomeScreen({super.key});

  @override
  State<CandidateHomeScreen> createState() => _CandidateHomeScreenState();
}

class _CandidateHomeScreenState extends State<CandidateHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final jobVM = context.watch<JobViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm việc làm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Tin nhắn',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.assignment),
            tooltip: 'Đơn ứng tuyển',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyApplicationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm việc làm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _keyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _keyword = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _keyword = v.toLowerCase()),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: jobVM.categories.length,
              itemBuilder: (_, i) {
                final cat = jobVM.categories[i];
                final selected = jobVM.selectedCategory == cat ||
                    (jobVM.selectedCategory.isEmpty && cat == 'Tất cả');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) => jobVM.setCategory(cat == 'Tất cả' ? '' : cat),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<JobModel>>(
              stream: jobVM.getJobs(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var jobs = snap.data ?? [];
                if (_keyword.isNotEmpty) {
                  jobs = jobs.where((j) =>
                      j.title.toLowerCase().contains(_keyword) ||
                      j.company.toLowerCase().contains(_keyword) ||
                      j.location.toLowerCase().contains(_keyword)).toList();
                }
                if (jobs.isEmpty) {
                  return const Center(child: Text('Không tìm thấy việc làm nào'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) => _JobCard(job: jobs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E88E5),
          child: Text(job.company.isNotEmpty ? job.company[0] : 'J',
              style: const TextStyle(color: Colors.white)),
        ),
        title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(job.company),
            Text('📍 ${job.location}'),
            Text('💰 ${job.salary}'),
          ],
        ),
        trailing: Chip(
          label: Text(job.category, style: const TextStyle(fontSize: 12)),
          backgroundColor: Colors.blue.shade50,
        ),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: job))),
      ),
    );
  }
}