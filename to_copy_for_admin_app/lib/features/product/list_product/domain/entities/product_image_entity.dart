import 'package:equatable/equatable.dart';

class ProductImageEntity extends Equatable {
  final int id;
  final String url;
  final String? mobileUrl;
  final String? thumbnailUrl;
  final bool isMain;
  final int displayOrder;

  const ProductImageEntity({
    required this.id,
    required this.url,
    this.mobileUrl,
    this.thumbnailUrl,
    required this.isMain,
    required this.displayOrder,
  });

  @override
  List<Object?> get props => [
        id,
        url,
        mobileUrl,
        thumbnailUrl,
        isMain,
        displayOrder,
      ];
}







