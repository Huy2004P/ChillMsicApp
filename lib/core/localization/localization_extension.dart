import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/music_player/presentation/bloc/player_bloc.dart';
import 'translation.dart';

extension LocalizationExtension on BuildContext {
  String tr(String key, {Map<String, String>? args, bool listen = false}) {
    // Read locale from PlayerBloc.
    final locale = read<PlayerBloc>().state.appLocale;
    return AppTranslations.get(key, locale, args: args);
  }
}
