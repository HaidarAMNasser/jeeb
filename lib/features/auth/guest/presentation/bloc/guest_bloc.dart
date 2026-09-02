import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';

import '../../data/repositories/guest_repository.dart';

part 'guest_event.dart';
part 'guest_state.dart';

class GuestBloc extends Bloc<GuestEvent, GuestState> {
  final GuestRepository _guestRepository;
  final StorageService _storageService;

  GuestBloc(this._guestRepository, this._storageService)
      : super(const GuestInitial()) {
    on<GuestLoginSubmitted>((event, emit) async {
      emit(const GuestLoading());

      // Guest login no longer requires firebaseToken on the backend (Redis guest).
      // Attach FCM token when available (Android usually has it; iOS often does not yet).
      final firebaseToken = (await _storageService.getFcmToken())?.trim();

      final result = await _guestRepository.loginAsGuest(
        firebaseToken: firebaseToken?.isNotEmpty == true ? firebaseToken : null,
      );

      await result.fold(
        (failure) async {
          if (emit.isDone) return;
          emit(GuestError(message: failure.message));
        },
        (tokenEntity) async {
          await _storageService.setUserToken(tokenEntity.accessToken);
          await _storageService.setUserId(tokenEntity.user.id);
          await _storageService.setUserRole(tokenEntity.user.role.name);
          await _storageService.setLoggedIn(true);
          await _storageService.setVerified(true);
          await _storageService.setPendingVerifyEmail(null);
          if (emit.isDone) return;
          emit(const GuestSuccess());
        },
      );
    });
  }
}
