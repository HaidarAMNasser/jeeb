import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/reviews/data/repositories/reviews_repository.dart';
import 'package:jeeb_app/features/reviews/domain/entities/review_entity.dart';

part 'reviews_event.dart';
part 'reviews_state.dart';

class ReviewsBloc extends Bloc<ReviewsEvent, ReviewsState> {
  final ReviewsRepository _repository;

  ReviewsBloc(this._repository) : super(const ReviewsInitial()) {
    on<CreateReviewEvent>(_onCreateReview);
    on<GetMyReviewEvent>(_onGetMyReview);
    on<UpdateReviewEvent>(_onUpdateReview);
    on<DeleteReviewEvent>(_onDeleteReview);
    on<SetMyReviewEvent>(_onSetMyReview);
  }

  void _onCreateReview(CreateReviewEvent event, Emitter<ReviewsState> emit) async {
    emit(const ReviewsLoading());
    final result = await _repository.createReview(
      entityType: event.entityType,
      entityId: event.entityId,
      rating: event.rating,
      comment: event.comment,
    );
    result.fold(
      (failure) => emit(ReviewsError(failure.message)),
      (review) => emit(ReviewsCreateSuccess(review)),
    );
  }

  void _onGetMyReview(GetMyReviewEvent event, Emitter<ReviewsState> emit) async {
    emit(const ReviewsLoading());
    final result = await _repository.getReview(event.reviewId);
    result.fold(
      (failure) => emit(ReviewsError(failure.message)),
      (review) => emit(ReviewsLoaded(review)),
    );
  }

  void _onUpdateReview(UpdateReviewEvent event, Emitter<ReviewsState> emit) async {
    emit(const ReviewsLoading());
    final result = await _repository.updateReview(
      event.reviewId,
      rating: event.rating,
      comment: event.comment,
    );
    result.fold(
      (failure) => emit(ReviewsError(failure.message)),
      (review) => emit(ReviewsUpdateSuccess(review)),
    );
  }

  void _onDeleteReview(DeleteReviewEvent event, Emitter<ReviewsState> emit) async {
    emit(const ReviewsLoading());
    final result = await _repository.deleteReview(event.reviewId);
    result.fold(
      (failure) => emit(ReviewsError(failure.message)),
      (_) => emit(const ReviewsDeleteSuccess()),
    );
  }

  void _onSetMyReview(SetMyReviewEvent event, Emitter<ReviewsState> emit) {
    if (event.review == null) {
      emit(const ReviewsInitial());
    } else {
      emit(ReviewsLoaded(event.review!));
    }
  }
}
