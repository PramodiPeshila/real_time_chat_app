import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:realtime_chat_app/pages/authenticate.dart';
import 'package:realtime_chat_app/pages/loggin_screen.dart';
import 'package:realtime_chat_app/pages/welcome_screen.dart';
import 'firebase_options.dart';

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

    // 🔹 Test Firestore connection (optional)
    // await FirebaseFirestore.instance.collection("test").add({
    //   "message": "Hello Firestore 🚀",
    //   "timestamp": DateTime.now(),
    // });
    // print("✅ .yeeeeeeeeeeeeeeeeeeeh.Test document added to Firestore");
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LinkTalk',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const Logginscreen(),
        '/auth': (context) => const Authenticate(),
      },
    );
  }
}
