import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/infrastructure/services/storage_service.dart';

part 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  final StorageService _storage;

  LanguageCubit(this._storage)
      : super(LanguageCurrent(__currentCode(_storage.getAppLanguage())));

  static String? __currentCode(String raw) {
    final s = raw.trim();
    return s.isEmpty ? null : s;
  }

  /// Returns the current language code for the dialog (null if not set).
  String? get currentLanguageCode =>
      state is LanguageCurrent ? (state as LanguageCurrent).currentCode : null;

  /// Saves the selected language and emits [LanguageChangeSuccess] then resets to [LanguageCurrent].
  Future<void> setLanguage(String code) async {
    await _storage.setAppLanguage(code);
    emit(LanguageChangeSuccess(code));
    emit(LanguageCurrent(code));
  }
}
