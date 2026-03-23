part of 'update_token_bloc.dart';

class UpdateTokenState extends Equatable {
  final String? cachedToken;
  final bool isSyncing;
  final String? errorMessage;

  const UpdateTokenState({
    this.cachedToken,
    this.isSyncing = false,
    this.errorMessage,
  });

  UpdateTokenState copyWith({
    String? cachedToken,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return UpdateTokenState(
      cachedToken: cachedToken ?? this.cachedToken,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [cachedToken, isSyncing, errorMessage];
}
