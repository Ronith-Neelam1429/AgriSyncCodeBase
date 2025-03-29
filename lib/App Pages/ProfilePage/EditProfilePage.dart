import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _locationController;
  late TextEditingController _farmSizeController;
  late TextEditingController _preferredCropsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.userData['firstName']);
    _lastNameController = TextEditingController(text: widget.userData['lastName']);
    _locationController = TextEditingController(text: widget.userData['location'] ?? '');
    _farmSizeController = TextEditingController(text: widget.userData['farmSize'] ?? '');
    _preferredCropsController = TextEditingController(
      text: (widget.userData['preferredCrops'] as List?)?.join(', ') ?? '',
    );
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final updatedData = {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'location': _locationController.text.trim(),
          'farmSize': _farmSizeController.text.trim(),
          'preferredCrops': _preferredCropsController.text.split(',').map((e) => e.trim()).toList(),
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updatedData);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _locationController.dispose();
    _farmSizeController.dispose();
    _preferredCropsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _farmSizeController,
                      decoration: const InputDecoration(labelText: 'Farm Size'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _preferredCropsController,
                      decoration: const InputDecoration(
                          labelText: 'Preferred Crops (comma-separated)'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}