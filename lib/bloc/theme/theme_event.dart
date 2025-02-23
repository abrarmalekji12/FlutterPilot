part of 'theme_bloc.dart';

@immutable
abstract class ThemeEvent {}

class UpdateThemeEvent extends ThemeEvent {
  UpdateThemeEvent(this.themeType);
  final ThemeType themeType;
}
