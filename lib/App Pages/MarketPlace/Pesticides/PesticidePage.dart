import 'package:agrisync/App%20Pages/MarketPlace/Models/ItemPage.dart';
import 'package:agrisync/App%20Pages/MarketPlace/Models/ListingModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PesticidesPage extends StatefulWidget {
  @override
  _PesticidesPageState createState() => _PesticidesPageState();
}

class _PesticidesPageState extends State<PesticidesPage> {
  String selectedFilter = 'All';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RangeValues _priceRange =
      const RangeValues(0, 10000); // Adjusted for pesticide pricing

  final List<String> filters = [
    'All',
    'Organic',
    'Chemical',
    'Insecticide',
    'Herbicide',
    'Fungicide'
  ];

  Stream<List<EquipmentListing>> getFilteredListings() {
    // Start with base query and add list filter
    Query query = _firestore
        .collection('marketPlace')
        .where('list', isEqualTo: 'Pesticide');

    // Add condition filter if selected
    if (selectedFilter != 'All') {
      query = query.where('condition', isEqualTo: selectedFilter);
    }

    return query.snapshots().map((snapshot) {
      List<EquipmentListing> validListings = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          double price = 0.0;
          var rawPrice = data['price'];
          if (rawPrice is num) {
            price = rawPrice.toDouble();
          } else if (rawPrice is String) {
            price = double.tryParse(rawPrice) ?? 0.0;
          }

          final listing = EquipmentListing(
            name: data['name'] as String? ?? '',
            price: price,
            condition: data['condition'] as String? ?? '',
            imageUrl: data['imageURL'] as String? ?? '',
            list: data['list'] as String? ?? '',
            category: data['category'] as String? ?? '',
            retailURL: data['retailURL'] as String? ?? '',
            retailer: data['retailer'] as String? ?? '', listedBy: '',
          );

          if (listing.price >= _priceRange.start &&
              listing.price <= _priceRange.end) {
            validListings.add(listing);
          }
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
          continue;
        }
      }

      return validListings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            title: const Text('Pesticides'),
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search pesticides...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Filters Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filters.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(filters[index]),
                        selected: selectedFilter == filters[index],
                        onSelected: (bool selected) {
                          setState(() {
                            selectedFilter = filters[index];
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.orange.shade100,
                        checkmarkColor: Colors.orange.shade800,
                        labelStyle: TextStyle(
                          color: selectedFilter == filters[index]
                              ? Colors.orange.shade800
                              : Colors.black87,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selectedFilter == filters[index]
                                ? Colors.orange.shade800
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Listings Grid
          StreamBuilder<List<EquipmentListing>>(
            stream: getFilteredListings(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final listings = snapshot.data ?? [];

              if (listings.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No listings found')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final listing = listings[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemPage(item: listing),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image container with fixed or proportional height
                              Expanded(
                                flex: 3, // Allocate 3/5 of space to image
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  child: Image.network(
                                    listing.imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Text content with flexible height
                              Expanded(
                                flex:
                                    2, // Allocate 2/5 of space to text content
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing.name,
                                        style: const TextStyle(
                                          fontSize: 13, // Slightly smaller font
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines:
                                            1, // Limit to 1 line initially
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '\$${listing.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14, // Slightly smaller font
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        listing.condition,
                                        style: TextStyle(
                                          fontSize:
                                              11, // Smaller font for condition
                                          color: Colors.grey[600],
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
                    },
                    childCount: listings.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: MediaQuery.of(context).size.width > 400
                        ? 0.85
                        : 0.75, // Responsive aspect ratio
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
