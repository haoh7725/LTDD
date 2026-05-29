import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final chatService = ChatService();

    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getMyChats(auth.userModel!.uid),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final chats = snap.data!;
          if (chats.isEmpty) return const Center(child: Text('Chưa có cuộc trò chuyện nào'));
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (_, i) {
              final chat = chats[i];
              final participants = List<String>.from(chat['participants'] ?? []);
              final otherId = participants.firstWhere(
                (p) => p != auth.userModel!.uid,
                orElse: () => '',
              );
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();
                  final userData = userSnap.data!.data() as Map<String, dynamic>?;
                  final otherName = userData?['fullName'] ?? 'Người dùng';
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(otherName[0].toUpperCase()),
                    ),
                    title: Text(otherName),
                    subtitle: Text(chat['lastMessage'] ?? ''),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          otherUserId: otherId,
                          otherUserName: otherName,
                        ),
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