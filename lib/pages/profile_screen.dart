import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realtime_chat_app/pages/methods.dart';
// import 'package:realtime_chat_app/components/footer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user data from Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          _userData = userDoc.data();
          _nameController.text = _userData?['name'] ?? user.displayName ?? '';
          _emailController.text = _userData?['email'] ?? user.email ?? '';
          _profileImageUrl = _userData?['profileImage'];
        } else {
          // If no Firestore document exists, use Firebase Auth data
          _nameController.text = user.displayName ?? '';
          _emailController.text = user.email ?? '';
          
          // Create initial user document in Firestore
          await _createInitialUserDocument(user);
        }
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createInitialUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'profileImage': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Name cannot be empty', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update Firebase Auth display name
        await user.updateDisplayName(_nameController.text.trim());

        // Update Firestore document
        await _firestore.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        setState(() {
          _isEditing = false;
        });

        _showSnackBar('Profile updated successfully!');
        await _loadUserData(); // Reload data
      }
    } catch (e) {
      _showSnackBar('Error updating profile: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.blue,
        foregroundColor: Colors.black,
         actions: [
          // Edit / Save button
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              tooltip: 'Edit profile',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          
          
           IconButton(
             icon: const Icon(Icons.logout, color: Colors.black),
             onPressed: () async {
               await logOut();
               if (mounted) {
                 //navigate to new screen
                 Navigator.pushNamedAndRemoveUntil(
                   context, 
                   '/login', 
                   (route) => false,
                 );
               }
             },
           ),
         ],
       ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Picture Section
                  _buildProfilePicture(),
                  const SizedBox(height: 30),
                  
                  // User Info Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Name Field
                          _buildTextField(
                            controller: _nameController,
                            label: 'Name',
                            icon: Icons.person,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 16),
                          
                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            enabled: false, // Email should not be editable
                          ),
                          const SizedBox(height: 20),
                          
                          // Edit/Save Buttons
                          if (_isEditing)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,

                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      // Reset fields
                                      _loadUserData();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                                    side: BorderSide(color: Colors.blue.shade300),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 0, 94, 255),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Save Changes'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Account Info Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // _buildInfoRow('User ID', user?.uid ?? 'N/A'),
                          // const SizedBox(height: 12),
                          _buildInfoRow(
                            'Account Created', 
                            user?.metadata.creationTime != null
                                ? _formatDate(user!.metadata.creationTime!)
                                : 'N/A'
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Last Sign In', 
                            user?.metadata.lastSignInTime != null
                                ? _formatDate(user!.metadata.lastSignInTime!)
                                : 'N/A'
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Generate QR Code Button
                  
                ],
              ),
            ),
    );
  }

  Widget _buildProfilePicture() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color.fromARGB(255, 0, 94, 255),
            backgroundImage: _profileImageUrl != null 
                ? NetworkImage(_profileImageUrl!) 
                : null,
            child: _profileImageUrl == null
                ? Text(
                    _nameController.text.isNotEmpty 
                        ? _nameController.text[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 0, 94, 255),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  onPressed: () {
                    // TODO: Implement image picker
                    _showSnackBar('Photo upload feature coming soon!');
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.shade50 : null,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }



  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
