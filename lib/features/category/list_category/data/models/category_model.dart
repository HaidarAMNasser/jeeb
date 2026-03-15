class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    final images = json['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map<String, dynamic>) {
        imageUrl = (first['thumbnailUrl'] ?? first['mobileUrl'] ?? first['url'])?.toString();
      }
    }
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

