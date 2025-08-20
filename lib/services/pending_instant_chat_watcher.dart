import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../pages/instant_chat_screen.dart';
import 'instant_chat_service.dart';

class PendingInstantChatWatcher {
  static StreamSubscription<QuerySnapshot>? _messageSubscription;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static final Set<String> _processedMessages = <String>{};
  // Track chat rooms we've already notified about for this session
  static final Set<String> _notifiedChatRooms = <String>{};
  // Track the currently active chat room to suppress notifications
  static String? _activeChatRoomId;

  /// Set the navigator key (should be called from main.dart)
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Set the currently active chat room (suppress notifications for this chat)
  static void setActiveChatRoom(String chatRoomId) {
    _activeChatRoomId = chatRoomId;
    print('🔇 Suppressing notifications for active chat: $chatRoomId');
  }

  /// Clear the active chat room (allow notifications again)
  static void clearActiveChatRoom() {
    final previousChatRoomId = _activeChatRoomId;
    _activeChatRoomId = null;
    if (previousChatRoomId != null) {
      print(
        '🔔 Re-enabling notifications, was suppressed for: $previousChatRoomId',
      );
    }
  }

  /// Start listening for incoming instant messages
  static Future<void> startListening() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ No authenticated user for instant chat watcher');
      return;
    }

    print(
      '🔍 Starting instant chat message watcher for user: ${currentUser.uid}',
    );

    _messageSubscription?.cancel();
    // Fresh session suppression
    _notifiedChatRooms.clear();

    _messageSubscription = FirebaseFirestore.instance
        .collection('instant_messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        // Keep query simple to avoid composite index requirement; we'll filter isRead in code
        .snapshots()
        .listen(
          (snapshot) {
            _handleNewMessages(snapshot);
          },
          onError: (error) {
            print('❌ Error in instant chat watcher: $error');
          },
        );
  }

  /// Handle new instant messages
  static void _handleNewMessages(QuerySnapshot snapshot) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    for (var change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      final dataRaw = change.doc.data();
      if (dataRaw == null) continue;
      final messageData = dataRaw as Map<String, dynamic>;
      final messageId = change.doc.id;
      final String? chatRoomIdRaw = messageData['chatRoomId'] as String?;
      final String senderId = (messageData['senderId'] as String?) ?? '';
      final String receiverId = (messageData['receiverId'] as String?) ?? '';
      final String fallbackChatRoomId =
          (chatRoomIdRaw != null && chatRoomIdRaw.isNotEmpty)
          ? chatRoomIdRaw
          : InstantChatService.generateChatRoomId(senderId, receiverId);

      // Filter only unread messages here
      if ((messageData['isRead'] as bool?) == true) continue;

      // Skip if already processed
      if (_processedMessages.contains(messageId)) continue;
      _processedMessages.add(messageId);

      // Skip notification if this chat room is currently active (user is viewing it)
      if (_activeChatRoomId == fallbackChatRoomId) {
        print(
          '🔇 Skipping notification for active chat room: $fallbackChatRoomId',
        );
        continue;
      }

      // Only show popup once per chat room until user opens it
      if (!_notifiedChatRooms.contains(fallbackChatRoomId)) {
        _showInstantMessageNotification(messageData);
        _notifiedChatRooms.add(fallbackChatRoomId);
      }
    }
  }

  /// Show notification for new instant message
  static void _showInstantMessageNotification(
    Map<String, dynamic> messageData,
  ) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final senderName = messageData['senderName'] ?? 'Unknown User';
    final message = messageData['message'] ?? '';
    final senderId = messageData['senderId'];

    // Show snackbar with action to open chat
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New message from $senderName',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.length > 50 ? '${message.substring(0, 50)}...' : message,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OPEN CHAT',
          textColor: Colors.white,
          onPressed: () {
            _openInstantChat(context, senderId, senderName);
          },
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    print('📱 Instant message notification shown from: $senderName');
  }

  /// Open instant chat screen
  static void _openInstantChat(
    BuildContext context,
    String senderId,
    String senderName,
  ) {
    // Mark any unread messages as read for this chat room before navigating
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final chatRoomId = InstantChatService.generateChatRoomId(
        currentUser.uid,
        senderId,
      );
      InstantChatService.markMessagesAsRead(chatRoomId, currentUser.uid);
      // Clear suppression on open so the next new conversation can notify again
      clearSuppressionForChat(chatRoomId);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstantChatScreen(
          receiverId: senderId,
          receiverName: senderName,
          ephemeral: false,
        ),
      ),
    );
  }

  /// Stop listening for instant messages
  static void stopListening() {
    print('🛑 Stopping instant chat message watcher');
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _processedMessages.clear();
    // Keep _notifiedChatRooms persisted; no need to clear here
  }

  /// Clear processed messages cache
  static void clearProcessedMessages() {
    _processedMessages.clear();
  }

  /// Clear suppression for a specific chat room (used after deleting a chat)
  static Future<void> clearSuppressionForChat(String chatRoomId) async {
    _notifiedChatRooms.remove(chatRoomId);
    // No persistence: session-only suppression
  }
}
