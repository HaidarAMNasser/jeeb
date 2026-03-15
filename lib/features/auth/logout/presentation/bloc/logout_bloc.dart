import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/infrastructure/services/storage_service.dart';
import '../../data/repositories/logout_repository.dart';

part 'logout_event.dart';
part 'logout_state.dart';

class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  final LogoutRepository _logoutRepository;
  final StorageService _storageService;

  LogoutBloc(
    this._logoutRepository,
    this._storageService,
  ) : super(const LogoutInitial()) {
    on<LogoutEvent>((event, emit) async {
      if (event is LogoutSubmitted) {
        emit(const LogoutLoading());
        final result = await _logoutRepository.logout();

        await result.fold(
          (failure) async => emit(LogoutError(message: failure.message)),
          (_) async {
            await _storageService.clearStorage(clearAuthParams: true);
            if (!emit.isDone) emit(const LogoutSuccess());
          },
        );
      }
    });
  }
}

