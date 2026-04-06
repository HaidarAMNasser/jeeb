import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/infrastructure/services/storage_service.dart';
import '../../../login/domain/entities/user_entity.dart';
import '../../../login/data/models/token_model.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/repositories/verify_repository.dart';

part 'verify_event.dart';
part 'verify_state.dart';

/// Role on [auth/verify] `data.user` (backend may use several spellings).
bool _isDeliveryFromVerifyPayload(Map<String, dynamic>? data) {
  if (data == null) return false;
  final u = data['user'];
  if (u is! Map) return false;
  final raw = u['role']?.toString().trim().toUpperCase() ?? '';
  if (raw.isEmpty) return false;
  return raw == 'DELIVERY' ||
      raw == 'DELIVERY_MAN' ||
      raw == 'DRIVER' ||
      raw == 'COURIER';
}

Future<void> _emitDeliveryPending(
  Emitter<VerifyState> emit,
  StorageService storage,
) async {
  await storage.setLoggedIn(false);
  await storage.setVerified(false);
  await storage.setPendingVerifyEmail(null);
  if (!emit.isDone) emit(const VerifyDeliveryPending());
}

class VerifyBloc extends Bloc<VerifyEvent, VerifyState> {
  final VerifyRepository _verifyRepository;
  final StorageService _storageService;
  final ProfileRepository _profileRepository;

  VerifyBloc(
    this._verifyRepository,
    this._storageService,
    this._profileRepository,
  ) : super(const VerifyInitial()) {
    on<VerifyEvent>((event, emit) async {
      if (event is VerifySubmitted) {
        emit(const VerifyLoading());
        final result = await _verifyRepository.verify(
          email: event.email,
          otp: event.otp,
        );

        await result.fold(
          (failure) async => emit(VerifyError(message: failure.message)),
          (data) async {
            String? tokenToUse;
            final responseToken =
                data?['access_token'] ?? data?['accessToken'] ?? data?['token'];
            final responseUser = data?['user'];

            if (responseToken != null &&
                responseToken.toString().isNotEmpty &&
                responseUser is Map<String, dynamic>) {
              try {
                final normalized = Map<String, dynamic>.from(data!);
                normalized['access_token'] ??=
                    normalized['accessToken'] ?? normalized['token'];
                final tokenModel = TokenModel.fromJson(normalized);
                await _storageService.setUserToken(tokenModel.accessToken);
                await _storageService.setUserId(tokenModel.user.id);
                await _storageService.setUserRole(tokenModel.user.role);
                tokenToUse = tokenModel.accessToken;
              } catch (_) {
                tokenToUse = null;
              }
            }
            if (tokenToUse == null || tokenToUse.isEmpty) {
              tokenToUse = await _storageService.getUserToken();
            }
            if (tokenToUse.isEmpty) {
              if (event.expectDeliveryWaiting) {
                await _emitDeliveryPending(emit, _storageService);
              } else if (!emit.isDone) {
                emit(const VerifySuccess(goToMain: false));
              }
              return;
            }

            // Driver self-registration: show waiting screen after OTP; do not depend on profile API.
            if (event.expectDeliveryWaiting) {
              await _emitDeliveryPending(emit, _storageService);
              return;
            }

            final deliveryFromVerify = _isDeliveryFromVerifyPayload(data);

            // Prefer GET profile when possible; if it fails, still honor delivery from verify payload.
            final profileResult = await _profileRepository.getProfile();
            await profileResult.fold(
              (failure) async {
                if (deliveryFromVerify) {
                  await _emitDeliveryPending(emit, _storageService);
                } else if (!emit.isDone) {
                  emit(const VerifySuccess(goToMain: false));
                }
              },
              (user) async {
                final isDelivery = user.role == UserRole.delivery ||
                    deliveryFromVerify;
                if (isDelivery) {
                  await _emitDeliveryPending(emit, _storageService);
                  return;
                }
                final verified = user.isVerified || (user.verifiedAt != null);
                await _storageService.setLoggedIn(true);
                await _storageService.setVerified(verified);
                await _storageService.setPendingVerifyEmail(null);
                if (!emit.isDone) {
                  emit(const VerifySuccess(goToMain: true));
                }
              },
            );
          },
        );
      } else if (event is ResendOtpSubmitted) {
        emit(const VerifyLoading());
        final result = await _verifyRepository.resendOtp(email: event.email);

        result.fold(
          (failure) => emit(VerifyError(message: failure.message)),
          (_) => emit(const VerifyOtpResent()),
        );
      }
    });
  }
}
