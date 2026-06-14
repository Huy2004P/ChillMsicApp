import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart' as di;
import 'core/theme/colors.dart';
import 'features/music_player/presentation/bloc/catalog_bloc.dart';
import 'features/music_player/presentation/bloc/player_bloc.dart';
import 'features/music_player/presentation/pages/splash_page.dart';

import 'package:google_fonts/google_fonts.dart';
import 'core/service/persistence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local persistence storage
  await PersistenceService.init();

  // Initialize dependency injection
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CatalogBloc>(create: (_) => di.sl<CatalogBloc>()),
        BlocProvider<PlayerBloc>(create: (_) => di.sl<PlayerBloc>()),
      ],
      child: BlocBuilder<PlayerBloc, PlayerState>(
        buildWhen: (previous, current) =>
            previous.isDarkMode != current.isDarkMode ||
            previous.appLocale != current.appLocale,
        builder: (context, state) {
          // Synchronize static colors state
          AppColors.isDarkMode = state.isDarkMode;

          return MaterialApp(
            title: 'ChillMsic',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                surface: AppColors.canvas,
                brightness: state.isDarkMode
                    ? Brightness.dark
                    : Brightness.light,
              ),
              scaffoldBackgroundColor: AppColors.canvas,
            ),
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
