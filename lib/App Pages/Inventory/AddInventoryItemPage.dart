import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddInventoryItemPage extends StatefulWidget {
  const AddInventoryItemPage({Key? key}) : super(key: key);

  @override
  _AddInventoryItemPageState createState() => _AddInventoryItemPageState();
}

class _AddInventoryItemPageState extends State<AddInventoryItemPage> {
  final _formKey = GlobalKey<FormState>(); // Key to manage the form
  final FirebaseAuth _auth = FirebaseAuth.instance; // Auth hookup
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore hookup

  // Inventory fields
  String _name = '';
  String _variety = '';
  String _internalSKU = '';
  String _electronicID = '';
  String _inventoryUnit = 'Units'; // Default unit type
  double _unitsInStock = 0.0;
  double _usagePerWeek = 0.0;
  double _alertThreshold = 0.0;

  final List<String> _unitTypes = ['Units', 'Pounds', 'Kilograms', 'Liters']; // Options for unit dropdown

  // Saves the item to Firestore
  void _saveInventoryItem() async {
    if (!_formKey.currentState!.validate()) return; // Stop if form’s not valid
    _formKey.currentState!.save(); // Grab all the form data

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      return;
    }

    try {
      await _firestore
          .collection('inventory')
          .doc(user.uid)
          .collection('items')
          .add({
        'name': _name.trim(),
        'variety': _variety.trim(),
        'internalSKU': _internalSKU.trim(),
        'electronicID': _electronicID.trim(),
        'inventoryUnit': _inventoryUnit,
        'unitsInStock': _unitsInStock,
        'usagePerWeek': _usagePerWeek,
        'alertThreshold': _alertThreshold,
        'timestamp': FieldValue.serverTimestamp(), // Add a timestamp for sorting later
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inventory item added successfully.")),
      );
      Navigator.pop(context); // Go back after saving
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving item: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Inventory Item',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration('Name (e.g. Seed)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!, // Save the name
              ),
              const SizedBox(height: 16),
              // Variety
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration('Variety (e.g. Corn)'),
                onSaved: (value) => _variety = value ?? '', // Optional field
              ),
              const SizedBox(height: 16),
              // Internal SKU
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration('Internal ID / SKU'),
                onSaved: (value) => _internalSKU = value ?? '',
              ),
              const SizedBox(height: 16),
              // Electronic ID
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration('Electronic ID'),
                onSaved: (value) => _electronicID = value ?? '',
              ),
              const SizedBox(height: 16),
              // Inventory Unit
              DropdownButtonFormField<String>(
                value: _inventoryUnit,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration('Inventory Unit'),
                items: _unitTypes.map((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _inventoryUnit = value!), // Update unit type
              ),
              const SizedBox(height: 16),
              // Units in Stock
              TextFormField(
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Units In Stock'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a stock quantity';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) => _unitsInStock = double.parse(value!),
              ),
              const SizedBox(height: 16),
              // Usage per week
              TextFormField(
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Usage Per Week'),
                validator: (value) {
                  if (value == null || value.isEmpty) return null; // optional
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  if (value == null || value.isEmpty) {
                    _usagePerWeek = 0.0; // Default to 0 if empty
                  } else {
                    _usagePerWeek = double.parse(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Alert Threshold
              TextFormField(
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Alert When Less Than'),
                validator: (value) {
                  if (value == null || value.isEmpty) return null; // optional
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  if (value == null || value.isEmpty) {
                    _alertThreshold = 0.0; // Default to 0 if empty
                  } else {
                    _alertThreshold = double.parse(value);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveInventoryItem, // Hit this to save
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 66, 192, 201),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                ),
                child: const Text(
                  'Save Item',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable styling for text fields
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color.fromARGB(255, 66, 192, 201)),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}