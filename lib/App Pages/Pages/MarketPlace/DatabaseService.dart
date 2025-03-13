import 'dart:async';
import 'package:agrisync/App%20Pages/Pages/MarketPlace/ListingModel.dart';
import 'package:agrisync/App%20Pages/Pages/MarketPlace/NotificationModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  // Stream controller to broadcast notifications
  static StreamController<ItemNotification>? _notificationStreamController;

  static StreamController<ItemNotification> get _controller {
    if (_notificationStreamController == null ||
        _notificationStreamController!.isClosed) {
      debugPrint("Creating new notification stream controller");
      _notificationStreamController =
          StreamController<ItemNotification>.broadcast();
    }
    return _notificationStreamController!;
  }

  static Stream<ItemNotification> get notificationStream => _controller.stream;

  static Set<String> _readNotificationIds = {};
  static bool _readStateLoaded = false;

  // Update to add notification
  static void _addNotification(ItemNotification notification) {
  print("Adding notification to stream: ${notification.name} (ID: ${notification.id})");
  // Check if notification has been read before
  notification.isRead = isNotificationRead(notification.id);
  
  try {
    _controller.add(notification);
    print("Successfully added notification to stream. IsRead: ${notification.isRead}");
  } catch (e) {
    print("Error adding notification to stream: $e");
  }
}

  static Future<void> loadReadNotificationIds() async {
  if (_readStateLoaded) return;
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('read_notifications') ?? [];
    _readNotificationIds = readIds.toSet();
    _readStateLoaded = true;
    debugPrint('Loaded ${_readNotificationIds.length} read notification IDs');
  } catch (e) {
    debugPrint('Error loading read notification IDs: $e');
    _readNotificationIds = {};
    _readStateLoaded = true;
  }
}

static Future<void> saveReadNotificationIds() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_notifications', _readNotificationIds.toList());
    debugPrint('Saved ${_readNotificationIds.length} read notification IDs');
  } catch (e) {
    debugPrint('Error saving read notification IDs: $e');
  }
}

static bool isNotificationRead(String notificationId) {
  return _readNotificationIds.contains(notificationId);
}

static Future<void> markNotificationAsRead(String notificationId) async {
  _readNotificationIds.add(notificationId);
  await saveReadNotificationIds();
}

static Future<void> markNotificationsAsRead(List<String> notificationIds) async {
  _readNotificationIds.addAll(notificationIds);
  await saveReadNotificationIds();
}

static Future<void> loadExistingData() async {
  debugPrint('Loading all existing data');
  await loadReadNotificationIds();
  _listenForNewEquipment();
  _listenForNewSeeds();
  _listenForNewFertilizers();
  _listenForNewIrrigation();
  _listenForNewPesticides();
  _listenForNewTools();
}

  // Initialize database listeners
  static void initializeListeners() {
    _listenForNewEquipment();
    _listenForNewSeeds();
    _listenForNewFertilizers();
    _listenForNewIrrigation();
    _listenForNewPesticides();
    _listenForNewTools();
  }

  static void refreshListeners() {
    _listenersInitialized = false;
    initializeAllListeners();
  }

