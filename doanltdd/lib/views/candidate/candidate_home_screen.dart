import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../models/job_model.dart';
import '../../services/notification_service.dart';
import 'job_detail_screen.dart';
import 'my_applications_screen.dart';
import 'profile_screen.dart';
import '../chat/chat_list_screen.dart';
import '../notifications/notifications_screen.dart';

class CandidateHomeScreen extends StatefulWidget {
  const CandidateHomeScreen({super.key});

  @override
  State<CandidateHomeScreen> createState() => _CandidateHomeScreenState();
}

class _CandidateHomeScreenState extends State<CandidateHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _keyword = '';
  String _locationFilter = '';
  int _currentIndex = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final jobVM = context.watch<JobViewModel>();
    final notifService = NotificationService();
    final uid = auth.userModel?.uid ?? '';

    final pages = [
      _buildJobList(auth, jobVM, notifService, uid),
      const MyApplicationsScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.search), label: 'Tìm việc'),
          const NavigationDestination(
              icon: Icon(Icons.assignment), label: 'Đơn ứng tuyển'),
          const NavigationDestination(
              icon: Icon(Icons.chat), label: 'Tin nhắn'),
          const NavigationDestination(
              icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }

  Widget _buildJobList(AuthViewModel auth, JobViewModel jobVM,
      NotificationService notifService, String uid) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tìm việc làm',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Xin chào, ${auth.userModel?.fullName ?? ''}!',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          // Icon thông báo có badge
          StreamBuilder<int>(
            stream: notifService.getUnreadCount(uid),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm việc làm, công ty...',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Lọc theo địa điểm (VD: Hồ Chí Minh)',
                prefixIcon: const Icon(Icons.location_on, size: 20),
                suffixIcon: _locationFilter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            setState(() => _locationFilter = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              onChanged: (v) =>
                  setState(() => _locationFilter = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
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
                    onSelected: (_) => jobVM
                        .setCategory(cat == 'Tất cả' ? '' : cat),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: StreamBuilder<List<JobModel>>(
              stream: jobVM.getJobs(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var jobs = snap.data ?? [];
                if (_keyword.isNotEmpty) {
                  jobs = jobs
                      .where((j) =>
                          j.title.toLowerCase().contains(_keyword) ||
                          j.company.toLowerCase().contains(_keyword) ||
                          j.location.toLowerCase().contains(_keyword))
                      .toList();
                }
                if (_locationFilter.isNotEmpty) {
                  jobs = jobs
                      .where((j) => j.location
                          .toLowerCase()
                          .contains(_locationFilter))
                      .toList();
                }
                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('Không tìm thấy việc làm phù hợp',
                            style:
                                TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
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
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => JobDetailScreen(job: job))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1E88E5),
                child: Text(
                  job.company.isNotEmpty
                      ? job.company[0].toUpperCase()
                      : 'J',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(job.company,
                        style:
                            TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _tag(Icons.location_on, job.location,
                            Colors.red),
                        _tag(Icons.attach_money, job.salary,
                            Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(job.category,
                    style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.blue.shade50,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Text(text,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}