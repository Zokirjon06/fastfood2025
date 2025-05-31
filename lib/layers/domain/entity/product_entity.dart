class ProductEntity {
  String id;
  final String name;
  final DateTime? date;
  final String? localImagePath; // For admin: local device image path (required for creation)
  final String? imageUrl; // Generated after upload to Firebase Storage
  final double price;

  ProductEntity({
    this.id = '',
    required this.name,
    required this.date,
    required this.localImagePath, // Required: must select image from device
    this.imageUrl, // Optional: set after upload
    required this.price,
  });

  factory ProductEntity.fromJson(Map<String, dynamic> json) {
    return ProductEntity(
      id: json['id'] as String,
      name: json['name'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      localImagePath: json['localImagePath'], // For backward compatibility
      imageUrl: json['imageUrl'], // URL after Firebase upload
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date?.toIso8601String(),
    if (localImagePath != null) 'localImagePath': localImagePath,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'price': price,
  };

  /// Helper method to get the appropriate image source for display
  /// Returns local path if available (for admin preview), otherwise returns uploaded URL
  String? get displayImageSource => localImagePath ?? imageUrl;

  /// Helper method to check if this product has a local image (admin mode)
  bool get hasLocalImage => localImagePath != null && localImagePath!.isNotEmpty;

  /// Helper method to check if this product has an uploaded image URL
  bool get hasUploadedImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Helper method to check if product has any image (local or uploaded)
  bool get hasImage => hasLocalImage || hasUploadedImage;

  /// Creates a copy of this ProductEntity with uploaded image URL
  ProductEntity copyWithUploadedUrl(String uploadedUrl) {
    return ProductEntity(
      id: id,
      name: name,
      date: date,
      localImagePath: localImagePath,
      imageUrl: uploadedUrl,
      price: price,
    );
  }
}
