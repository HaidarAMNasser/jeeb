import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/infrastructure/services/storage_service.dart';
import '../../data/repositories/delete_account_repository.dart';

part 'delete_account_event.dart';
part 'delete_account_state.dart';

class DeleteAccountBloc extends Bloc<DeleteAccountEvent, DeleteAccountState> {
  final DeleteAccountRepository _deleteAccountRepository;
  final StorageService _storageService;

  DeleteAccountBloc(
    this._deleteAccountRepository,
    this._storageService,
  ) : super(const DeleteAccountInitial()) {
    on<DeleteAccountEvent>((event, emit) async {
      if (event is DeleteAccountSubmitted) {
        emit(const DeleteAccountLoading());
        final result = await _deleteAccountRepository.deleteAccount();

        await result.fold(
          (failure) async => emit(DeleteAccountError(message: failure.message)),
          (_) async {
            await _storageService.clearStorage(clearAuthParams: true);
            if (!emit.isDone) emit(const DeleteAccountSuccess());
          },
        );
      }
    });
  }
}
