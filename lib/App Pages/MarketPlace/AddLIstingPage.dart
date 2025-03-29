import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddListingPage extends StatefulWidget {
  @override
  _AddListingPageState createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _name = '';
  double _price = 0.0;
  String _condition = 'New';
  String _list = 'Equipment';
  String _imageUrl = '';
  String _retailURL = '';
  String _retailer = '';
  String _category = 'Equipment';

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

  void _submitListing() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('marketPlace').add({
            'name': _name,
            'price': _price,
            'condition': _condition,
            'list': _list,
            'category': _category,
            'imageUrl': _imageUrl,
            'retailURL': _retailURL,
            'retailer': _retailer,
            'listedBy': user.uid, // Add the user who listed the item
            'timestamp': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Listing added successfully!')),
          );

          Navigator.pop(context); // Go back to the previous page
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
        title: Text('Add New Listing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Price'),
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
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: InputDecoration(labelText: 'Condition'),
                items: _conditions.map((String condition) {
                  return DropdownMenuItem<String>(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _condition = value!),
              ),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(labelText: 'Category'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Image URL'),
                onSaved: (value) => _imageUrl = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Retail URL'),
                onSaved: (value) => _retailURL = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Retailer'),
                onSaved: (value) => _retailer = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitListing,
                child: Text('Submit Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
