class MenuItemModel {
  final String id;
  final String name;
  final double price;
  final String category;
  final String imageUrl;
  final String description;
  final String externalId;
  final String source;
  final String dailyDate;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.description,
    this.externalId = '',
    this.source = 'local',
    this.dailyDate = '',
  });

  factory MenuItemModel.fromMap(String id, Map<String, dynamic> map) {
    return MenuItemModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      externalId: map['externalId'] ?? '',
      source: map['source'] ?? 'local',
      dailyDate: map['dailyDate'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'externalId': externalId,
      'source': source,
      'dailyDate': dailyDate,
    };
  }
}
