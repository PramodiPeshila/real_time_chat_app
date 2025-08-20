import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:realtime_chat_app/controllers/pending_request_watcher.dart';
import 'package:realtime_chat_app/controllers/pending_instant_chat_watcher.dart';

class NotificationWrapper extends StatefulWidget {
  final Widget child;

  const NotificationWrapper({super.key, required this.child});

  @override
  State<NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<NotificationWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is signed in, start listening for connection requests and instant messages
        // ignore: avoid_print
        print('🔔 User authenticated, starting PendingRequestWatcher');
        PendingRequestWatcher.startListening();

        print('🔔 User authenticated, starting PendingInstantChatWatcher');
        PendingInstantChatWatcher.startListening();
      } else {
        // User is signed out, stop listening for connection requests and instant messages
        print('🔕 User signed out, stopping PendingRequestWatcher');
        PendingRequestWatcher.stopListening();

        print('🔕 User signed out, stopping PendingInstantChatWatcher');
        PendingInstantChatWatcher.stopListening();
      }
    });
  }

  @override
  void dispose() {
    // Stop watching for connection requests and instant messages when disposing
    PendingRequestWatcher.stopListening();
    PendingInstantChatWatcher.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
