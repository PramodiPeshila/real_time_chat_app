import 'package:flutter/material.dart';
import 'package:realtime_chat_app/components/footer.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Center(
        child: const Text("User Profile"),
      ),
      bottomNavigationBar: const Footer()
    );
  }
}
