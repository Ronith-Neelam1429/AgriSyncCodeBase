class EquipmentListing {
  final String name;
  final double price;
  final String condition;
  final String imageUrl;
  final String list;
  final String category;
  final String retailURL;
  final String retailer;
  final String listedBy;

  EquipmentListing({
    required this.name,
    required this.price,
    required this.condition,
    required this.imageUrl,
    required this.list,
    required this.category,
    required this.retailURL,
    required this.retailer,
    required this.listedBy,
  });
  @override
  String toString() {
    return 'EquipmentListing{'
        'name: $name, '
        'price: $price, '
        'imageUrl: $imageUrl'
        '}';
  }
}