// Modify _listenForNewEquipment() to handle existing documents
  static void _listenForNewEquipment() {
    debugPrint('Setting up equipment listener');

    // Get all existing equipment first
    FirebaseFirestore.instance
        .collection('marketPlace')
        .where('list', isEqualTo: 'Equipment') // Match your field name
        .snapshots()
        .listen((snapshot) {
      debugPrint('Found ${snapshot.docs.length} existing equipment documents');

      for (var doc in snapshot.docs) {
        try {
          final equipmentData = doc.data();
          debugPrint('Processing equipment: ${equipmentData['name']}');

          final equipment = EquipmentListing(
            name: equipmentData['name'] ?? '',
            price: double.tryParse(equipmentData['price'].toString()) ?? 0.0,
            condition: equipmentData['condition'] ?? 'New',
            imageUrl: equipmentData['imageURL'] ?? '',
            list: equipmentData['list'] ?? 'Equipment',
            category: equipmentData['category'] ?? '',
            retailURL: equipmentData['retailURL'] ?? '',
            retailer: equipmentData['retailer'] ?? '',
          );

          // Create a notification
          final notification = ItemNotification(
            name: equipment.name,
            price: equipment.price,
            imageUrl: equipment.imageUrl,
            list: 'Equipment',
            timeAdded: equipmentData['timestamp'] != null
                ? (equipmentData['timestamp'] as Timestamp).toDate()
                : DateTime.now(),
          );

          // Add to notification stream
          _addNotification(notification);
        } catch (e) {
          debugPrint('Error processing equipment data: $e');
        }
      }
    });

    // Then listen for changes
    FirebaseFirestore.instance
        .collection('equipment')
        .snapshots()
        .listen((snapshot) {
      debugPrint(
          'Equipment change snapshot received, changes: ${snapshot.docChanges.length}');

      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          // Handle all types of changes
          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            try {
              final equipmentData = change.doc.data() as Map<String, dynamic>;
              debugPrint(
                  'Processing equipment change: ${equipmentData['name']}');

              final equipment = EquipmentListing(
                name: equipmentData['name'] ?? '',
                price:
                    double.tryParse(equipmentData['price'].toString()) ?? 0.0,
                condition: equipmentData['condition'] ?? 'New',
                imageUrl: equipmentData['imageURL'] ?? '',
                list: equipmentData['list'] ?? 'Equipment',
                category: equipmentData['category'] ?? '',
                retailURL: equipmentData['retailURL'] ?? '',
                retailer: equipmentData['retailer'] ?? '',
              );

              // Create a notification
              final notification = ItemNotification(
                name: equipment.name,
                price: equipment.price,
                imageUrl: equipment.imageUrl,
                list: 'Equipment',
                timeAdded:
                    DateTime.now(), // Always use current time for notifications
              );

              // Add to notification stream
              _addNotification(notification);
            } catch (e) {
              debugPrint('Error processing equipment data: $e');
            }
          }
        }
      }
    });
  }

  // Seeds listener
  static void _listenForNewSeeds() {
    // FIRESTORE IMPLEMENTATION
    FirebaseFirestore.instance
        .collection('marketPlace')
        .where('list', isEqualTo: 'Seeds') // Match your field name
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            try {
              final seedData = change.doc.data() as Map<String, dynamic>;

              final seed = EquipmentListing(
                name: seedData['name'] ?? '',
                price: double.tryParse(seedData['price'].toString()) ?? 0.0,
                condition: seedData['condition'] ?? 'New',
                imageUrl: seedData['imageURL'] ?? '',
                list: seedData['list'] ?? 'Seeds',
                category: seedData['category'] ?? '',
                retailURL: seedData['retailURL'] ?? '',
                retailer: seedData['retailer'] ?? '',
              );

              // Create a notification
              final notification = ItemNotification(
                name: seed.name,
                price: seed.price,
                imageUrl: seed.imageUrl,
                list: 'Seeds',
                timeAdded: seedData['timestamp'] != null
                    ? (seedData['timestamp'] as Timestamp).toDate()
                    : DateTime.now(),
              );

              // Add to notification stream
              _addNotification(notification);
            } catch (e) {
              debugPrint('Error processing seed data: $e');
            }
          }
        }
      }
    });
  }

  // Fertilizers listener
  static void _listenForNewFertilizers() {
    // FIRESTORE IMPLEMENTATION
    FirebaseFirestore.instance
        .collection('marketPlace')
        .where('list', isEqualTo: 'Fertilizer') // Match your field name
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            try {
              final fertilizerData = change.doc.data() as Map<String, dynamic>;

              final fertilizer = EquipmentListing(
                name: fertilizerData['name'] ?? '',
                price:
                    double.tryParse(fertilizerData['price'].toString()) ?? 0.0,
                condition: fertilizerData['condition'] ?? 'New',
                imageUrl: fertilizerData['imageURL'] ?? '',
                list: fertilizerData['list'] ?? 'Fertilizers',
                category: fertilizerData['category'] ?? '',
                retailURL: fertilizerData['retailURL'] ?? '',
                retailer: fertilizerData['retailer'] ?? '',
              );

              // Create a notification
              final notification = ItemNotification(
                name: fertilizer.name,
                price: fertilizer.price,
                imageUrl: fertilizer.imageUrl,
                list: 'Fertilizers',
                timeAdded: fertilizerData['timestamp'] != null
                    ? (fertilizerData['timestamp'] as Timestamp).toDate()
                    : DateTime.now(),
              );

              // Add to notification stream
              _addNotification(notification);
            } catch (e) {
              debugPrint('Error processing fertilizer data: $e');
            }
          }
        }
      }
    });
  }

  // Irrigation listener
  static void _listenForNewIrrigation() {
    // FIRESTORE IMPLEMENTATION
    FirebaseFirestore.instance
        .collection('marketPlace')
        .where('list', isEqualTo: 'Irrigation') // Match your field name
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            try {
              final irrigationData = change.doc.data() as Map<String, dynamic>;

              final irrigation = EquipmentListing(
                name: irrigationData['name'] ?? '',
                price:
                    double.tryParse(irrigationData['price'].toString()) ?? 0.0,
                condition: irrigationData['condition'] ?? 'New',
                imageUrl: irrigationData['imageURL'] ?? '',
                list: irrigationData['list'] ?? 'Irrigation',
                category: irrigationData['category'] ?? '',
                retailURL: irrigationData['retailURL'] ?? '',
                retailer: irrigationData['retailer'] ?? '',
              );

              // Create a notification
              final notification = ItemNotification(
                name: irrigation.name,
                price: irrigation.price,
                imageUrl: irrigation.imageUrl,
                list: 'Irrigation',
                timeAdded: irrigationData['timestamp'] != null
                    ? (irrigationData['timestamp'] as Timestamp).toDate()
                    : DateTime.now(),
              );

              // Add to notification stream
              _addNotification(notification);
            } catch (e) {
              debugPrint('Error processing irrigation data: $e');
            }
          }
        }
      }
    });
  }

  // Pesticides listener
  static void _listenForNewPesticides() {
    debugPrint('Setting up pesticides listener');

    // FIRESTORE IMPLEMENTATION
    FirebaseFirestore.instance
        .collection('marketPlace')
        .where('list', isEqualTo: 'Pesticide') // Match your field name
        .snapshots()
        .listen((snapshot) {
      debugPrint(
          'Pesticides snapshot received, changes: ${snapshot.docChanges.length}');

      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            try {
              final pesticideData = change.doc.data() as Map<String, dynamic>;

              final pesticide = EquipmentListing(
                name: pesticideData['name'] ?? '',
                price:
                    double.tryParse(pesticideData['price'].toString()) ?? 0.0,
                condition: pesticideData['condition'] ?? 'New',
                imageUrl: pesticideData['imageURL'] ?? '',
                list: pesticideData['list'] ?? 'Pesticides',
                category: pesticideData['category'] ?? '',
                retailURL: pesticideData['retailURL'] ?? '',
                retailer: pesticideData['retailer'] ?? '',
              );

              // Create a notification
              final notification = ItemNotification(
                name: pesticide.name,
                price: pesticide.price,
                imageUrl: pesticide.imageUrl,
                list: 'Pesticides',
                timeAdded: pesticideData['timestamp'] != null
                    ? (pesticideData['timestamp'] as Timestamp).toDate()
                    : DateTime.now(),
              );

              // Add to notification stream
              _addNotification(notification);
            } catch (e) {
              debugPrint('Error processing pesticide data: $e');
            }
          }
        }
      }
    });
  }

  // Tools listener
  static void _listenForNewTools() {
    // FIRESTORE IMPLEMENTATION
    FirebaseFirestore.instance
        .collection('marketPlace')
        .where('list', isEqualTo: 'Tools') // Match your field name
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            try {
              final toolData = change.doc.data() as Map<String, dynamic>;

              final tool = EquipmentListing(
                name: toolData['name'] ?? '',
                price: double.tryParse(toolData['price'].toString()) ?? 0.0,
                condition: toolData['condition'] ?? 'New',
                imageUrl: toolData['imageURL'] ?? '',
                list: toolData['list'] ?? 'Tools',
                category: toolData['category'] ?? '',
                retailURL: toolData['retailURL'] ?? '',
                retailer: toolData['retailer'] ?? '',
              );

              // Create a notification
              final notification = ItemNotification(
                name: tool.name,
                price: tool.price,
                imageUrl: tool.imageUrl,
                list: 'Tools',
                timeAdded: toolData['timestamp'] != null
                    ? (toolData['timestamp'] as Timestamp).toDate()
                    : DateTime.now(),
              );

              // Add to notification stream
              _addNotification(notification);
            } catch (e) {
              debugPrint('Error processing tool data: $e');
            }
          }
        }
      }
    });
  }

  // Method to initialize all listeners
  static bool _listenersInitialized = false;

  static void initializeAllListeners({bool force = false}) {
    // Initialize listeners if they haven't been initialized or if forced
    if (!_listenersInitialized || force) {
      initializeListeners();
      _listenersInitialized = true;
    }
  }

  // Method to dispose of resources
  static void dispose() {
    if (_notificationStreamController != null &&
        !_notificationStreamController!.isClosed) {
      print("Closing notification stream controller");
      _notificationStreamController!.close();
      _notificationStreamController = null;
    }
    _listenersInitialized = false;
    print("DatabaseService disposed");
  }
}
