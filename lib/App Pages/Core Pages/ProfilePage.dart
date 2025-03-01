import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isDarkMode = false;
  bool notificationsEnabled = true;

  // Mock user data - in a real app, this would come from a user service or state management
  final Map<String, dynamic> userData = {
    'name': 'John Farmer',
    'email': 'john.farmer@example.com',
    'location': 'Midwest Region',
    'farmSize': '250 acres',
    'preferredCrops': ['Corn', 'Soybeans', 'Wheat'],
    'memberSince': '2023',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to profile edit page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Edit profile functionality will be implemented')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header with image
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: const NetworkImage(
                          'https://www.example.com/placeholder.jpg', // Replace with actual image in production
                        ),
                        onBackgroundImageError: (_, __) {},
                        child: const Icon(Icons.person,
                            size: 60, color: Colors.grey),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              const Color.fromARGB(255, 35, 167, 182),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.white),
                            onPressed: () {
                              _showImageSourceOptions(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userData['name'] ?? 'User Name',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    userData['email'] ?? 'email@example.com',
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

            // Farm information section
            _buildSectionTitle(context, 'Farm Information'),
            _buildInfoRow(
                context, 'Location', userData['location'] ?? 'Not specified'),
            _buildInfoRow(
                context, 'Farm Size', userData['farmSize'] ?? 'Not specified'),
            _buildInfoRow(
                context,
                'Preferred Crops',
                (userData['preferredCrops'] as List<String>?)?.join(', ') ??
                    'Not specified'),
            _buildInfoRow(context, 'Member Since',
                userData['memberSince'] ?? 'Not specified'),

            const SizedBox(height: 24),
            const Divider(),

            // App settings section
            _buildSectionTitle(context, 'App Settings'),

            // Theme mode toggle
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('App Theme'),
              subtitle: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
              trailing: Switch(
                value: isDarkMode,
                activeColor: Color.fromARGB(255, 35, 167, 182),
                onChanged: (value) {
                  setState(() {
                    isDarkMode = value;
                  });
                  // In a real app, you would update the theme in a theme provider
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${value ? "Dark" : "Light"} mode will be applied'),
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
                },
              ),
            ),

            // Notifications toggle
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              subtitle: Text(notificationsEnabled
                  ? 'Enabled - Weather alerts, crop cycles, market updates'
                  : 'Disabled'),
              trailing: Switch(
                value: notificationsEnabled,
                activeColor: Color.fromARGB(255, 35, 167, 182),
                onChanged: (value) {
                  setState(() {
                    notificationsEnabled = value;
                  });
                  // In a real app, you would handle notification permissions here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Notifications ${value ? "enabled" : "disabled"}'),
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
                },
              ),
            ),

            // Units of measurement
            ListTile(
              leading: const Icon(Icons.straighten),
              title: const Text('Units of Measurement'),
              subtitle: const Text('Metric System'),
              onTap: () {
                // Show dialog to change measurement units
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Units of measurement settings will be implemented')),
                );
              },
            ),

            // Language selection
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: const Text('English'),
              onTap: () {
                // Show language selection dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Language settings will be implemented')),
                );
              },
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Account actions section
            _buildSectionTitle(context, 'Account'),

            // Connected services
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Connected Services'),
              subtitle:
                  const Text('Weather API, Market Integration, Soil Sensors'),
              onTap: () {
                // Navigate to connected services page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Connected services page will be implemented')),
                );
              },
            ),

            // Export data
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text(
                'Export Farm Data',
              ),
              subtitle: const Text('Download your data in CSV or PDF format'),
              onTap: () {
                // Show export options
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Data export functionality will be implemented')),
                );
              },
            ),

            // Privacy settings
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Privacy & Security'),
              onTap: () {
                // Navigate to privacy settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Privacy settings page will be implemented')),
                );
              },
            ),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    // Handle logout
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Logout functionality will be implemented')),
                    );
                  },
                ),
              ),
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
        style: TextStyle(
          color: const Color.fromARGB(255, 35, 167, 182),
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
                  // Handle camera capture
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Camera functionality will be implemented')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Handle gallery selection
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Gallery selection will be implemented')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
