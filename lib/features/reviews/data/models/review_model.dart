import 'package:jeeb_app/features/merchant/reviews/domain/entities/review_entity.dart';

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.id,
    required super.rating,
    required super.comment,
    required super.entityType,
    required super.entityId,
    required super.reviewerId,
    required super.createdAt,
    required super.updatedAt,
    super.reviewerFirstName,
    super.reviewerLastName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] as String? ?? json['created_at'] as String?;
    final updatedAt = json['updatedAt'] as String? ?? json['updated_at'] as String?;
    final reviewer = json['reviewer'] as Map<String, dynamic>?;

    return ReviewModel(
      id: (json['id'] as num).toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      entityType: json['entityType'] as String? ?? json['entity_type'] as String? ?? 'PRODUCT',
      entityId: (json['entityId'] as num?)?.toInt() ?? (json['entity_id'] as num?)?.toInt() ?? 0,
      reviewerId: (json['reviewerId'] as num?)?.toInt() ?? (json['reviewer_id'] as num?)?.toInt() ?? 0,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt) ?? DateTime.now() : DateTime.now(),
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt) ?? DateTime.now() : DateTime.now(),
      reviewerFirstName: reviewer?['firstName'] as String? ?? reviewer?['first_name'] as String?,
      reviewerLastName: reviewer?['lastName'] as String? ?? reviewer?['last_name'] as String?,
    );
  }
}
