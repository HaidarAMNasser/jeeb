part of 'merchant_details_bloc.dart';

abstract class MerchantDetailsState extends Equatable {
  const MerchantDetailsState();

  @override
  List<Object?> get props => [];
}

class MerchantDetailsInitial extends MerchantDetailsState {
  const MerchantDetailsInitial();
}

class MerchantDetailsLoading extends MerchantDetailsState {
  const MerchantDetailsLoading();
}

class MerchantDetailsLoaded extends MerchantDetailsState {
  final MerchantEntity merchant;

  const MerchantDetailsLoaded({required this.merchant});

  @override
  List<Object?> get props => [merchant];
}

class MerchantDetailsError extends MerchantDetailsState {
  final String message;

  const MerchantDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}

