import '../../domain/entities/area_entity.dart';
import '../models/area_model.dart';

extension AreaMapper on AreaModel {
  AreaEntity toDomain() {
    return AreaEntity(
      id: id,
      name: name,
      description: description,
      price: price,
    );
  }
}

extension AreaListMapper on List<AreaModel> {
  List<AreaEntity> toDomain() {
    return map((model) => model.toDomain()).toList();
  }
}
