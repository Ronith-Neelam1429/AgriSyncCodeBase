import 'package:agrisync/App%20Pages/ProfilePage/EditProfilePage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrisync/Authentication/Pages/LogOrSignPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData; // Holds user info from Firestore
  bool isDarkMode = false;
  bool notificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load saved settings
    _fetchUserData(); // Grab user data when page starts
  }

  // Pulls theme and notification prefs from storage
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  // Fetches or creates user data in Firestore
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true; // Show loading while fetching
    });
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
            
        final doc = await docRef.get();
        
        if (doc.exists) {
          final data = doc.data();
          
          // Check if we need to fill in missing stuff
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
          // No doc yet, so make one with defaults
          final newUserData = {
            'firstName': user.displayName != null ? user.displayName!.split(' ')[0] : 'AgriSync',
            'lastName': user.displayName != null && user.displayName!.split(' ').length > 1 
                       ? user.displayName!.split(' ').sublist(1).join(' ') : 'User',
            'email': user.email ?? '',
            'profilePictureUrl': user.photoURL ?? '',
            'location': 'Not specified',
            'farmSize': 'Not specified',
            'preferredCrops': [],
            'uid': user.uid,
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
      // No user, kick them to login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()),
        (route) => false,
      );
    }
  }

  // Picks and uploads a new profile pic
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
          await storageRef.putFile(File(pickedFile.path));
          final downloadUrl = await storageRef.getDownloadURL();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'profilePictureUrl': downloadUrl,
          });
          await _fetchUserData(); // Refresh data after upload
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Shows options for picking a photo
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

  // Signs the user out and clears stuff
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
        (route) => false, // Wipe the stack and go to login
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // Show spinner while loading
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(userData: userData!), // Go to edit page
                ),
              ).then((_) => _fetchUserData()); // Refresh data when back
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
                  ? (userData!['createdAt'] as Timestamp).toDate().year.toString()
                  : 'Not specified',
            ),

            const SizedBox(height: 24),
            const Divider(),

            _buildSectionTitle(context, 'App Settings'),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('App Theme'),
              subtitle: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
              trailing: Switch(
                value: isDarkMode,
                activeColor: const Color.fromARGB(255, 35, 167, 182),
                onChanged: (value) async {
                  setState(() {
                    isDarkMode = value;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isDarkMode', value); // Save theme choice
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              subtitle: Text(notificationsEnabled
                  ? 'Enabled - Weather alerts, crop cycles, market updates'
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
            ListTile(
              leading: const Icon(Icons.straighten),
              title: const Text('Units of Measurement'),
              subtitle: const Text('Metric System'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Units settings to be implemented')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: const Text('English'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Language settings to be implemented')),
                );
              },
            ),

            const SizedBox(height: 24),
            const Divider(),

            _buildSectionTitle(context, 'Account'),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Connected Services'),
              subtitle: const Text('Weather API, Market Integration, Soil Sensors'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Connected services to be implemented')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Farm Data'),
              subtitle: const Text('Download your data in CSV or PDF format'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Data export to be implemented')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Privacy & Security'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Privacy settings to be implemented')),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _signOut,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds section headers
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

  // Builds info rows for farm details
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