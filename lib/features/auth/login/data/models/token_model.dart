import '../../domain/entities/token_entity.dart';
import 'user_model.dart';

class TokenModel {
  final String accessToken;
  final UserModel user;

  TokenModel({
    required this.accessToken,
    required this.user,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access_token'] as String? ?? '',
      user: UserModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'user': user.toJson(),
    };
  }

  TokenEntity toDomain() {
    return TokenEntity(
      accessToken: accessToken,
      user: user.toDomain(),
    );
  }
}

