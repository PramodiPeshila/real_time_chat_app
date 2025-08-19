import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:realtime_chat_app/models/connection_request.dart';
import 'package:realtime_chat_app/services/contact_service.dart';

class ConnectionRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      _firestore.collection('connection_requests');

  static CollectionReference<Map<String, dynamic>>
  get _notificationsCollection => _firestore.collection('notifications');

  // Generate a unique request ID
  static String _generateRequestId() {
    return _firestore.collection('connection_requests').doc().id;
  }

  /// Send a connection request to another user
  static Future<bool> sendConnectionRequest({
    required String toUserId,
    required String toUserName,
    required String toUserEmail,
    String? message,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No authenticated user');
        return false;
      }

      // Check if a request already exists between these users
      final existingRequest = await _getExistingRequest(
        currentUser.uid,
        toUserId,
      );
      if (existingRequest != null && existingRequest.isPending) {
        print('Connection request already exists');
        return false;
      }

      // Check if they are already contacts
      final isAlreadyContact = await ContactService.isContactRemote(
        currentUser.uid,
        toUserId,
      );
      if (isAlreadyContact) {
        print('Users are already contacts');
        return false;
      }

      final requestId = _generateRequestId();

      // Create request document directly in Firestore with server timestamp
      await _requestsCollection.doc(requestId).set({
        'fromUserId': currentUser.uid,
        'fromUserName': currentUser.displayName ?? 'Unknown User',
        'fromUserEmail': currentUser.email ?? '',
        'toUserId': toUserId,
        'toUserName': toUserName,
        'toUserEmail': toUserEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'message': message,
      });

      // Create notification for the recipient
      await _createNotification(
        userId: toUserId,
        type: 'connection_request',
        title: 'New Connection Request',
        body:
            '${currentUser.displayName ?? 'Someone'} wants to connect with you',
        data: {'requestId': requestId, 'fromUserId': currentUser.uid},
      );

      print('✅ Connection request sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending connection request: $e');
      return false;
    }
  }

  /// Get connection request by ID
  static Future<ConnectionRequest?> getConnectionRequest(
    String requestId,
  ) async {
    try {
      final doc = await _requestsCollection.doc(requestId).get();
      if (doc.exists && doc.data() != null) {
        final data = _fromFirestoreData(doc.data()!);
        return ConnectionRequest.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting connection request: $e');
      return null;
    }
  }

  /// Check if there's an existing request between two users
  static Future<ConnectionRequest?> _getExistingRequest(
    String fromUserId,
    String toUserId,
  ) async {
    try {
      // Check requests from fromUserId to toUserId
      final query1 = await _requestsCollection
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (query1.docs.isNotEmpty) {
        final data = _fromFirestoreData(query1.docs.first.data());
        return ConnectionRequest.fromJson(data);
      }

      // Check requests from toUserId to fromUserId
      final query2 = await _requestsCollection
          .where('fromUserId', isEqualTo: toUserId)
          .where('toUserId', isEqualTo: fromUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (query2.docs.isNotEmpty) {
        final data = _fromFirestoreData(query2.docs.first.data());
        return ConnectionRequest.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error checking existing request: $e');
      return null;
    }
  }

  /// Get all pending connection requests for a user (received)
  static Future<List<ConnectionRequest>> getPendingRequests(
    String userId,
  ) async {
    try {
      final snapshot = await _requestsCollection
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = _fromFirestoreData(doc.data());
        return ConnectionRequest.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  /// Get all sent connection requests for a user
  static Future<List<ConnectionRequest>> getSentRequests(String userId) async {
    try {
      final snapshot = await _requestsCollection
          .where('fromUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = _fromFirestoreData(doc.data());
        return ConnectionRequest.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting sent requests: $e');
      return [];
    }
  }

  /// Accept a connection request using transaction
  static Future<bool> acceptConnectionRequest(String requestId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No authenticated user');
        return false;
      }

      // Use transaction to ensure atomic updates
      await _firestore.runTransaction((transaction) async {
        final requestRef = _requestsCollection.doc(requestId);
        final requestSnap = await transaction.get(requestRef);

        if (!requestSnap.exists) {
          throw Exception('Request not found');
        }

        final data = requestSnap.data()!;

        // Check if request is still pending
        if (data['status'] != 'pending') {
          throw Exception('Request is no longer pending');
        }

        // Verify that current user is the recipient
        if (data['toUserId'] != currentUser.uid) {
          throw Exception('User not authorized to accept this request');
        }

        // Update request status
        transaction.update(requestRef, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });

        // Add both users to each other's contacts
        final fromUserId = data['fromUserId'] as String;
        final fromUserName = data['fromUserName'] as String;
        final fromUserEmail = data['fromUserEmail'] as String;
        final toUserName = data['toUserName'] as String;
        final toUserEmail = data['toUserEmail'] as String;

        // Add User A (fromUser) to User B's (currentUser) contact list
        final fromContact = {
          'userId': fromUserId,
          'email': fromUserEmail,
          'displayName': fromUserName,
          'addedAt': FieldValue.serverTimestamp(),
        };

        // Add User B (currentUser) to User A's (fromUser) contact list
        final toContact = {
          'userId': currentUser.uid,
          'email': toUserEmail,
          'displayName': toUserName,
          'addedAt': FieldValue.serverTimestamp(),
        };

        // Use correct ContactService structure: users/{ownerId}/contacts/{contactId}
        // Add fromUser to currentUser's contacts
        transaction.set(
          _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('contacts')
              .doc(fromUserId),
          fromContact,
        );

        // Add currentUser to fromUser's contacts
        transaction.set(
          _firestore
              .collection('users')
              .doc(fromUserId)
              .collection('contacts')
              .doc(currentUser.uid),
          toContact,
        );
      });

      // Get the fromUserId for notification
      final requestDoc = await _requestsCollection.doc(requestId).get();
      final fromUserId = requestDoc.data()?['fromUserId'] as String?;

      if (fromUserId != null) {
        // Create notification for the requester (outside transaction)
        await _createNotification(
          userId: fromUserId,
          type: 'connection_accepted',
          title: 'Connection Accepted',
          body:
              '${currentUser.displayName ?? 'Someone'} accepted your connection request',
          data: {'requestId': requestId, 'userId': currentUser.uid},
        );
      }

      print('✅ Connection request accepted successfully');
      return true;
    } catch (e) {
      print('❌ Error accepting connection request: $e');
      return false;
    }
  }

  /// Decline a connection request using transaction
  static Future<bool> declineConnectionRequest(String requestId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No authenticated user');
        return false;
      }

      String? fromUserId;

      // Use transaction to ensure atomic updates
      await _firestore.runTransaction((transaction) async {
        final requestRef = _requestsCollection.doc(requestId);
        final requestSnap = await transaction.get(requestRef);

        if (!requestSnap.exists) {
          throw Exception('Request not found');
        }

        final data = requestSnap.data()!;

        // Check if request is still pending
        if (data['status'] != 'pending') {
          throw Exception('Request is no longer pending');
        }

        // Verify that current user is the recipient
        if (data['toUserId'] != currentUser.uid) {
          throw Exception('User not authorized to decline this request');
        }

        fromUserId = data['fromUserId'] as String;

        // Update request status
        transaction.update(requestRef, {
          'status': 'declined',
          'respondedAt': FieldValue.serverTimestamp(),
        });
      });

      // Create notification for the requester (outside transaction)
      if (fromUserId != null) {
        await _createNotification(
          userId: fromUserId!,
          type: 'connection_declined',
          title: 'Connection Declined',
          body:
              '${currentUser.displayName ?? 'Someone'} declined your connection request',
          data: {'requestId': requestId},
        );
      }

      print('✅ Connection request declined successfully');
      return true;
    } catch (e) {
      print('❌ Error declining connection request: $e');
      return false;
    }
  }

  /// Check connection status between two users
  static Future<String> getConnectionStatus(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      // Check if they are already contacts
      final isContact = await ContactService.isContactRemote(
        currentUserId,
        otherUserId,
      );
      if (isContact) {
        return 'connected';
      }

      // Check for pending requests
      final existingRequest = await _getExistingRequest(
        currentUserId,
        otherUserId,
      );
      if (existingRequest != null) {
        if (existingRequest.fromUserId == currentUserId) {
          return 'request_sent';
        } else {
          return 'request_received';
        }
      }

      return 'not_connected';
    } catch (e) {
      print('Error checking connection status: $e');
      return 'not_connected';
    }
  }

  /// Create a notification
  static Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notificationsCollection.add({
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Convert from Firestore data
  static Map<String, dynamic> _fromFirestoreData(Map<String, dynamic> data) {
    final Map<String, dynamic> normalizedData = Map<String, dynamic>.from(data);

    // Convert Firestore Timestamps to ISO strings
    if (normalizedData['createdAt'] is Timestamp) {
      normalizedData['createdAt'] = (normalizedData['createdAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    if (normalizedData['respondedAt'] is Timestamp) {
      normalizedData['respondedAt'] =
          (normalizedData['respondedAt'] as Timestamp)
              .toDate()
              .toIso8601String();
    }

    return normalizedData;
  }

  /// Clean up expired requests (can be called periodically)
  static Future<void> cleanupExpiredRequests() async {
    try {
      final expiredDate = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _requestsCollection
          .where('status', isEqualTo: 'pending')
          .where('createdAt', isLessThan: expiredDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'expired'});
      }

      await batch.commit();
      print('Cleaned up ${snapshot.docs.length} expired requests');
    } catch (e) {
      print('Error cleaning up expired requests: $e');
    }
  }
}
