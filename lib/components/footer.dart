import 'package:flutter/material.dart';
import 'package:realtime_chat_app/pages/profile_screen.dart';
import 'package:realtime_chat_app/pages/qr_genetator.dart';
import 'package:realtime_chat_app/pages/home_screen.dart';

class Footer extends StatefulWidget {
  const Footer({super.key});

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  int _selectedIndex =
      1; // 0: Conversations, 1: Center (QR), 2: Contacts, 3: Profile

  // Customize icon sizes and colors here
  final double _navIconSize = 28; // size for left/right nav icons
  final Color _selectedIconColor = Colors.black;

  final double _centerFabIconSize = 30; // size for center QR icon
  final Color _centerFabIconColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Bottom navigation items
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                // Conversations (Left)
                _buildNavItem(
                  icon: Icons.chat,

                  label: "Chat",
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
                    // ignore: avoid_print
                    print("Home tapped");
                  },
                ),

                const SizedBox(width: 60), // Space for center FAB
                // Profile (Right)
                _buildNavItem(
                  icon: Icons.person,
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
                    // ignore: avoid_print
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
                // ignore: avoid_print
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
                child: Icon(
                  Icons.qr_code,
                  color: _centerFabIconColor,
                  size: _centerFabIconSize,
                ),
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
    Color iconColor = _selectedIconColor;
    Color textColor = _selectedIconColor;
    FontWeight fontWeight = isSelected ? FontWeight.w600 : FontWeight.normal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: _navIconSize, color: iconColor),
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
