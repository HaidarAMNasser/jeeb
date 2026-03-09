import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/confirmation_dialog.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/merchant/reviews/domain/entities/review_entity.dart';
import 'package:jeeb_app/features/merchant/reviews/presentation/bloc/reviews_bloc.dart';

/// Review section for product details: create form or display my review with edit/delete.
class ReviewFormSection extends StatefulWidget {
  final String productId;
  final ReviewEntity? initialReview;

  const ReviewFormSection({
    super.key,
    required this.productId,
    this.initialReview,
  });

  @override
  State<ReviewFormSection> createState() => _ReviewFormSectionState();
}

class _ReviewFormSectionState extends State<ReviewFormSection> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialReview != null) {
      _commentController.text = widget.initialReview!.comment;
      _selectedRating = widget.initialReview!.rating;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  int? _productIdInt() {
    final id = int.tryParse(widget.productId);
    if (id != null) return id;
    final stripped = widget.productId.replaceFirst(RegExp(r'^product_'), '');
    return int.tryParse(stripped);
  }

  void _submitReview() {
    final entityId = _productIdInt();
    if (entityId == null) return;
    if (_selectedRating < 1 || _selectedRating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslation.pleaseSelectRating)),
      );
      return;
    }
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslation.pleaseEnterComment)),
      );
      return;
    }
    context.read<ReviewsBloc>().add(CreateReviewEvent(
          entityType: 'PRODUCT',
          entityId: entityId,
          rating: _selectedRating,
          comment: comment,
        ));
  }

  void _deleteReview(String reviewId) {
    ConfirmationDialog.show(
      context: context,
      title: AppTranslation.areYouSureDeleteReview,
      onConfirm: () {
        Navigator.of(context).pop();
        context.read<ReviewsBloc>().add(DeleteReviewEvent(reviewId));
      },
      confirmText: AppTranslation.delete,
      cancelText: AppTranslation.cancel,
      confirmColor: ColorManager.error,
    );
  }

  void _showEditDialog(ReviewEntity review) {
    final editCommentController = TextEditingController(text: review.comment);
    int editRating = review.rating;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: ColorManager.surface,
            title: CustomText(
              text: AppTranslation.editReview,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.defaultWhite,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: AppTranslation.rating,
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.defaultWhite,
                    ),
                  ),
                  SizedBox(height: AppHeight.s8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return IconButton(
                        onPressed: () => setDialogState(() => editRating = star),
                        icon: Icon(
                          editRating >= star ? Icons.star : Icons.star_border,
                          color: ColorManager.primary,
                          size: AppSize.s28,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: AppHeight.s16),
                  CustomTextField(
                    hintText: AppTranslation.commentHint,
                    controller: editCommentController,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: CustomText(
                  text: AppTranslation.cancel,
                  textStyle: getRegularStyle(color: ColorManager.defaultWhite),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _selectedRating = editRating;
                  _commentController.text = editCommentController.text;
                  context.read<ReviewsBloc>().add(UpdateReviewEvent(
                        reviewId: review.id,
                        rating: editRating,
                        comment: editCommentController.text.trim(),
                      ));
                },
                child: CustomText(
                  text: AppTranslation.save,
                  textStyle: getSemiBoldStyle(color: ColorManager.primary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReviewsBloc, ReviewsState>(
      listener: (context, state) {
        if (state is ReviewsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is ReviewsCreateSuccess || state is ReviewsUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state is ReviewsCreateSuccess
                    ? AppTranslation.reviewSubmitted
                    : AppTranslation.reviewUpdated,
              ),
            ),
          );
        }
        if (state is ReviewsDeleteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTranslation.reviewDeleted)),
          );
          context.read<ReviewsBloc>().add(const SetMyReviewEvent(null));
        }
      },
      builder: (context, state) {
        ReviewEntity? displayReview;
        if (state is ReviewsCreateSuccess) displayReview = state.review;
        if (state is ReviewsLoaded) displayReview = state.review;
        if (state is ReviewsUpdateSuccess) displayReview = state.review;
        if (displayReview == null && widget.initialReview != null) {
          displayReview = widget.initialReview;
        }

        if (displayReview != null) {
          return _buildReviewCard(displayReview, state is ReviewsLoading);
        }

        return _buildCreateForm(state is ReviewsLoading);
      },
    );
  }

  Widget _buildReviewCard(ReviewEntity review, bool isLoading) {
    return Container(
      padding: EdgeInsets.all(AppPadding.p16),
      margin: EdgeInsets.only(top: AppMargin.m16),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: AppTranslation.yourReview,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s18,
                  color: ColorManager.defaultWhite,
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CustomCircleIndicator(),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showEditDialog(review),
                      icon: Icon(
                        Icons.edit,
                        size: AppSize.s20,
                        color: ColorManager.primary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: AppWidth.s8),
                    IconButton(
                      onPressed: () => _deleteReview(review.id),
                      icon: Icon(
                        Icons.delete_outline,
                        size: AppSize.s20,
                        color: ColorManager.error,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: AppHeight.s8),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating ? Icons.star : Icons.star_border,
                color: ColorManager.primary,
                size: AppSize.s20,
              );
            }),
          ),
          SizedBox(height: AppHeight.s8),
          CustomText(
            text: review.comment,
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s14,
              color: ColorManager.textSecondary,
            ),
            maxLines: 10,
            textOverflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm(bool isLoading) {
    return Container(
      padding: EdgeInsets.all(AppPadding.p16),
      margin: EdgeInsets.only(top: AppMargin.m16),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: AppTranslation.writeReview,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.defaultWhite,
              ),
            ),
            SizedBox(height: AppHeight.s12),
            CustomText(
              text: AppTranslation.rating,
              textStyle: getSemiBoldStyle(
                fontSize: AppFontSize.s14,
                color: ColorManager.defaultWhite,
              ),
            ),
            SizedBox(height: AppHeight.s8),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _selectedRating = star),
                  icon: Icon(
                    _selectedRating >= star ? Icons.star : Icons.star_border,
                    color: ColorManager.primary,
                    size: AppSize.s30,
                  ),
                );
              }),
            ),
            SizedBox(height: AppHeight.s16),
            CustomTextField(
              hintText: AppTranslation.commentHint,
              controller: _commentController,
            ),
            SizedBox(height: AppHeight.s16),
            CustomButton(
              text: AppTranslation.submitReview,
              onPressed: isLoading ? null : _submitReview,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
