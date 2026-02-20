import 'package:equatable/equatable.dart';

class LogInEntity extends Equatable {
  final String id;
  final String name;

  const LogInEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
