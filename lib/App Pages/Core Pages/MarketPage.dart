import 'package:agrisync/App%20Pages/Core%20Pages/MarketPlace/DatabaseService.dart';
import 'package:agrisync/App%20Pages/Core%20Pages/MarketPlace/Equipment/EquipmentPage.dart';
import 'package:agrisync/App%20Pages/Core%20Pages/MarketPlace/Fertilizers/FertilizerPage.dart';
import 'package:agrisync/App%20Pages/Core%20Pages/MarketPlace/Irrigation/IrrigationPage.dart';
import 'package:agrisync/App%20Pages/Core%20Pages/MarketPlace/NotificationModel.dart';
import 'package:agrisync/App%20Pages/Core%20Pages/MarketPlace/Pesticides/PesticidePage.dart';
import 'package:agrisync/App%20Pages/Core%20Pages/MarketPlace/Seeds/SeedsPage.dart';
import 'package:agrisync/App%20Pages/Core%20Pages/MarketPlace/Tools/ToolsPage.dart';
import 'package:flutter/material.dart';

class MarketPlacePage extends StatefulWidget {
  const MarketPlacePage({super.key});

  @override
  State<MarketPlacePage> createState() => _MarketPlacePageState();
}

class _MarketPlacePageState extends State<MarketPlacePage> {
  // List to store notifications
  List<ItemNotification> notifications = [];
  // Flag to control notification panel visibility
  bool _showNotificationPanel = false;

  @override
  void initState() {
    super.initState();
    print("MarketPlacePage initState called");

    // Load existing data first - now returns a Future
    DatabaseService.loadExistingData().then((_) {
      // Then set up listeners for new changes
      DatabaseService.initializeAllListeners();

      // Listen to notification stream
      DatabaseService.notificationStream.listen((newNotification) {
        print(
            "Notification received from stream: ${newNotification.name}, isRead: ${newNotification.isRead}");
        setState(() {
          // Check if notification already exists in our list
          final existingIndex =
              notifications.indexWhere((n) => n.id == newNotification.id);

          if (existingIndex >= 0) {
            // Update existing notification
            notifications[existingIndex] = newNotification;
          } else {
            // Add new notification
            notifications.add(newNotification);
          }
        });
      }, onError: (error) {
        print("Error from notification stream: $error");
      });
    });
  }

  // Method to listen for database changes
  void _listenForNewItems() {
    // Use initializeAllListeners instead of just initializeListeners
    DatabaseService.initializeAllListeners();

    // Listen to notification stream
    DatabaseService.notificationStream.listen((newNotification) {
      setState(() {
        notifications.add(newNotification);
      });
    });
  }

  @override
  void dispose() {
    // Clean up database service
    DatabaseService.dispose();
    super.dispose();
  }

  // Method to mark all notifications as read
  void _markAllAsRead() async {
    // Collect IDs of all unread notifications
    final unreadIds = notifications
        .where((notification) => !notification.isRead)
        .map((notification) => notification.id)
        .toList();

    if (unreadIds.isNotEmpty) {
      // Mark notifications as read in DatabaseService
      await DatabaseService.markNotificationsAsRead(unreadIds);

      // Update UI
      setState(() {
        for (var notification in notifications) {
          notification.isRead = true;
        }
        _showNotificationPanel = false;
      });
    }
  }

  // Check if there are any unread notifications
  bool get _hasUnreadNotifications =>
      notifications.any((notification) => !notification.isRead);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
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
                            Stack(
                              children: [
                                IconButton(
                                  icon:
                                      const Icon(Icons.notifications_outlined),
                                  onPressed: () {
                                    setState(() {
                                      _showNotificationPanel =
                                          !_showNotificationPanel;
                                      if (_showNotificationPanel == false) {
                                        _markAllAsRead();
                                      }
                                    });
                                  },
                                  iconSize: 28,
                                ),
                                if (_hasUnreadNotifications)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
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
                  padding:
                      const EdgeInsets.only(left: 16, bottom: 16, right: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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

            // Notification Panel
            if (_showNotificationPanel)
              Positioned(
                top: 60,
                right: 16,
                child: _buildNotificationPanel(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPanel() {
    // Filter to only show unread notifications
    final unreadNotifications = notifications.where((n) => !n.isRead).toList();

    return Container(
      width: 280,
      constraints: const BoxConstraints(
        maxHeight: 400,
        minHeight: 100,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Notifications",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (unreadNotifications.isNotEmpty)
                  GestureDetector(
                    onTap: _markAllAsRead,
                    child: const Text(
                      "Mark all as read",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          unreadNotifications.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: const Text(
                    "No new notifications",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Flexible(
                  child: ListView.builder(
                    // Changed from ListView.separated
                    shrinkWrap: true,
                    itemCount: unreadNotifications.length,
                    itemBuilder: (context, index) {
                      // Safely get the notification at this index
                      if (index >= unreadNotifications.length) {
                        return const SizedBox
                            .shrink(); // Return empty widget for safety
                      }

                      final notification = unreadNotifications[index];
                      Color categoryColor;

                      // Set color based on category
                      switch (notification.list) {
                        case 'Equipment':
                          categoryColor = Colors.orange;
                          break;
                        case 'Seeds':
                          categoryColor = Colors.green;
                          break;
                        case 'Fertilizers':
                          categoryColor = Colors.blue;
                          break;
                        case 'Irrigation':
                          categoryColor = Colors.lightBlue;
                          break;
                        case 'Pesticides':
                          categoryColor = Colors.red;
                          break;
                        case 'Tools':
                          categoryColor = Colors.brown;
                          break;
                        default:
                          categoryColor = Colors.grey;
                      }

                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 1),
                          Container(
                            color: notification.isRead
                                ? Colors.white
                                : (notification.isRecent
                                    ? Colors.blue[100]
                                    : Colors.blue[50]),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 12.0),
                              child: Row(
                                children: [
                                  // Product Image
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[200],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        notification.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          // Fallback icon if image fails to load
                                          IconData iconData;
                                          switch (notification.list) {
                                            case 'Equipment':
                                              iconData = Icons.agriculture;
                                              break;
                                            case 'Seeds':
                                              iconData = Icons.grass;
                                              break;
                                            case 'Fertilizers':
                                              iconData = Icons.science;
                                              break;
                                            case 'Irrigation':
                                              iconData = Icons.water_drop;
                                              break;
                                            case 'Pesticides':
                                              iconData = Icons.bug_report;
                                              break;
                                            case 'Tools':
                                              iconData = Icons.handyman;
                                              break;
                                            default:
                                              iconData = Icons.shopping_bag;
                                          }
                                          return Icon(
                                            iconData,
                                            color: categoryColor,
                                            size: 30,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Product Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: categoryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                notification.list,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: categoryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "\$${notification.price.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ],
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
            } else if (title == 'Irrigation') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => IrrigationPage()),
              );
            } else if (title == 'Pesticides') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PesticidesPage()),
              );
            } else if (title == 'Tools') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ToolsPage()),
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
