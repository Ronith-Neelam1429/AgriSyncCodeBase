import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:agrisync/Providers/ThemeProvider.dart';
import 'package:agrisync/App%20Pages/ProfilePage/EditProfilePage.dart';
import 'package:agrisync/Authentication/Pages/LogOrSignPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool notificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchUserData();
  }

  // Load notification preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  // Fetch or initialize user data from Firestore
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (doc.exists) {
          final data = doc.data();
          bool needsUpdate = false;
          Map<String, dynamic> updateData = {};

          if (data?['firstName'] == null && user.displayName != null) {
            final nameParts = user.displayName!.split(' ');
            if (nameParts.isNotEmpty) {
              updateData['firstName'] = nameParts[0];
              updateData['lastName'] = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
              needsUpdate = true;
            }
          }

          if (data?['email'] == null && user.email != null) {
            updateData['email'] = user.email;
            needsUpdate = true;
          }

          if (needsUpdate) {
            await docRef.update(updateData);
            final updatedDoc = await docRef.get();
            setState(() {
              userData = updatedDoc.data();
              _isLoading = false;
            });
          } else {
            setState(() {
              userData = data;
              _isLoading = false;
            });
          }
        } else {
          // Create a new user document
          final newUserData = {
            'firstName': user.displayName != null ? user.displayName!.split(' ')[0] : 'AgriSync',
            'lastName': user.displayName != null && user.displayName!.split(' ').length > 1
                ? user.displayName!.split(' ').sublist(1).join(' ')
                : 'User',
            'email': user.email ?? '',
            'profilePictureUrl': user.photoURL ?? '',
            'location': 'Not specified',
            'farmSize': 'Not specified',
            'preferredCrops': [],
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          };

          await docRef.set(newUserData);

          setState(() {
            userData = newUserData;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome! Your profile has been created')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()),
        (route) => false,
      );
    }
  }

  // Upload a new profile picture
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_pictures/${user.uid}.jpg');
          final uploadTask = storageRef.putFile(File(pickedFile.path));
          await uploadTask.whenComplete(() => null);
          final downloadUrl = await storageRef.getDownloadURL();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'profilePictureUrl': downloadUrl});
          await _fetchUserData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show image source options
  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Sign out
  Future<void> _signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);

      await FirebaseAuth.instance.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading || userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(userData: userData!),
                ),
              ).then((result) {
                if (result == true) {
                  _fetchUserData();
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: userData!['profilePictureUrl'] != null &&
                                userData!['profilePictureUrl'].isNotEmpty
                            ? NetworkImage(userData!['profilePictureUrl'])
                            : null,
                        child: userData!['profilePictureUrl'] == null ||
                                userData!['profilePictureUrl'].isEmpty
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color.fromARGB(255, 35, 167, 182),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: () => _showImageSourceOptions(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${userData!['firstName'] ?? ''} ${userData!['lastName'] ?? ''}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    userData!['email'] ?? 'email@example.com',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      'Farm Owner',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    backgroundColor: const Color.fromARGB(255, 35, 167, 182),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            _buildSectionTitle(context, 'Farm Information'),
            _buildInfoRow(
                context, 'Location', userData!['location'] ?? 'Not specified'),
            _buildInfoRow(
                context, 'Farm Size', userData!['farmSize'] ?? 'Not specified'),
            _buildInfoRow(
                context,
                'Preferred Crops',
                (userData!['preferredCrops'] as List?)?.join(', ') ?? 'Not specified'),
            _buildInfoRow(
              context,
              'Member Since',
              userData!['createdAt'] != null
                  ? (userData!['createdAt'] as Timestamp).toDate().toString()
                  : 'Not specified',
            ),
            const SizedBox(height: 24),
            const Divider(),
            _buildSectionTitle(context, 'App Settings'),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('App Theme'),
              subtitle: Text(themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode'),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                activeColor: const Color.fromARGB(255, 35, 167, 182),
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              subtitle: Text(notificationsEnabled
                  ? 'Enabled - Weather alerts, crop cycles'
                  : 'Disabled'),
              trailing: Switch(
                value: notificationsEnabled,
                activeColor: const Color.fromARGB(255, 35, 167, 182),
                onChanged: (value) async {
                  setState(() {
                    notificationsEnabled = value;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('notificationsEnabled', value);
                },
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            _buildSectionTitle(context, 'Account'),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color.fromARGB(255, 35, 167, 182),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}