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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhà tuyển dụng',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(auth.userModel?.fullName ?? '',  // fixed: removed unnecessary string interpolation
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
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
        stream: jobVM.getJobsByEmployer(auth.userModel!.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = snap.data ?? [];
          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Chưa có tin tuyển dụng nào',
                      style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text('Nhấn nút + bên dưới để đăng tin',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (_, i) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    jobs[i].company.isNotEmpty
                        ? jobs[i].company[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(jobs[i].title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${jobs[i].location} • ${jobs[i].salary}'),
                    Text(jobs[i].category,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: Text(
                                'Bạn có chắc muốn xóa tin "${jobs[i].title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Xóa',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await jobVM.deleteJob(jobs[i].id);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.people_outline,
                          color: Color(0xFF1E88E5)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ApplicantsScreen(
                            jobId: jobs[i].id,
                            jobTitle: jobs[i].title,
                          ),
                        ),
                      ),
                    ),
                  ],
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
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Đăng tin tuyển dụng',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration:
                    const InputDecoration(labelText: 'Tên vị trí *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập tên vị trí'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyCtrl,
                decoration:
                    const InputDecoration(labelText: 'Tên công ty *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập tên công ty'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration:
                    const InputDecoration(labelText: 'Địa điểm *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập địa điểm'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _salaryCtrl,
                decoration: const InputDecoration(
                    labelText: 'Mức lương (VD: 10-15 triệu) *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập mức lương'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category, // fixed: was deprecated `value`
                decoration:
                    const InputDecoration(labelText: 'Ngành nghề'),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Mô tả công việc *'),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập mô tả công việc'
                    : null,
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
      ),
    );
  }
}