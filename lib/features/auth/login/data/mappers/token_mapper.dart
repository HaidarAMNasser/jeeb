import '../../domain/entities/token_entity.dart';
import '../models/token_model.dart';

extension TokenMapper on TokenModel {
  TokenEntity toDomain() {
    return TokenEntity(
      accessToken: accessToken,
      user: user.toDomain(),
    );
  }
}

