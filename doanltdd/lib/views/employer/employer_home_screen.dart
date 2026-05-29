import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../models/job_model.dart';
import 'applicants_screen.dart';
import '../chat/chat_list_screen.dart';

class EmployerHomeScreen extends StatelessWidget {
  const EmployerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final jobVM = context.watch<JobViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhà tuyển dụng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Tin nhắn',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: StreamBuilder<List<JobModel>>(
        stream: jobVM.getJobs(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = (snap.data ?? [])
              .where((j) => j.employerId == auth.userModel?.uid)
              .toList();
          if (jobs.isEmpty) {
            return const Center(child: Text('Chưa có tin tuyển dụng nào'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (_, i) => Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Text(jobs[i].title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${jobs[i].location} • ${jobs[i].salary}'),
                trailing: Chip(label: Text(jobs[i].category)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplicantsScreen(
                      jobId: jobs[i].id,
                      jobTitle: jobs[i].title,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Đăng tin'),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _PostJobSheet(),
        ),
      ),
    );
  }
}

class _PostJobSheet extends StatefulWidget {
  const _PostJobSheet();

  @override
  State<_PostJobSheet> createState() => _PostJobSheetState();
}

class _PostJobSheetState extends State<_PostJobSheet> {
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'IT';
  bool _loading = false;

  final List<String> _categories = [
    'IT', 'Marketing', 'Kế toán', 'Kinh doanh', 'Thiết kế', 'Khác'
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _locationCtrl.dispose();
    _salaryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _companyCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final auth = context.read<AuthViewModel>();
    final jobVM = context.read<JobViewModel>();
    await jobVM.addJob(JobModel(
      id: '',
      title: _titleCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      salary: _salaryCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      employerId: auth.userModel!.uid,
      createdAt: DateTime.now(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Đăng tin tuyển dụng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Tên vị trí *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _companyCtrl,
              decoration: const InputDecoration(labelText: 'Tên công ty *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Địa điểm'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _salaryCtrl,
              decoration: const InputDecoration(labelText: 'Mức lương'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Ngành nghề'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả công việc'),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Đăng tin'),
                  ),
          ],
        ),
      ),
    );
  }
}