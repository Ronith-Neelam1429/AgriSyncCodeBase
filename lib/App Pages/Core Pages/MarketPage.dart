import 'package:agrisync/App%20Pages/Core%20Pages/MarketPlace/Equipment/EquipmentPage.dart';
import 'package:agrisync/App%20Pages/Core%20Pages/MarketPlace/Fertilizers/FertilizerPage.dart';
import 'package:agrisync/App%20Pages/Core%20Pages/MarketPlace/Seeds/SeedsPage.dart';
import 'package:flutter/material.dart';

class MarketPlacePage extends StatefulWidget {
  const MarketPlacePage({super.key});

  @override
  State<MarketPlacePage> createState() => _MarketPlacePageState();
}

class _MarketPlacePageState extends State<MarketPlacePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Title and Notification Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Title and Notification Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Marketplace',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {
                            // Handle notification tap
                          },
                          iconSize: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    Container(
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
                          hintText: 'Search equipment, seeds, supplies...',
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
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
                child: Text(
                  'Pick a category',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Categories Grid
            SliverPadding(
              padding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  _buildCategoryCard(
                    'Equipment',
                    'Tractors, tools, and machinery',
                    Icons.agriculture,
                    Colors.orange,
                  ),
                  _buildCategoryCard(
                    'Seeds',
                    'Quality seeds for better yield',
                    Icons.grass,
                    Colors.green,
                  ),
                  _buildCategoryCard(
                    'Fertilizers',
                    'Organic and chemical fertilizers',
                    Icons.science,
                    Colors.blue,
                  ),
                  _buildCategoryCard(
                    'Irrigation',
                    'Modern irrigation solutions',
                    Icons.water_drop,
                    Colors.lightBlue,
                  ),
                  _buildCategoryCard(
                    'Pesticides',
                    'Crop protection products',
                    Icons.bug_report,
                    Colors.red,
                  ),
                  _buildCategoryCard(
                    'Tools',
                    'Hand tools and equipment',
                    Icons.handyman,
                    Colors.brown,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (title == 'Equipment') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EquipmentPage()),
              );
            } else if (title == 'Seeds') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SeedsPage()),
              );
            } else if (title == 'Fertilizers') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FertilizersPage()),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}