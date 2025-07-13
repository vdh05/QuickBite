class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isVeg;
  final String imageUrl;
  final String categoryId;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isVeg,
    required this.imageUrl,
    required this.categoryId,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      isVeg: json['isVeg'] ?? false,
      imageUrl: json['imageUrl'] ?? '',
      categoryId: json['categoryId'] ?? '',
    );
  }
}
