// lib/App Pages/Inventory/InventoryPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AddInventoryItemPage.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Auth hookup
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore hookup

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) { // Check if user’s logged in
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Inventory',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        body: const Center(
          child: Text(
            "You must be logged in to view inventory.",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventory',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('inventory')
            .doc(user.uid)
            .collection('items')
            .orderBy('name', descending: false)
            .snapshots(), // Live feed of inventory items, sorted by name
        builder: (context, snapshot) {
          if (snapshot.hasError) { // Handle any errors
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.black),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Show spinner while loading
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No inventory available. Tap the + button to add items.",
                style: TextStyle(color: Colors.black),
              ),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id; // Grab the item’s ID

              // Pull out the data with defaults if missing
              final name = data['name'] ?? 'Unnamed';
              final variety = data['variety'] ?? '';
              final sku = data['internalSKU'] ?? '';
              final unitsInStock = data['unitsInStock'] ?? 0;
              final usagePerWeek = (data['usagePerWeek'] ?? 0).toDouble();
              final alertThreshold = data['alertThreshold'] ?? 0;
              final eID = data['electronicID'] ?? '';
              final unitType = data['inventoryUnit'] ?? 'Units';

              // Calculate weeks left if usagePerWeek > 0
              double weeksLeft = 0;
              if (usagePerWeek > 0) {
                weeksLeft = unitsInStock / usagePerWeek;
              }

              bool isLow = unitsInStock < alertThreshold; // Flag if stock’s below threshold

              return Card(
                color: Colors.grey[100],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    '$name ($variety)',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SKU: $sku, eID: $eID',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'In Stock: $unitsInStock $unitType',
                        style: TextStyle(
                          color: isLow ? Colors.red : Colors.black, // Red if low
                          fontSize: 13,
                        ),
                      ),
                      if (usagePerWeek > 0)
                        Text(
                          'Usage/Week: $usagePerWeek $unitType, ~${weeksLeft.toStringAsFixed(1)} weeks left',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                    ],
                  ),
                  trailing: isLow
                      ? const Icon(Icons.warning, color: Colors.red) // Warn if low
                      : const SizedBox(width: 1),
                  onTap: () {
                    // Optionally navigate to a detail or edit page if needed
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 66, 192, 201),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInventoryItemPage()), // Go to add item page
          );
        },
      ),
    );
  }
}