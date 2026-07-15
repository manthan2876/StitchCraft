import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/profile_service.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _profileService = ProfileService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoadingProfile = true;
  String? _shopId;
  String? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _initFirebaseAndProfile();
  }

  Future<void> _initFirebaseAndProfile() async {
    try {
      // 1. Firebase Anonymous Sign In
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      // 2. Fetch User Profile
      final profile = await _profileService.fetchProfile();
      if (profile != null) {
        setState(() {
          _shopId = profile['shopId'];
          _userId = profile['_id'];
          _userName = profile['name'];
        });
      }
    } catch (e) {
      debugPrint("Error initializing chat: $e");
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _shopId == null || _userId == null) return;

    _messageController.clear();

    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'shopId': _shopId,
        'senderId': _userId,
        'senderName': _userName ?? 'Staff Member',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Auto scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: context.loc.chat,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1.0,
          ),
        ),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPurple))
          : _shopId == null
              ? const Center(
                  child: Text(
                    'Unable to retrieve shop channel info.',
                    style: TextStyle(color: AppTheme.alertRed),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('messages')
                            .where('shopId', isEqualTo: _shopId)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: AppTheme.alertRed),
                              ),
                            );
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppTheme.brandPurple));
                          }

                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return _buildWelcomeMessage();
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final bool isMe = data['senderId'] == _userId;
                              final String senderName = data['senderName'] ?? 'Staff Member';
                              final String text = data['text'] ?? '';
                              final Timestamp? timestamp = data['createdAt'] as Timestamp?;
                              
                              final DateTime time = timestamp?.toDate() ?? DateTime.now();
                              final String formattedTime = DateFormat('hh:mm a').format(time);

                              return _buildMessageBubble(
                                text: text,
                                senderName: senderName,
                                formattedTime: formattedTime,
                                isMe: isMe,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    _buildInputBar(),
                  ],
                ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.brandPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppTheme.brandPurple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Shop Channel',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a conversation with your karigars & staff.',
            style: TextStyle(color: AppTheme.darkGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required String senderName,
    required String formattedTime,
    required bool isMe,
  }) {
    final theme = Theme.of(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  senderName,
                  style: const TextStyle(color: AppTheme.darkGrey, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe 
                    ? AppTheme.brandPurple
                    : theme.cardTheme.color ?? const Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
                border: Border.all(
                  color: isMe 
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      color: isMe ? Colors.white.withValues(alpha: 0.6) : AppTheme.darkGrey,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppTheme.darkGrey),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.brandPurple,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
