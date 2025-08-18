import 'package:flutter/material.dart';
import 'package:realtime_chat_app/pages/profile_screen.dart';
import 'package:realtime_chat_app/pages/qr_genetator.dart';
import 'package:realtime_chat_app/pages/home_screen.dart';
import 'package:realtime_chat_app/pages/contacts_screen.dart';

class Footer extends StatefulWidget {
  const Footer({super.key});

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  int _selectedIndex = 1; // 0: Conversations, 1: Center (QR), 2: Contacts, 3: Profile

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Bottom navigation items
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Conversations (Left)
                _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  label: "Conversations",
                  index: 0,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                    print("Home tapped");
                  },
                ),

                // Contacts (Center Left)
                _buildNavItem(
                  icon: Icons.contacts_outlined,
                  label: "Contacts",
                  index: 2,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactsScreen(),
                      ),
                    );
                    print("Contacts tapped");
                  },
                ),

                const SizedBox(width: 60), // Space for center FAB

                // Profile (Right)
                _buildNavItem(
                  icon: Icons.person_outline,
                  label: "Profile",
                  index: 3,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 3;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                    print("Profile tapped");
                  },
                ),
              ],
            ),
          ),

          // Center FAB
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 30,
            top: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRGenerator()),
                );
                print("QR Generator opened");
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _selectedIndex == 1
                        ? [Colors.blue, const Color(0xFF4B0082)]
                        : [Colors.blue, const Color(0xFF483D8B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.white,
                  //     blurRadius: 8,
                  //     spreadRadius: 1,
                  //     offset: const Offset(0, 2),
                  //   ),
                  // ],
                ),
                child: const Icon(Icons.qr_code, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    bool isSelected = _selectedIndex == index;
    Color iconColor = isSelected ? Colors.white : Colors.grey[100]!;
    Color textColor = isSelected ? Colors.white : Colors.grey[100]!;
    FontWeight fontWeight = isSelected ? FontWeight.w600 : FontWeight.normal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: textColor,
                fontWeight: fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
