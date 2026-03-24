import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/infrastructure/services/storage_service.dart';
import '../../data/repositories/update_token_repository.dart';

part 'update_token_event.dart';
part 'update_token_state.dart';

class UpdateTokenBloc extends Bloc<UpdateTokenEvent, UpdateTokenState> {
  final UpdateTokenRepository _repository;
  final StorageService _storageService;

  UpdateTokenBloc(this._repository, this._storageService)
    : super(const UpdateTokenState()) {
    on<UpdateTokenInitializeRequested>(_onInitialize);
    on<UpdateTokenLoginSucceeded>(_onLoginSucceeded);
    on<UpdateTokenReceived>(_onTokenReceived);
  }

  Future<void> _onInitialize(
    UpdateTokenInitializeRequested event,
    Emitter<UpdateTokenState> emit,
  ) async {
    final cached = await _storageService.getFcmToken();
    emit(state.copyWith(cachedToken: cached, errorMessage: null));
    if (cached != null && cached.isNotEmpty) {
      await _syncTokenIfNeeded(cached, emit: emit);
    }
  }

  Future<void> _onLoginSucceeded(
    UpdateTokenLoginSucceeded event,
    Emitter<UpdateTokenState> emit,
  ) async {
    final token = await _storageService.getFcmToken();
    if (token == null || token.isEmpty) return;
    await _syncTokenIfNeeded(token, emit: emit);
  }

  Future<void> _onTokenReceived(
    UpdateTokenReceived event,
    Emitter<UpdateTokenState> emit,
  ) async {
    final previous = await _storageService.getFcmToken();
    if (previous != event.token) {
      await _storageService.setFcmToken(event.token);
    }
    emit(state.copyWith(cachedToken: event.token, errorMessage: null));
    await _syncTokenIfNeeded(event.token, emit: emit);
  }

  Future<void> _syncTokenIfNeeded(
    String token, {
    required Emitter<UpdateTokenState> emit,
  }) async {
    if (token.isEmpty) return;

    final isLoggedIn = await _storageService.isLoggedIn();
    if (!isLoggedIn) return;

    final userId = await _storageService.getUserId();
    if (userId == null) return;

    final lastSyncedToken = await _storageService.getLastSyncedFcmToken();
    final lastSyncedUserId = await _storageService.getLastSyncedFcmUserId();

    final alreadySynced =
        token == lastSyncedToken && userId == lastSyncedUserId;
    if (alreadySynced) return;

    emit(state.copyWith(isSyncing: true, errorMessage: null));
    final result = await _repository.updateDeviceToken(
      token: token,
      platform: _platformName,
    );

    await result.fold(
      (failure) async {
        emit(state.copyWith(isSyncing: false, errorMessage: failure.message));
      },
      (_) async {
        await _storageService.setLastSyncedFcmToken(token);
        await _storageService.setLastSyncedFcmUserId(userId);
        emit(state.copyWith(isSyncing: false, errorMessage: null));
      },
    );
  }

  String get _platformName {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }
}
