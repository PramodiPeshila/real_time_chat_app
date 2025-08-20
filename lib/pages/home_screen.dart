import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:realtime_chat_app/components/footer.dart';
import 'package:realtime_chat_app/services/instant_chat_service.dart';
import 'package:realtime_chat_app/pages/instant_chat_screen.dart';
import 'package:realtime_chat_app/pages/contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, Map<String, dynamic>> _userCache = {};
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<String> _getUserName(String userId) async {
    if (_userCache.containsKey(userId)) {
      final cached = _userCache[userId]!;
      return (cached['displayName'] as String?) ??
          (cached['name'] as String?) ??
          'Unknown';
    }
    final info = await InstantChatService.getUserInfo(userId);
    if (info != null) {
      _userCache[userId] = info;
      return (info['displayName'] as String?) ??
          (info['name'] as String?) ??
          'Unknown';
    }
    return 'Unknown';
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 1) {
      return '${dt.day}/${dt.month}/${dt.year}';
    } else {
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.hour}:$m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          child: Row(
            children: [
              Image.asset("lib/assets/icon.png", width: 50, height: 50),
              const SizedBox(width: 8),
              const Text(
                'LinkTalk',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.blue,
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 245, 247, 250),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _currentUserId.isEmpty
                    ? const Center(child: Text('Please sign in to view chats'))
                    : StreamBuilder<QuerySnapshot>(
                        stream: InstantChatService.getChatRooms(_currentUserId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          final docs = snapshot.data?.docs.toList() ?? [];
                          // Sort by lastMessageTime desc client-side
                          docs.sort((a, b) {
                            final ad = (a.data() as Map<String, dynamic>);
                            final bd = (b.data() as Map<String, dynamic>);
                            final at = ad['lastMessageTime'] as Timestamp?;
                            final bt = bd['lastMessageTime'] as Timestamp?;
                            final atMillis = at?.millisecondsSinceEpoch ?? 0;
                            final btMillis = bt?.millisecondsSinceEpoch ?? 0;
                            return btMillis.compareTo(atMillis);
                          });
                          if (docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.chat,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No Chat yet',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Welcome to LinkTalk',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;
                                final List participants =
                                    (data['participants'] as List?) ?? [];
                                final otherId =
                                    participants.firstWhere(
                                          (p) => p != _currentUserId,
                                          orElse: () => '',
                                        )
                                        as String;
                                final lastMsg =
                                    (data['lastMessage'] as String?) ?? '';
                                final lastTime =
                                    data['lastMessageTime'] as Timestamp?;
                                if (otherId.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,

                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: FutureBuilder<String>(
                                    future: _getUserName(otherId),
                                    builder: (context, nameSnap) {
                                      final otherName =
                                          nameSnap.data ?? 'Unknown';
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: const Color.fromARGB(
                                            255,
                                            0,
                                            94,
                                            255,
                                          ),
                                          child: Text(
                                            otherName.isNotEmpty
                                                ? otherName[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          otherName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          lastMsg,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Text(
                                          _formatTime(lastTime),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => InstantChatScreen(
                                                receiverId: otherId,
                                                receiverName: otherName,
                                                ephemeral: false,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactsScreen()),
            );
          },
          backgroundColor: const Color.fromARGB(255, 0, 94, 255),
          child: const Icon(Icons.contacts_rounded, color: Colors.white),
        ),
      ),
    );
  }
}
