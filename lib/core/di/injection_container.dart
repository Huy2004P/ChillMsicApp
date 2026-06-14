import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../service/audio_player_service.dart';
import '../service/real_audio_player_service.dart';
import '../../features/music_player/data/datasources/music_remote_data_source.dart';
import '../../features/music_player/data/repositories/music_repository_impl.dart';
import '../../features/music_player/domain/repositories/music_repository.dart';
import '../../features/music_player/domain/usecases/get_songs.dart';
import '../../features/music_player/domain/usecases/search_songs.dart';
import '../../features/music_player/domain/usecases/toggle_favorite.dart';
import '../../features/music_player/presentation/bloc/catalog_bloc.dart';
import '../../features/music_player/presentation/bloc/player_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Blocs
  sl.registerFactory(() => CatalogBloc(
        getSongsUseCase: sl(),
        searchSongsUseCase: sl(),
      ));

  sl.registerLazySingleton(() => PlayerBloc(
        audioPlayerService: sl(),
        toggleFavoriteUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetSongs(sl()));
  sl.registerLazySingleton(() => SearchSongs(sl()));
  sl.registerLazySingleton(() => ToggleFavorite(sl()));

  // Repository
  sl.registerLazySingleton<MusicRepository>(
    () => MusicRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<MusicRemoteDataSource>(
    () => HttpMusicRemoteDataSourceImpl(client: sl()),
  );

  // External
  sl.registerLazySingleton(() => http.Client());

  // Services
  sl.registerLazySingleton<AudioPlayerService>(
    () => RealAudioPlayerService(),
  );
}
