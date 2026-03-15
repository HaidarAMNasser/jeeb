part of 'language_cubit.dart';

/// Current language code (e.g. 'en', 'ar'). Empty means not set.
sealed class LanguageState extends Equatable {
  const LanguageState();

  @override
  List<Object?> get props => [];
}

class LanguageCurrent extends LanguageState {
  final String? currentCode;

  const LanguageCurrent([this.currentCode]);

  @override
  List<Object?> get props => [currentCode];
}

class LanguageChangeSuccess extends LanguageState {
  final String newCode;

  const LanguageChangeSuccess(this.newCode);

  @override
  List<Object> get props => [newCode];
}
