import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/music_player/presentation/bloc/player_bloc.dart';
import 'translation.dart';

extension LocalizationExtension on BuildContext {
  String tr(String key, {Map<String, String>? args, bool listen = true}) {
    // Read locale from PlayerBloc.
    // Use watch so widgets rebuild whenever appLocale changes in PlayerState.
    final locale = listen
        ? watch<PlayerBloc>().state.appLocale
        : read<PlayerBloc>().state.appLocale;
    return AppTranslations.get(key, locale, args: args);
  }
}
