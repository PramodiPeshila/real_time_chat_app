import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// Firestore
import 'package:realtime_chat_app/views/screens/authenticate.dart';
import 'package:realtime_chat_app/views/screens/loggin_screen.dart';
import 'package:realtime_chat_app/views/screens/welcome_screen.dart';
import 'package:realtime_chat_app/views/widgets/notification_wrapper.dart';
import 'package:realtime_chat_app/controllers/pending_request_watcher.dart';
import 'package:realtime_chat_app/controllers/pending_instant_chat_watcher.dart';
import 'config/firebase_options.dart';

// Global navigator key for showing dialogs from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Debug info
    print('✅ Firebase initialized successfully');
    final opts = Firebase.app().options;
    print('Project ID: ${opts.projectId}');
    print('App ID: ${opts.appId}');
    print('API Key: ${opts.apiKey}');

    // Initialize the PendingRequestWatcher with navigator key
    PendingRequestWatcher.setNavigatorKey(navigatorKey);
    print('✅ PendingRequestWatcher initialized');

    // Initialize the PendingInstantChatWatcher with navigator key
    PendingInstantChatWatcher.setNavigatorKey(navigatorKey);
    print('✅ PendingInstantChatWatcher initialized');

   
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NotificationWrapper(
      child: MaterialApp(
        navigatorKey: navigatorKey, // Add global navigator key
        debugShowCheckedModeBanner: false,
        title: 'LinkTalk',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const Authenticate(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const Logginscreen(),
          '/auth': (context) => const Authenticate(),
        },
      ),
    );
  }
}
