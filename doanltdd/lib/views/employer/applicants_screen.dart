import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../services/notification_service.dart';
import '../chat/chat_screen.dart';

class ApplicantsScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const ApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final Map<String, Map<String, dynamic>?> _userCache = {};

  Future<Map<String, dynamic>?> _getUserInfo(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    _userCache[uid] = doc.data();
    return _userCache[uid];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return 'Chờ duyệt';
    }
  }

  // FIX #7: Không truyền BuildContext qua async gap
  // Lấy service và jobVM trước khi await, kiểm tra mounted sau
  Future<void> _updateStatus(
    String applicationId,
    String candidateId,
    String newStatus,
    String candidateName,
  ) async {
    // Lấy references trước khi bước vào async gap
    final jobVM = context.read<JobViewModel>();
    final notifService = NotificationService();
    final jobTitle = widget.jobTitle;

    await jobVM.updateApplicationStatus(applicationId, newStatus);

    // Kiểm tra mounted trước khi dùng context
    if (!mounted) return;

    final title = newStatus == 'accepted'
        ? 'Đơn ứng tuyển được duyệt'
        : 'Đơn ứng tuyển bị từ chối';
    final body = newStatus == 'accepted'
        ? 'Chúc mừng! Đơn ứng tuyển của bạn cho vị trí "$jobTitle" đã được chấp nhận.'
        : 'Rất tiếc, đơn ứng tuyển của bạn cho vị trí "$jobTitle" đã bị từ chối.';

    await notifService.sendNotification(
      toUserId: candidateId,
      title: title,
      body: body,
      type: newStatus,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newStatus == 'accepted'
            ? 'Đã duyệt đơn của $candidateName'
            : 'Đã từ chối đơn của $candidateName'),
        backgroundColor:
            newStatus == 'accepted' ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobVM = context.read<JobViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ứng viên',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.jobTitle,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: jobVM.getApplicationsByJob(widget.jobId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = snap.data ?? [];
          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Chưa có ứng viên nào',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: apps.length,
            itemBuilder: (_, i) {
              final app = apps[i];
              final status = app['status'] ?? 'pending';
              final candidateId = app['candidateId'] ?? '';
              final candidateName = app['candidateName'] ?? 'Ứng viên';
              final appliedAt = (app['appliedAt'] as dynamic)
                      ?.toDate()
                      .toString()
                      .substring(0, 10) ??
                  '';

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserInfo(candidateId),
                builder: (context, userSnap) {
                  final userData = userSnap.data;
                  final phone = userData?['phone'] ?? '';
                  final skills = userData?['skills'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF1E88E5),
                                child: Text(
                                  candidateName.isNotEmpty
                                      ? candidateName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(candidateName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    if (phone.isNotEmpty)
                                      Text(phone,
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13)),
                                    Text('Ngày nộp: $appliedAt',
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _statusColor(status)
                                          .withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          if (skills.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Kỹ năng: $skills',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700)),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (status == 'pending') ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green, size: 18),
                                    label: const Text('Duyệt',
                                        style: TextStyle(
                                            color: Colors.green)),
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Colors.green)),
                                    onPressed: () => _updateStatus(
                                      app['id'],
                                      candidateId,
                                      'accepted',
                                      candidateName,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red, size: 18),
                                    label: const Text('Từ chối',
                                        style:
                                            TextStyle(color: Colors.red)),
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Colors.red)),
                                    onPressed: () => _updateStatus(
                                      app['id'],
                                      candidateId,
                                      'rejected',
                                      candidateName,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 18),
                                  label: const Text('Nhắn tin'),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        otherUserId: candidateId,
                                        otherUserName: candidateName,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}