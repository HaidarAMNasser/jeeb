class ProductImageModel {
  final int id;
  final String url;
  final String? mobileUrl;
  final String? thumbnailUrl;
  final bool isMain;
  final int displayOrder;

  ProductImageModel({
    required this.id,
    required this.url,
    this.mobileUrl,
    this.thumbnailUrl,
    required this.isMain,
    required this.displayOrder,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] as int? ?? 0,
      url: json['url'] as String? ?? '',
      mobileUrl: json['mobileUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isMain: json['isMain'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'mobileUrl': mobileUrl,
      'thumbnailUrl': thumbnailUrl,
      'isMain': isMain,
      'displayOrder': displayOrder,
    };
  }
}







