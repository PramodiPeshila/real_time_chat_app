import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/instant_chat_service.dart';
import '../services/pending_instant_chat_watcher.dart';

class InstantChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  // When true, closing the screen will destroy the chat for both users
  final bool ephemeral;

  const InstantChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.ephemeral = false,
  });

  @override
  State<InstantChatScreen> createState() => _InstantChatScreenState();
}

class _InstantChatScreenState extends State<InstantChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String chatRoomId;
  late String currentUserId;
  bool _isLoading = false;

  Future<bool> _confirmAndDeleteOnExit() async {
    // Clear active chat room suppression when leaving
    PendingInstantChatWatcher.clearActiveChatRoom();

    // For contact-based (persistent) chats, do not delete on exit
    if (!mounted || widget.ephemeral == false) {
      return true; // allow pop without deletion
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close chat?'),
        content: const Text(
          'Closing will permanently delete all messages in this chat for both users. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.blue),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Delete & Close'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await InstantChatService.deleteChat(chatRoomId);
      if (ok) {
        await PendingInstantChatWatcher.clearSuppressionForChat(chatRoomId);
      }
      return true; // allow pop regardless to avoid trapping user
    }

    return false; // cancel pop
  }

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    chatRoomId = InstantChatService.generateChatRoomId(
      currentUserId,
      widget.receiverId,
    );

    // Mark messages as read when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InstantChatService.markMessagesAsRead(chatRoomId, currentUserId);
      // Suppress notifications for this chat while user is viewing it
      PendingInstantChatWatcher.setActiveChatRoom(chatRoomId);
    });
  }

  @override
  void dispose() {
    // Re-enable notifications when leaving this chat screen
    PendingInstantChatWatcher.clearActiveChatRoom();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    _messageController.clear();

    final success = await InstantChatService.sendMessage(
      receiverId: widget.receiverId,
      receiverName: widget.receiverName,
      message: message,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _scrollToBottom();
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe) {
    final timestamp = messageData['timestamp'] as Timestamp?;
    final timeString = timestamp != null
        ? _formatTime(timestamp.toDate())
        : 'Sending...';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color.fromARGB(255, 0, 94, 255) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Text(
                messageData['senderName'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            Text(
              messageData['message'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeString,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmAndDeleteOnExit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.receiverName),
          backgroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.blue,
          foregroundColor: Colors.black,

          actions: [
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete chat for both',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete chat?'),
                    content: const Text(
                      'This will permanently delete all messages in this chat for both users. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.blue),
                        ),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final ok = await InstantChatService.deleteChat(chatRoomId);
                  if (!mounted) return;
                  if (ok) {
                    // Allow future popup notifications if this chat restarts
                    await PendingInstantChatWatcher.clearSuppressionForChat(
                      chatRoomId,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat deleted'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete chat'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: InstantChatService.getMessages(chatRoomId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final ta =
                          (a.data() as Map<String, dynamic>)['timestamp']
                              as Timestamp?;
                      final tb =
                          (b.data() as Map<String, dynamic>)['timestamp']
                              as Timestamp?;
                      if (ta == null && tb == null) return 0;
                      if (ta == null) return -1;
                      if (tb == null) return 1;
                      return ta.compareTo(tb);
                    });

                  // Auto scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageData =
                          messages[index].data() as Map<String, dynamic>;
                      final isMe = messageData['senderId'] == currentUserId;

                      return _buildMessageBubble(messageData, isMe);
                    },
                  );
                },
              ),
            ),

            // Message input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: FloatingActionButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      backgroundColor: const Color.fromARGB(255, 0, 94, 255),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      mini: true,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
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
}
