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

  static String _cleanUrl(dynamic value) {
    if (value == null) return '';
    return value
        .toString()
        .trim()
        .replaceAll('`', '')
        .replaceAll(RegExp(r'\s+'), '');
  }

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] as int? ?? 0,
      url: _cleanUrl(json['url']),
      mobileUrl: json['mobileUrl'] == null ? null : _cleanUrl(json['mobileUrl']),
      thumbnailUrl: json['thumbnailUrl'] == null
          ? null
          : _cleanUrl(json['thumbnailUrl']),
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







