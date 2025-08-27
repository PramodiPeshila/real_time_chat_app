import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:realtime_chat_app/views/screens/connection_requests_page.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static StreamSubscription<QuerySnapshot>? _notificationSubscription;

  /// Start listening for real-time notifications
  static void startListening(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _notificationSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final notification = change.doc.data() as Map<String, dynamic>;
              // Only handle unread notifications
              if (notification['read'] == false) {
                _handleNewNotification(context, notification, change.doc.id);
              }
            }
          }
        });
  }

  /// Stop listening for notifications
  static void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  /// Handle new notification
  static void _handleNewNotification(
    BuildContext context,
    Map<String, dynamic> notification,
    String notificationId,
  ) {
    final type = notification['type'];
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? '';
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    if (type == 'connection_request') {
      _showConnectionRequestDialog(context, title, body, data, notificationId);
    } else {
      _showGeneralNotification(context, title, body, notificationId);
    }
  }

  /// Show connection request dialog
  static void _showConnectionRequestDialog(
    BuildContext context,
    String title,
    String body,
    Map<String, dynamic> data,
    String notificationId,
  ) {
    // Only show if the context is valid and mounted
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(body, style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can accept or decline this request in the Connection Requests page.',
                        style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _markAsRead(notificationId);
              },
              child: Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _markAsRead(notificationId);

                // Navigate to connection requests page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConnectionRequestsPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('View Requests'),
            ),
          ],
        );
      },
    );
  }

  /// Show general notification
  static void _showGeneralNotification(
    BuildContext context,
    String title,
    String body,
    String notificationId,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (body.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(body, style: TextStyle(color: Colors.white)),
            ],
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    _markAsRead(notificationId);
  }

  /// Mark notification as read
  static Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Get unread notification count
  static Stream<int> getUnreadCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.where((doc) => doc.data()['read'] == false).length,
        );
  }

  /// Clear all notifications for current user
  static Future<void> clearAllNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      for (final doc in notifications.docs) {
        // Only update unread notifications
        if (doc.data()['read'] == false) {
          batch.update(doc.reference, {'read': true});
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
}
