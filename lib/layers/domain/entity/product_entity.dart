class ProductEntity {
  String id;
  final String name;
  final String category;
  final DateTime? date;
  final String imageUrl;
  final double price;
  final bool isAvailable;

  ProductEntity({
    this.id = '',
    required this.name,
    required this.date,
    required this.category,
    required this.imageUrl,
    required this.price,
    required this.isAvailable,
  });

  factory ProductEntity.fromJson(Map<String, dynamic> json) {
    return ProductEntity(
      id: json['id'] as String,
      name: json['name'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      category: json['category'],
      imageUrl: json['imageUrl'],
      price: json['price'],
      isAvailable: json['isAvailable'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date?.toIso8601String(),
    'category': category,
    'imageUrl': imageUrl,
    'price': price,
    'isAvailable': isAvailable,
  };
}
