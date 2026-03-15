import '../../domain/entities/category_entity.dart';
import '../models/category_model.dart';

extension CategoryMapper on CategoryModel {
  CategoryEntity toDomain() {
    return CategoryEntity(
      id: id,
      name: name,
      imageUrl: imageUrl,
    );
  }
}

extension CategoryListMapper on List<CategoryModel> {
  List<CategoryEntity> toDomain() {
    return map((model) => model.toDomain()).toList();
  }
}

