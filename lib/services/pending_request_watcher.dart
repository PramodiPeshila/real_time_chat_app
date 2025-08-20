import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:realtime_chat_app/services/connection_request_service.dart';

/// Real-time watcher for pending connection requests and notifications
/// Shows AlertDialog when new requests arrive and handles accepted notifications
class PendingRequestWatcher {
  static StreamSubscription<QuerySnapshot>? _subscription;
  static StreamSubscription<QuerySnapshot>? _notificationSubscription;
  static final Set<String> _seenRequests = <String>{};
  static final Set<String> _seenNotifications = <String>{};
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Initialize the navigator key for showing dialogs
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  /// Start listening for pending connection requests
  static void startListening() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ No authenticated user for request watching');
      return;
    }

    print(
      '🔍 Starting to watch for connection requests for user: ${currentUser.uid}',
    );

    // Stop any existing subscriptions
    stopListening();

    // Listen for pending connection requests (ONLY for User B - the recipient)
    _subscription = FirebaseFirestore.instance
        .collection('connection_requests')
        .where('toUserId', isEqualTo: currentUser.uid) // Only for recipient
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
          _onRequestsChanged,
          onError: (error) {
            print('❌ Error watching connection requests: $error');
          },
        );

    // Listen for connection accepted notifications (for User A - the original requester)
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('type', isEqualTo: 'connection_accepted')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
          _onNotificationsChanged,
          onError: (error) {
            print('❌ Error watching notifications: $error');
          },
        );

    print(
      '✅ Listeners started - watching for requests TO user ${currentUser.uid}',
    );
  }

  /// Stop listening for connection requests
  static void stopListening() {
    print('🛑 Stopping connection request watcher');
    _subscription?.cancel();
    _subscription = null;
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _seenRequests.clear();
    _seenNotifications.clear();
  }

  /// Handle changes in connection requests collection
  static void _onRequestsChanged(QuerySnapshot snapshot) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ No current user for processing requests');
      return;
    }

    print(
      '📨 Connection requests snapshot received with ${snapshot.docs.length} documents for user: ${currentUser.uid}',
    );

    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final doc = change.doc;
        final requestId = doc.id;
        final data = doc.data() as Map<String, dynamic>?;

        if (data == null) {
          print('❌ Invalid request data for: $requestId');
          continue;
        }

        final toUserId = data['toUserId'] as String?;
        final fromUserId = data['fromUserId'] as String?;

        // Double-check: Only show to the recipient (toUserId)
        if (toUserId != currentUser.uid) {
          print(
            '⚠️ Skipping request $requestId - not for current user (toUserId: $toUserId, currentUser: ${currentUser.uid})',
          );
          continue;
        }

        // Don't show alerts to the sender
        if (fromUserId == currentUser.uid) {
          print('⚠️ Skipping request $requestId - current user is the sender');
          continue;
        }

        // Skip if we've already shown this request
        if (_seenRequests.contains(requestId)) {
          print('⏭️ Skipping already seen request: $requestId');
          continue;
        }

        print(
          '🆕 New connection request detected for recipient: $requestId (from: $fromUserId to: $toUserId)',
        );
        _seenRequests.add(requestId);
        _showConnectionRequestDialog(doc);
      }
    }
  }

  /// Handle changes in notifications collection for connection accepted events
  static void _onNotificationsChanged(QuerySnapshot snapshot) {
    print(
      '📬 Notifications snapshot received with ${snapshot.docs.length} documents',
    );

    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final doc = change.doc;
        final notificationId = doc.id;

        // Skip if we've already processed this notification
        if (_seenNotifications.contains(notificationId)) {
          print('⏭️ Skipping already seen notification: $notificationId');
          return;
        }

        print(
          '🎉 New connection accepted notification detected: $notificationId',
        );
        _seenNotifications.add(notificationId);
        _handleConnectionAcceptedNotification(doc);
      }
    }
  }

  /// Show connection request dialog to user
  static Future<void> _showConnectionRequestDialog(DocumentSnapshot doc) async {
    if (navigatorKey?.currentContext == null) {
      print('❌ No context available for showing dialog');
      return;
    }

    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        print('❌ Invalid request data');
        return;
      }

      final fromUserId = data['fromUserId'] as String?;
      final fromUserName = data['fromUserName'] as String? ?? 'Unknown User';
      final toUserId = data['toUserId'] as String?;
      final message = data['message'] as String?;

      if (fromUserId == null || toUserId == null) {
        print('❌ Missing fromUserId or toUserId in request data');
        return;
      }

      // Final safety check - make sure current user is the recipient
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != toUserId) {
        print(
          '❌ Dialog showing to wrong user! CurrentUser: ${currentUser?.uid}, ToUser: $toUserId',
        );
        return;
      }

      print(
        '🚀 Showing dialog for request from: $fromUserName to: ${currentUser.uid}',
      );

      final context = navigatorKey!.currentContext!;
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Colors.blue),
              SizedBox(width: 8),
              Text('New Request'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$fromUserName wants to connect with you.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(message),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Decline'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.green),
              ),
              child: const Text('Accept'),
            ),
          ],
        ),
      );

      if (accepted == true) {
        await _acceptRequest(doc.id);
      } else if (accepted == false) {
        await _declineRequest(doc.id);
      }
    } catch (e) {
      print('❌ Error showing connection request dialog: $e');
    }
  }

  /// Accept a connection request and add to contacts
  static Future<void> _acceptRequest(String requestId) async {
    print('✅ Accepting connection request: $requestId');

    try {
      // Get the request data first to know who we're adding
      final requestDoc = await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        print('❌ Request document not found');
        _showSnackBar('Request not found. Please try again.', Colors.red);
        return;
      }

      final requestData = requestDoc.data()!;
      final fromUserName =
          requestData['fromUserName'] as String? ?? 'Unknown User';

      // Accept the connection request (this automatically adds both users as contacts)
      final success = await ConnectionRequestService.acceptConnectionRequest(
        requestId,
      );

      if (success) {
        print('✅ Connection request accepted successfully');
        _showSnackBar(
          'Connection accepted! $fromUserName added to contacts.',
          Colors.green,
        );
      } else {
        print('❌ Failed to accept connection request');
        _showSnackBar(
          'Failed to accept request. Please try again.',
          Colors.red,
        );
      }
    } catch (e) {
      print('❌ Error accepting connection request: $e');
      _showSnackBar('Error accepting request. Please try again.', Colors.red);
    }
  }

  /// Handle connection accepted notification for User B (the requester)
  static Future<void> _handleConnectionAcceptedNotification(
    DocumentSnapshot doc,
  ) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      print('🎉 Connection accepted notification received: $data');

      // Mark notification as read
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(doc.id)
          .update({'isRead': true});

      // Get the request details to find who accepted
      final requestId = data['requestId'] as String?;
      if (requestId == null) {
        print('❌ No requestId in notification data');
        return;
      }

      // Fetch the connection request to get accepter details
      final requestDoc = await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        print('❌ Connection request not found: $requestId');
        return;
      }

      final requestData = requestDoc.data() as Map<String, dynamic>;
      final accepterName = requestData['toUserName'] as String;

      print('🎉 Contact request accepted by $accepterName');
      _showSnackBar(
        'Your contact request was accepted! $accepterName added to contacts.',
        Colors.green,
      );
    } catch (e) {
      print('❌ Error handling connection accepted notification: $e');
    }
  }

  /// Decline a connection request
  static Future<void> _declineRequest(String requestId) async {
    print('❌ Declining connection request: $requestId');

    final success = await ConnectionRequestService.declineConnectionRequest(
      requestId,
    );

    if (success) {
      print('✅ Connection request declined successfully');
      _showSnackBar('Connection request declined.', Colors.orange);
    } else {
      print('❌ Failed to decline connection request');
      _showSnackBar('Failed to decline request. Please try again.', Colors.red);
    }
  }

  /// Show snackbar message
  static void _showSnackBar(String message, Color color) {
    final context = navigatorKey?.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Check if currently listening
  static bool get isListening => _subscription != null;
}
