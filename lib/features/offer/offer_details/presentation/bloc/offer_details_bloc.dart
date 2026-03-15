import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/offer/offer_details/data/repositories/offer_details_repository.dart';

part 'offer_details_event.dart';
part 'offer_details_state.dart';

class OfferDetailsBloc extends Bloc<OfferDetailsEvent, OfferDetailsState> {
  final OfferDetailsRepository _repository;

  OfferDetailsBloc(this._repository) : super(const OfferDetailsInitial()) {
    on<OfferDetailsEvent>((event, emit) async {
      if (event is GetOfferDetailsEvent) {
        emit(const OfferDetailsLoading());
        final result = await _repository.getOfferDetails(event.id);
        result.fold(
          (failure) => emit(OfferDetailsError(
            message: failure.message,
          )),
          (offer) => emit(OfferDetailsLoaded(offer: offer)),
        );
      }
    });
  }
}
