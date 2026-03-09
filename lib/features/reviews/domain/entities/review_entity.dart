import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final int rating;
  final String comment;
  final String entityType;
  final int entityId;
  final int reviewerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reviewerFirstName;
  final String? reviewerLastName;

  const ReviewEntity({
    required this.id,
    required this.rating,
    required this.comment,
    required this.entityType,
    required this.entityId,
    required this.reviewerId,
    required this.createdAt,
    required this.updatedAt,
    this.reviewerFirstName,
    this.reviewerLastName,
  });

  String get reviewerDisplayName {
    if (reviewerFirstName != null && reviewerLastName != null) {
      return '$reviewerFirstName $reviewerLastName'.trim();
    }
    if (reviewerFirstName != null) return reviewerFirstName!;
    if (reviewerLastName != null) return reviewerLastName!;
    return 'User';
  }

  @override
  List<Object?> get props =>
      [id, rating, comment, entityType, entityId, reviewerId, createdAt, updatedAt];
}
