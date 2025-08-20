import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InstantChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate chat room ID for two users (consistent ordering)
  static String generateChatRoomId(String userId1, String userId2) {
    List<String> users = [userId1, userId2];
    users.sort(); // Ensure consistent ordering
    return '${users[0]}_${users[1]}';
  }

  /// Delete all messages in a chat room and remove the chat room document
  static Future<bool> deleteChat(String chatRoomId) async {
    try {
      // Delete instant messages in batches to respect Firestore limits
      const int batchSize = 300;
      while (true) {
        final snapshot = await _firestore
            .collection('instant_messages')
            .where('chatRoomId', isEqualTo: chatRoomId)
            .limit(batchSize)
            .get();

        if (snapshot.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Delete chat room summary
      await _firestore
          .collection('instant_chat_rooms')
          .doc(chatRoomId)
          .delete();

      print('🧹 Chat deleted for chatRoomId=$chatRoomId');
      return true;
    } catch (e) {
      print('❌ Error deleting chat $chatRoomId: $e');
      return false;
    }
  }

  /// Send an instant message
  static Future<bool> sendMessage({
    required String receiverId,
    required String receiverName,
    required String message,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No authenticated user');
        return false;
      }

      final chatRoomId = generateChatRoomId(currentUser.uid, receiverId);

      // Create message document
      final messageData = {
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Unknown User',
        'receiverId': receiverId,
        'receiverName': receiverName,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'chatRoomId': chatRoomId,
      };

      // Add message to instant_messages collection
      await _firestore.collection('instant_messages').add(messageData);

      // Update or create chat room info
      await _updateChatRoom(chatRoomId, currentUser.uid, receiverId, message);

      print('✅ Instant message sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending instant message: $e');
      return false;
    }
  }

  /// Update chat room with latest message info
  static Future<void> _updateChatRoom(
    String chatRoomId,
    String senderId,
    String receiverId,
    String lastMessage,
  ) async {
    try {
      final chatRoomData = {
        'chatRoomId': chatRoomId,
        'participants': [senderId, receiverId],
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('instant_chat_rooms')
          .doc(chatRoomId)
          .set(chatRoomData, SetOptions(merge: true));
    } catch (e) {
      print('❌ Error updating chat room: $e');
    }
  }

  /// Get messages for a chat room
  static Stream<QuerySnapshot> getMessages(String chatRoomId) {
    // Keep query simple to avoid composite index requirement; we'll sort client-side
    return _firestore
        .collection('instant_messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .snapshots();
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(
    String chatRoomId,
    String currentUserId,
  ) async {
    try {
      final unreadMessages = await _firestore
          .collection('instant_messages')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  /// Get chat rooms for current user
  static Stream<QuerySnapshot> getChatRooms(String userId) {
    // Keep query simple to avoid composite index requirement with arrayContains + orderBy
    return _firestore
        .collection('instant_chat_rooms')
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  /// Check if user exists and get their info
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error getting user info: $e');
      return null;
    }
  }
}
