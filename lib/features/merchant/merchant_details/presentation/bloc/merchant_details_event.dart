part of 'merchant_details_bloc.dart';

abstract class MerchantDetailsEvent extends Equatable {
  const MerchantDetailsEvent();

  @override
  List<Object> get props => [];
}

class GetMerchantDetailsEvent extends MerchantDetailsEvent {
  final String id;

  const GetMerchantDetailsEvent({required this.id});

  @override
  List<Object> get props => [id];
}

