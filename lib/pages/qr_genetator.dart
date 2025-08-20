import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:realtime_chat_app/components/footer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:realtime_chat_app/pages/qr_scanner.dart';

class QRGenerator extends StatefulWidget {
  const QRGenerator({super.key});

  @override
  _QRGeneratorState createState() => _QRGeneratorState();
}

class _QRGeneratorState extends State<QRGenerator> {
  String? userQRData;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _generateUserQRData();
  }

  void _generateUserQRData() {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Create QR data with user information
      userQRData = {
        'userId': currentUser!.uid,
        'email': currentUser!.email ?? 'No email',
        'displayName': currentUser!.displayName ?? 'User',
        'type': 'chat_user',
      }.toString();
    } else {
      // Fallback for testing without Firebase
      userQRData = {
        'userId': 'demo_user_123',
        'email': 'demo@example.com',
        'displayName': 'Demo User',
        'type': 'chat_user',
      }.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My QR Code',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(255, 0, 94, 255),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 0, 94, 255).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),

              const SizedBox(height: 20),

              // User Info
              Text(
                currentUser?.displayName ?? 'Demo User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                currentUser?.email ?? 'demo@example.com',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),

              const SizedBox(height: 30),

              // QR Code Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (userQRData != null)
                      QrImageView(
                        data: userQRData!,
                        version: QrVersions.auto,
                        size: 230.0,
                        gapless: false,
                        backgroundColor: Colors.white,
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: Color.fromARGB(255, 0, 94, 255),
                        ),
                      )
                    else
                      const CircularProgressIndicator(),

                    const SizedBox(height: 15),

                    Text(
                      'Let others scan this code to start chatting!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Share Button
                  

                  // Scan Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QRScanner(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 94, 255),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan' , style: TextStyle(fontWeight: FontWeight.w700 , fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }

  
}
