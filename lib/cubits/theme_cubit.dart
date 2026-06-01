import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../core/constants.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final Language language;

  const ThemeState({
    required this.themeMode,
    required this.language,
  });

  @override
  List<Object> get props => [themeMode, language];

  ThemeState copyWith({
    ThemeMode? themeMode,
    Language? language,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit()
      : super(ThemeState(
          // Default: Dark Mode if morning (4 AM to 12 PM), Light Mode otherwise
          themeMode: AppConstants.getCurrentSession() == Session.morning
              ? ThemeMode.dark
              : ThemeMode.light,
          language: Language.hindi, // Default to Hindi as per user documentation vision
        ));

  void toggleTheme() {
    final nextMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(state.copyWith(themeMode: nextMode));
  }

  void setLanguage(Language lang) {
    emit(state.copyWith(language: lang));
  }
}
