import 'package:flutter/material.dart';
import '../views/screens/welcome_screen.dart';
import '../views/screens/loggin_screen.dart';
import '../views/screens/create_account.dart';
import '../views/screens/home_screen.dart';
import '../views/screens/contacts_screen.dart';
import '../views/screens/profile_screen.dart';
import '../views/screens/qr_genetator.dart';
import '../views/screens/qr_scanner.dart';
import '../views/screens/instant_chat_screen.dart';
import '../views/screens/instant_chat_view.dart';
import '../views/screens/connection_requests_page.dart';

class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String createAccount = '/create-account';
  static const String home = '/home';
  static const String contacts = '/contacts';
  static const String profile = '/profile';
  static const String qrGenerator = '/qr-generator';
  static const String qrScanner = '/qr-scanner';
  static const String instantChat = '/instant-chat';
  static const String instantChatView = '/instant-chat-view';
  static const String connectionRequests = '/connection-requests';

  static Map<String, WidgetBuilder> get routes => {
    welcome: (context) => const WelcomeScreen(),
    login: (context) => const Logginscreen(),
    createAccount: (context) => const CreateAccount(),
    home: (context) => const HomeScreen(),
    contacts: (context) => const ContactsScreen(),
    profile: (context) => const ProfileScreen(),
    qrGenerator: (context) => const QRGenerator(),
    qrScanner: (context) => const QRScanner(),
    connectionRequests: (context) => const ConnectionRequestsPage(),
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case instantChat:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => InstantChatScreen(
              receiverId: args['receiverId'],
              receiverName: args['receiverName'],
              ephemeral: args['ephemeral'] ?? false,
            ),
          );
        }
        break;
      case instantChatView:
        final args = settings.arguments as Map<String, String>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) =>
                InstantChatView(scannedData: args['scannedData']!),
          );
        }
        break;
    }
    return null;
  }
}
