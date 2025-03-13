class ItemNotification {
  final String id; // Add a unique ID for each notification
  final String name;
  final double price;
  final String imageUrl;
  final String list;
  final DateTime timeAdded;
  bool isRead;
  bool isRecent;

  ItemNotification({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.list,
    required this.timeAdded,
    String? id, // Make ID optional for backward compatibility
    this.isRead = false,
    this.isRecent = true,
  }) : id = id ?? '${name}_${timeAdded.millisecondsSinceEpoch}'; // Generate ID if not provided
  
  // Add method to convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'list': list,
      'timeAdded': timeAdded.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }
  
  // Add factory method to create from Map for storage
  factory ItemNotification.fromMap(Map<String, dynamic> map) {
    return ItemNotification(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      imageUrl: map['imageUrl'],
      list: map['list'],
      timeAdded: DateTime.fromMillisecondsSinceEpoch(map['timeAdded']),
      isRead: map['isRead'] ?? false,
    );
  }
}