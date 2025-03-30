import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AddListingPage extends StatefulWidget {
  @override
  _AddListingPageState createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // Form fields
  String _name = '';
  double _price = 0.0;
  String _condition = 'New';
  String _list = 'Equipment';
  String _retailURL = '';
  String _retailer = '';
  String _category = 'Equipment';
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<String> _conditions = [
    'New',
    'Used',
    'On Sale',
    'Featured',
    'Local'
  ];
  final List<String> _categories = [
    'Equipment',
    'Seeds',
    'Fertilizers',
    'Irrigation',
    'Pesticides',
    'Tools'
  ];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('marketplace_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(_selectedImage!);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      await uploadTask;
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _submitListing() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Upload image first
      final imageUrl = await _uploadImage();
      if (_selectedImage != null && imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
        return;
      }

      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('marketPlace').add({
            'name': _name,
            'price': _price,
            'condition': _condition,
            'list': _list,
            'category': _category,
            'imageUrl': imageUrl ?? '',
            'retailURL': _retailURL,
            'retailer': _retailer,
            'listedBy': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing added successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding listing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Listing'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image Upload Section
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 1,
                    ),
                  ),
                  child: _isUploading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _uploadProgress,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Uploading... ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_a_photo, 
                                    size: 40, 
                                    color: Colors.grey),
                                SizedBox(height: 10),
                                Text('Tap to add photo',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),

              // Price Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) => _price = double.parse(value!),
              ),
              const SizedBox(height: 16),

              // Condition Dropdown
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: _conditions.map((String condition) {
                  return DropdownMenuItem<String>(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _condition = value!),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 16),

              // Retail URL
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Retail URL (optional)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _retailURL = value ?? '',
              ),
              const SizedBox(height: 16),

              // Retailer
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Retailer (optional)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _retailer = value ?? '',
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isUploading ? null : _submitListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}