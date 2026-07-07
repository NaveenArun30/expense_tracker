import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends HydratedBloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(false)) {
    on<ToggleTheme>((event, emit) {
      emit(ThemeState(!state.isDark));
    });
  }

  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    try {
      final isDark = json['isDark'] as bool;
      return ThemeState(isDark);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    return {'isDark': state.isDark};
  }
}
