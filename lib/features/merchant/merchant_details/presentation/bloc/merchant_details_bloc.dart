import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/merchant/merchant_details/data/repositories/merchant_details_repository.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';

part 'merchant_details_event.dart';
part 'merchant_details_state.dart';

class MerchantDetailsBloc
    extends Bloc<MerchantDetailsEvent, MerchantDetailsState> {
  final MerchantDetailsRepository _repository;

  MerchantDetailsBloc(this._repository) : super(const MerchantDetailsInitial()) {
    on<MerchantDetailsEvent>((event, emit) async {
      if (event is GetMerchantDetailsEvent) {
        emit(const MerchantDetailsLoading());
        final result = await _repository.getMerchantDetails(event.id);
        result.fold(
          (l) => emit(MerchantDetailsError(
              message: l is Exception ? l.toString() : (l as dynamic).message?.toString() ?? 'Unknown error')),
          (merchant) => emit(MerchantDetailsLoaded(merchant: merchant )),
        );
      }
    });
  }
}

