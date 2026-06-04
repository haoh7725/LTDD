import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_screen.dart';
import '../../services/report_service.dart';
import '../../services/notification_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị viên'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Đăng xuất'),
                    content: const Text('Bạn có chắc muốn đăng xuất?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Đăng xuất',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<AuthViewModel>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Thống kê'),
              Tab(text: 'Người dùng'),
              Tab(text: 'Tin tuyển dụng'),
              Tab(text: 'Báo cáo'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StatsTab(),
            _UsersTab(),
            _JobsTab(),
            _ReportsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Stats Tab ─────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  Stream<int> _countStream(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> _countByRole(String role) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> _countByStatus(String status) {
    return FirebaseFirestore.instance
        .collection('applications')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng quan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  stream: _countStream('users'),
                  label: 'Người dùng',
                  icon: Icons.people,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countStream('jobs'),
                  label: 'Tin tuyển dụng',
                  icon: Icons.work,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countStream('applications'),
                  label: 'Đơn ứng tuyển',
                  icon: Icons.assignment,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Người dùng theo vai trò',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  stream: _countByRole('candidate'),
                  label: 'Ứng viên',
                  icon: Icons.person,
                  color: const Color(0xFF1E88E5),
                  small: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countByRole('employer'),
                  label: 'Nhà tuyển dụng',
                  icon: Icons.business,
                  color: Colors.green,
                  small: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countByRole('admin'),
                  label: 'Admin',
                  icon: Icons.admin_panel_settings,
                  color: Colors.red,
                  small: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Đơn ứng tuyển theo trạng thái',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  stream: _countByStatus('pending'),
                  label: 'Chờ duyệt',
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                  small: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countByStatus('accepted'),
                  label: 'Đã duyệt',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  small: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countByStatus('rejected'),
                  label: 'Từ chối',
                  icon: Icons.cancel,
                  color: Colors.red,
                  small: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Hoạt động gần đây',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Text('Chưa có tin tuyển dụng nào');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('5 tin tuyển dụng mới nhất',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  ...docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final createdAt = (data['createdAt'] as dynamic)?.toDate();
                    final timeStr =
                        createdAt != null ? _timeAgo(createdAt) : '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: const Icon(Icons.work,
                            color: Colors.green, size: 20),
                      ),
                      title: Text(data['title'] ?? '',
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text(data['company'] ?? '',
                          style: const TextStyle(fontSize: 12)),
                      trailing: Text(timeStr,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    return '${(diff.inDays / 30).floor()} tháng trước';
  }
}

class _StatCard extends StatelessWidget {
  final Stream<int> stream;
  final String label;
  final IconData icon;
  final Color color;
  final bool small;

  const _StatCard({
    required this.stream,
    required this.label,
    required this.icon,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return Container(
          padding: EdgeInsets.all(small ? 12 : 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: small ? 24 : 32),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: small ? 20 : 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: small ? 10 : 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Users Tab ─────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final role = data['role'] ?? 'candidate';
            final isBlocked = data['isBlocked'] ?? false;
            final uid = docs[i].id;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBlocked
                      ? Colors.grey
                      : role == 'employer'
                          ? Colors.green
                          : Colors.blue,
                  child: Text(
                    (data['fullName'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(data['fullName'] ?? ''),
                subtitle: Text(data['email'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        role == 'employer'
                            ? 'NTD'
                            : role == 'admin'
                                ? 'Admin'
                                : 'UV',
                      ),
                      backgroundColor: role == 'employer'
                          ? Colors.green.shade100
                          : role == 'admin'
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        isBlocked ? Icons.lock_open : Icons.lock,
                        color: isBlocked ? Colors.green : Colors.red,
                      ),
                      tooltip: isBlocked ? 'Mở khóa' : 'Khóa tài khoản',
                      onPressed: () async {
                        final authVM = context.read<AuthViewModel>();
                        if (uid == authVM.userModel?.uid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Không thể khóa tài khoản của chính mình')),
                          );
                          return;
                        }
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({'isBlocked': !isBlocked});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isBlocked
                                  ? 'Đã mở khóa tài khoản'
                                  : 'Đã khóa tài khoản'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Jobs Tab ──────────────────────────────────────────────────────────────

class _JobsTab extends StatelessWidget {
  const _JobsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final jobId = docs[i].id;
            return Card(
              child: ListTile(
                title: Text(data['title'] ?? ''),
                subtitle: Text('${data['company']} • ${data['category']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: Text(
                            'Bạn có chắc muốn xóa tin "${data['title']}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Xóa',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('jobs')
                          .doc(jobId)
                          .delete();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã xóa tin tuyển dụng')),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Reports Tab ───────────────────────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final notifService = NotificationService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: reportService.getAllReports(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snap.data!;
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Chưa có báo cáo nào',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        // Đếm số báo cáo chờ xử lý
        final pendingCount =
            reports.where((r) => r['status'] == 'pending').length;

        return Column(
          children: [
            // Banner tổng số báo cáo chờ xử lý
            if (pendingCount > 0)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '$pendingCount báo cáo đang chờ xử lý',
                      style: const TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: reports.length,
                itemBuilder: (_, i) {
                  final r = reports[i];
                  final status = r['status'] ?? 'pending';
                  final isPending = status == 'pending';
                  final createdAt = (r['createdAt'] as dynamic)
                          ?.toDate()
                          .toString()
                          .substring(0, 10) ??
                      '';
                  final reporterId = r['reporterId'] ?? '';
                  final jobId = r['jobId'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: icon + thông tin báo cáo + badge trạng thái
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isPending
                                    ? Colors.red.shade100
                                    : Colors.green.shade100,
                                child: Icon(
                                  isPending ? Icons.flag : Icons.check,
                                  color: isPending ? Colors.red : Colors.green,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['jobTitle'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text('Lý do: ${r['reason']}',
                                        style:
                                            const TextStyle(fontSize: 13)),
                                    Text('Ngày báo cáo: $createdAt',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? Colors.orange.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isPending
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                                child: Text(
                                  isPending ? 'Chờ xử lý' : 'Đã xử lý',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isPending
                                        ? Colors.orange
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Thông tin người báo cáo (fetch realtime)
                          if (reporterId.isNotEmpty)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(reporterId)
                                  .get(),
                              builder: (context, userSnap) {
                                final userData = userSnap.data?.data()
                                    as Map<String, dynamic>?;
                                final reporterName =
                                    userData?['fullName'] ?? 'Đang tải...';
                                final reporterEmail =
                                    userData?['email'] ?? '';
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_outline,
                                          size: 14,
                                          color: Colors.grey.shade500),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Báo cáo bởi: $reporterName${reporterEmail.isNotEmpty ? ' ($reporterEmail)' : ''}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 10),

                          // Action buttons
                          if (isPending)
                            Column(
                              children: [
                                // Hàng 1: Đánh dấu xử lý + Xóa tin & xử lý
                                Row(
                                  children: [
                                    // Đánh dấu đã xử lý (không xóa tin)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.check,
                                            color: Colors.green, size: 16),
                                        label: const Text('Đã xử lý',
                                            style: TextStyle(
                                                color: Colors.green)),
                                        style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                                color: Colors.green)),
                                        onPressed: () async {
                                          await reportService
                                              .resolveReport(r['id']);
                                          // Thông báo cho người báo cáo
                                          if (reporterId.isNotEmpty) {
                                            await notifService.sendNotification(
                                              toUserId: reporterId,
                                              title: 'Báo cáo đã được xử lý',
                                              body:
                                                  'Báo cáo của bạn về tin "${r['jobTitle']}" đã được admin xem xét và xử lý.',
                                              type: 'general',
                                            );
                                          }
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Đã đánh dấu xử lý')),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Xóa tin + đánh dấu xử lý
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.delete_forever,
                                            color: Colors.red, size: 16),
                                        label: const Text('Xóa tin',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                                color: Colors.red)),
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Xác nhận xóa tin'),
                                              content: Text(
                                                  'Xóa tin "${r['jobTitle']}" và đánh dấu báo cáo đã xử lý?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Hủy'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Xóa',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm != true) return;

                                          // Xóa job
                                          if (jobId.isNotEmpty) {
                                            await FirebaseFirestore.instance
                                                .collection('jobs')
                                                .doc(jobId)
                                                .delete();
                                          }

                                          // Đánh dấu báo cáo đã xử lý
                                          await reportService
                                              .resolveReport(r['id']);

                                          // Thông báo người báo cáo
                                          if (reporterId.isNotEmpty) {
                                            await notifService.sendNotification(
                                              toUserId: reporterId,
                                              title: 'Báo cáo đã được xử lý',
                                              body:
                                                  'Tin tuyển dụng "${r['jobTitle']}" bạn báo cáo đã bị gỡ khỏi hệ thống.',
                                              type: 'general',
                                            );
                                          }

                                          // Lấy employerId để thông báo nhà tuyển dụng
                                          if (jobId.isNotEmpty) {
                                            final jobDoc =
                                                await FirebaseFirestore.instance
                                                    .collection('jobs')
                                                    .doc(jobId)
                                                    .get();
                                            // job đã bị xóa nên jobDoc.exists = false
                                            // employerId lấy từ report nếu có, hoặc bỏ qua
                                          }

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Đã xóa tin và xử lý báo cáo'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Hàng 2: Xóa báo cáo
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.grey, size: 16),
                                    label: const Text('Xóa báo cáo',
                                        style: TextStyle(color: Colors.grey)),
                                    style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: Colors.grey.shade400)),
                                    onPressed: () async {
                                      await reportService
                                          .deleteReport(r['id']);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('Đã xóa báo cáo')),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            // Báo cáo đã xử lý: chỉ có nút xóa báo cáo
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 16),
                                label: const Text('Xóa báo cáo',
                                    style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                    side:
                                        const BorderSide(color: Colors.red)),
                                onPressed: () async {
                                  await reportService.deleteReport(r['id']);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Đã xóa báo cáo')),
                                    );
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}