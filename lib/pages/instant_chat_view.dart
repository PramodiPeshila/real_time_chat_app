import 'package:flutter/material.dart';
import 'package:realtime_chat_app/services/contact_service.dart';
import 'package:realtime_chat_app/services/connection_request_service.dart';
import 'package:realtime_chat_app/pages/instant_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InstantChatView extends StatefulWidget {
  final String scannedData;

  const InstantChatView({super.key, required this.scannedData});

  @override
  _InstantChatViewState createState() => _InstantChatViewState();
}

class _InstantChatViewState extends State<InstantChatView> {
  Map<String, dynamic>? userData;
  bool isAddedToContacts = false;
  bool isLoadingContact = false;

  @override
  void initState() {
    super.initState();
    _parseUserData();
    _checkIfContact();
  }

  void _parseUserData() {
    try {
      // Remove the curly braces and parse as a map-like string
      String cleanData = widget.scannedData.replaceAll('{', '').replaceAll('}', '');
      Map<String, dynamic> parsedData = {};
      
      List<String> pairs = cleanData.split(', ');
      for (String pair in pairs) {
        List<String> keyValue = pair.split(': ');
        if (keyValue.length == 2) {
          String key = keyValue[0].trim();
          String value = keyValue[1].trim();
          parsedData[key] = value;
        }
      }
      
      setState(() {
        userData = parsedData;
      });
    } catch (e) {
      print('Error parsing user data: $e');
      setState(() {
        userData = {
          'userId': widget.scannedData,
          'displayName': 'Unknown User',
          'email': 'Unknown',
          'type': 'chat_user',
        };
      });
    }
  }

  void _checkIfContact() async {
    if (userData != null) {
      final ownerId = FirebaseAuth.instance.currentUser?.uid;
      final isContact = (ownerId != null && ownerId.isNotEmpty)
          ? await ContactService.isContactRemote(ownerId, userData!['userId'] ?? '')
          : await ContactService.isContact(userData!['userId'] ?? '');
      setState(() {
        isAddedToContacts = isContact;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Contact',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // User Avatar
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
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
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            userData!['displayName'] ?? 'Unknown User',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.email, size: 16, color: Colors.grey),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  userData!['email'] ?? 'No email available',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(
                                'ID: ${userData!['userId']?.toString().substring(0, 8) ?? 'Unknown'}...',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Contact Status
                  if (isAddedToContacts)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Already in your contacts',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      // Start Chat Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _startChat(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 5,
                          ),
                          icon: const Icon(Icons.chat),
                          label: const Text(
                            'Start Chat',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(width: 15),

                      // Add to Contacts Button
                      if (!isAddedToContacts)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isLoadingContact ? null : () => _addToContacts(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 5,
                            ),
                            icon: isLoadingContact 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.person_add),
                            label: Text(
                              isLoadingContact ? 'Sending...' : 'Add Contact',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isLoadingContact ? null : () => _removeFromContacts(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 5,
                            ),
                            icon: isLoadingContact 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.person_remove),
                            label: Text(
                              isLoadingContact ? 'Removing...' : 'Remove Contact',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Start chatting instantly or send a contact request. They will need to confirm before you both become contacts.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _startChat() {
    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start chat. User data not available.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final receiverId = userData!['userId'] ?? '';
    if (receiverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start chat. Missing receiver ID.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

  Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstantChatScreen(
          receiverId: receiverId,
          receiverName: userData!['displayName'] ?? 'Unknown User',
          ephemeral: true,
        ),
      ),
    );
  }

  void _addToContacts() async {
    if (userData == null) return;

    // Show confirmation dialog for User A
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: Text('Do you want to send a contact request to ${userData!['displayName']}? They will need to confirm before you both become contacts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isLoadingContact = true;
    });

    try {
      // Send connection request to User B
      final success = await ConnectionRequestService.sendConnectionRequest(
        toUserId: userData!['userId'] ?? '',
        toUserName: userData!['displayName'] ?? 'Unknown User',
        toUserEmail: userData!['email'] ?? '',
        message: 'Hi! I would like to add you as a contact.',
      );

      setState(() {
        isLoadingContact = false;
      });

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Contact request sent to ${userData!['displayName']}! Waiting for their confirmation.'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send contact request. You may already be contacts or have a pending request.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoadingContact = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending contact request: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removeFromContacts() async {
    if (userData == null) return;

    setState(() {
      isLoadingContact = true;
    });

    try {
      final ownerId = FirebaseAuth.instance.currentUser?.uid;
      final success = await ContactService.deleteContact(userData!['userId'] ?? '', ownerId: ownerId);

      if (success) {
        setState(() {
          isAddedToContacts = false;
          isLoadingContact = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact removed successfully!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          isLoadingContact = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove contact'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoadingContact = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing contact: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
