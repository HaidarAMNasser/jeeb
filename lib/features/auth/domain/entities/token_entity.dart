import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class TokenEntity extends Equatable {
  final String accessToken;
  final UserEntity user;

  const TokenEntity({
    required this.accessToken,
    required this.user,
  });

  @override
  List<Object> get props => [accessToken, user];
}
