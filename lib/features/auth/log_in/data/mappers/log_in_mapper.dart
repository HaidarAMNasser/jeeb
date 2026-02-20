import '../../domain/entities/log_in_entity.dart';
import '../models/log_in_model.dart';

extension LogInMapper on LogInModel? {
  LogInEntity toDomain() {
    return LogInEntity(
      id: this?.id ?? '',
      name: this?.name ?? '',
    );
  }
}

