import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';

import '../../../../core/service/audio_player_service.dart';
import '../../../../core/service/mock_audio_player_service.dart';
import '../../../../core/service/persistence_service.dart';
import '../../../../core/service/audio_cache_helper.dart';
import '../../../../core/service/gemini_service.dart';
import '../../../../core/theme/colors.dart';
import '../../data/datasources/music_remote_data_source.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/usecases/toggle_favorite.dart';

// --- Events ---
abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlaySongEvent extends PlayerEvent {
  final Song song;
  final List<Song> queue;

  const PlaySongEvent({required this.song, required this.queue});

  @override
  List<Object?> get props => [song, queue];
}

class PauseSongEvent extends PlayerEvent {}

class ResumeSongEvent extends PlayerEvent {}

class StopSongEvent extends PlayerEvent {}

class SeekSongEvent extends PlayerEvent {
  final Duration position;

  const SeekSongEvent(this.position);

  @override
  List<Object?> get props => [position];
}

class SkipNextEvent extends PlayerEvent {}

class SkipPreviousEvent extends PlayerEvent {}

class ToggleFavoriteCurrentSongEvent extends PlayerEvent {}

class ToggleFavoriteSongIdEvent extends PlayerEvent {
  final String songId;
  const ToggleFavoriteSongIdEvent(this.songId);
  @override
  List<Object?> get props => [songId];
}

class ChangeAudioQualityEvent extends PlayerEvent {
  final String quality;

  const ChangeAudioQualityEvent(this.quality);

  @override
  List<Object?> get props => [quality];
}

class UpdateSpatialAudioModeEvent extends PlayerEvent {
  final String mode;
  const UpdateSpatialAudioModeEvent(this.mode);
  @override
  List<Object?> get props => [mode];
}

class UpdateHeadphoneProfileEvent extends PlayerEvent {
  final String profile;
  const UpdateHeadphoneProfileEvent(this.profile);
  @override
  List<Object?> get props => [profile];
}

class UpdateEqBandEvent extends PlayerEvent {
  final String band;
  final double value;
  const UpdateEqBandEvent({required this.band, required this.value});
  @override
  List<Object?> get props => [band, value];
}

class SelectEqPresetEvent extends PlayerEvent {
  final String preset;
  const SelectEqPresetEvent(this.preset);
  @override
  List<Object?> get props => [preset];
}

class ToggleGaplessEvent extends PlayerEvent {}

class ToggleDarkModeEvent extends PlayerEvent {}

class ToggleShuffleEvent extends PlayerEvent {}

class ToggleRepeatModeEvent extends PlayerEvent {}

class UpdateCrossfadeEvent extends PlayerEvent {
  final int seconds;
  const UpdateCrossfadeEvent(this.seconds);
  @override
  List<Object?> get props => [seconds];
}

class _BitrateTickEvent extends PlayerEvent {
  final int bitrate;
  const _BitrateTickEvent(this.bitrate);
  @override
  List<Object?> get props => [bitrate];
}

class SetSleepTimerEvent extends PlayerEvent {
  final int minutes;
  const SetSleepTimerEvent(this.minutes);
  @override
  List<Object?> get props => [minutes];
}

class _SleepTimerTickEvent extends PlayerEvent {
  final Duration? remaining;
  final double volumeMultiplier;
  const _SleepTimerTickEvent(this.remaining, {this.volumeMultiplier = 1.0});
  @override
  List<Object?> get props => [remaining, volumeMultiplier];
}

class UpdateQueueEvent extends PlayerEvent {
  final List<Song> queue;
  const UpdateQueueEvent(this.queue);
  @override
  List<Object?> get props => [queue];
}

class UpdateGeminiApiKeyEvent extends PlayerEvent {
  final String apiKey;
  const UpdateGeminiApiKeyEvent(this.apiKey);
  @override
  List<Object?> get props => [apiKey];
}

class UpdateApiServerUrlEvent extends PlayerEvent {
  final String serverUrl;
  const UpdateApiServerUrlEvent(this.serverUrl);
  @override
  List<Object?> get props => [serverUrl];
}

class CreatePlaylistEvent extends PlayerEvent {
  final String name;
  const CreatePlaylistEvent(this.name);
  @override
  List<Object?> get props => [name];
}

class DeletePlaylistEvent extends PlayerEvent {
  final String playlistId;
  const DeletePlaylistEvent(this.playlistId);
  @override
  List<Object?> get props => [playlistId];
}

class AddSongToPlaylistEvent extends PlayerEvent {
  final String playlistId;
  final Song song;
  const AddSongToPlaylistEvent({required this.playlistId, required this.song});
  @override
  List<Object?> get props => [playlistId, song];
}

class RemoveSongFromPlaylistEvent extends PlayerEvent {
  final String playlistId;
  final String songId;
  const RemoveSongFromPlaylistEvent({
    required this.playlistId,
    required this.songId,
  });
  @override
  List<Object?> get props => [playlistId, songId];
}

class AddSearchQueryEvent extends PlayerEvent {
  final String query;
  const AddSearchQueryEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class ClearSearchHistoryEvent extends PlayerEvent {}

class DownloadSongEvent extends PlayerEvent {
  final Song song;
  const DownloadSongEvent(this.song);
  @override
  List<Object?> get props => [song];
}

class DeleteDownloadedSongEvent extends PlayerEvent {
  final String songId;
  const DeleteDownloadedSongEvent(this.songId);
  @override
  List<Object?> get props => [songId];
}

class AdjustLyricDelayEvent extends PlayerEvent {
  final int ms;
  const AdjustLyricDelayEvent(this.ms);
  @override
  List<Object?> get props => [ms];
}

class ChangeLocaleEvent extends PlayerEvent {
  final String locale;
  const ChangeLocaleEvent(this.locale);
  @override
  List<Object?> get props => [locale];
}

class ChangeAccentColorEvent extends PlayerEvent {
  final int colorVal;
  const ChangeAccentColorEvent(this.colorVal);
  @override
  List<Object?> get props => [colorVal];
}

class ChangeLyricFontSizeEvent extends PlayerEvent {
  final double multiplier;
  const ChangeLyricFontSizeEvent(this.multiplier);
  @override
  List<Object?> get props => [multiplier];
}

class TranslateCurrentSongLyricsEvent extends PlayerEvent {}

class GenerateMoodPlaylistEvent extends PlayerEvent {
  final String mood;
  const GenerateMoodPlaylistEvent(this.mood);
  @override
  List<Object?> get props => [mood];
}

class ClearAudioCacheEvent extends PlayerEvent {}

class UpdateAudioCacheSizeEvent extends PlayerEvent {
  final double sizeMb;
  const UpdateAudioCacheSizeEvent(this.sizeMb);
  @override
  List<Object?> get props => [sizeMb];
}

// Internal stream update events
class _UpdatePlayerStateEvent extends PlayerEvent {
  final AudioPlayerState state;

  const _UpdatePlayerStateEvent(this.state);

  @override
  List<Object?> get props => [state];
}

class _UpdatePositionEvent extends PlayerEvent {
  final Duration position;

  const _UpdatePositionEvent(this.position);

  @override
  List<Object?> get props => [position];
}

class _UpdateDurationEvent extends PlayerEvent {
  final Duration duration;

  const _UpdateDurationEvent(this.duration);

  @override
  List<Object?> get props => [duration];
}

class _UpdateCurrentSongEvent extends PlayerEvent {
  final Song? song;

  const _UpdateCurrentSongEvent(this.song);

  @override
  List<Object?> get props => [song];
}

// --- States ---
class PlayerState extends Equatable {
  final AudioPlayerState playerState;
  final Song? currentSong;
  final Duration position;
  final Duration duration;
  final List<Song> queue;
  final String audioQuality; // "Lossless", "High", "Standard"
  final String
  spatialAudioMode; // "Tắt (Stereo gốc)", "Phòng thu tiêu chuẩn (Studio)", "Sân khấu trực tiếp (Live Stage)", "Rạp hát vòm (Cinematic Surround)"
  final String
  headphoneProfile; // "Tai nghe In-Ear (IEM / Nhẹ - 16Ω)", "Tai nghe Chụp tai (On-Ear / Vừa - 32Ω)", "Tai nghe Phòng thu (Audiophile / Cao - 250Ω)"
  final Map<String, double>
  eqBands; // e.g. {"60 Hz": 0.0, "230 Hz": 0.0, "910 Hz": 0.0, "4 kHz": 0.0, "14 kHz": 0.0}
  final bool gaplessEnabled;
  final int crossfadeSeconds;
  final String
  eqPresetName; // "Mặc định", "Acoustic", "Pop", "EDM", "Lofi Thư giãn", "Tăng Bass (Bass Boost)", "Tùy chỉnh"
  final int currentBitrate;
  final bool shuffleEnabled;
  final String repeatMode; // "off" | "all" | "one"
  final bool? _isDarkMode;
  bool get isDarkMode => _isDarkMode ?? true;
  final Duration? sleepTimerRemaining;
  final List<Song> songPlayHistory;
  final Duration totalListeningDuration;
  final String geminiApiKey;
  final String apiServerUrl;
  final List<Playlist> customPlaylists;
  final List<String> searchHistory;
  final int lyricDelayMs;
  final String appLocale;
  final int themeAccentColor;
  final double lyricFontSizeMultiplier;
  final String translatedLyrics;
  final bool isTranslating;
  final double audioCacheSize;
  final Map<String, int> weeklyListeningStats;
  final double sleepTimerVolumeMultiplier;
  final bool isGeneratingMoodPlaylist;
  final List<Song> downloadedSongs;
  final Set<String> downloadingSongIds;

  const PlayerState({
    this.playerState = AudioPlayerState.idle,
    this.currentSong,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.audioQuality = 'Âm thanh Lossless (24-bit/192kHz)',
    this.spatialAudioMode = 'Tắt (Stereo gốc)',
    this.headphoneProfile = 'Tai nghe In-Ear (IEM / Nhẹ - 16Ω)',
    this.eqBands = const {
      '60 Hz': 0.0,
      '230 Hz': 0.0,
      '910 Hz': 0.0,
      '4 kHz': 0.0,
      '14 kHz': 0.0,
    },
    this.gaplessEnabled = true,
    this.crossfadeSeconds = 0,
    this.eqPresetName = 'Mặc định',
    this.currentBitrate = 0,
    this.shuffleEnabled = false,
    this.repeatMode = 'all',
    bool? isDarkMode, // Default to Dark Mode as requested
    this.sleepTimerRemaining,
    this.songPlayHistory = const [],
    this.totalListeningDuration = Duration.zero,
    this.geminiApiKey = '',
    this.apiServerUrl = 'http://music-api.vanhuy2004h.io.vn',
    this.customPlaylists = const [],
    this.searchHistory = const [],
    this.lyricDelayMs = 0,
    this.appLocale = 'vi',
    this.themeAccentColor = 0xFF0054FF,
    this.lyricFontSizeMultiplier = 1.0,
    this.translatedLyrics = '',
    this.isTranslating = false,
    this.audioCacheSize = 0.0,
    this.weeklyListeningStats = const {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    },
    this.sleepTimerVolumeMultiplier = 1.0,
    this.isGeneratingMoodPlaylist = false,
    this.downloadedSongs = const [],
    this.downloadingSongIds = const {},
  }) : _isDarkMode = isDarkMode ?? true;

  PlayerState copyWith({
    AudioPlayerState? playerState,
    Song? currentSong,
    Duration? position,
    Duration? duration,
    List<Song>? queue,
    String? audioQuality,
    String? spatialAudioMode,
    String? headphoneProfile,
    Map<String, double>? eqBands,
    bool? gaplessEnabled,
    int? crossfadeSeconds,
    String? eqPresetName,
    int? currentBitrate,
    bool? shuffleEnabled,
    String? repeatMode,
    bool? isDarkMode,
    Duration? Function()? sleepTimerRemaining,
    List<Song>? songPlayHistory,
    Duration? totalListeningDuration,
    String? geminiApiKey,
    String? apiServerUrl,
    List<Playlist>? customPlaylists,
    List<String>? searchHistory,
    int? lyricDelayMs,
    String? appLocale,
    int? themeAccentColor,
    double? lyricFontSizeMultiplier,
    String? translatedLyrics,
    bool? isTranslating,
    double? audioCacheSize,
    Map<String, int>? weeklyListeningStats,
    double? sleepTimerVolumeMultiplier,
    bool? isGeneratingMoodPlaylist,
    List<Song>? downloadedSongs,
    Set<String>? downloadingSongIds,
  }) {
    return PlayerState(
      playerState: playerState ?? this.playerState,
      currentSong: currentSong ?? this.currentSong,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      audioQuality: audioQuality ?? this.audioQuality,
      spatialAudioMode: spatialAudioMode ?? this.spatialAudioMode,
      headphoneProfile: headphoneProfile ?? this.headphoneProfile,
      eqBands: eqBands ?? this.eqBands,
      gaplessEnabled: gaplessEnabled ?? this.gaplessEnabled,
      crossfadeSeconds: crossfadeSeconds ?? this.crossfadeSeconds,
      eqPresetName: eqPresetName ?? this.eqPresetName,
      currentBitrate: currentBitrate ?? this.currentBitrate,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      sleepTimerRemaining: sleepTimerRemaining != null
          ? sleepTimerRemaining()
          : this.sleepTimerRemaining,
      songPlayHistory: songPlayHistory ?? this.songPlayHistory,
      totalListeningDuration:
          totalListeningDuration ?? this.totalListeningDuration,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      apiServerUrl: apiServerUrl ?? this.apiServerUrl,
      customPlaylists: customPlaylists ?? this.customPlaylists,
      searchHistory: searchHistory ?? this.searchHistory,
      lyricDelayMs: lyricDelayMs ?? this.lyricDelayMs,
      appLocale: appLocale ?? this.appLocale,
      themeAccentColor: themeAccentColor ?? this.themeAccentColor,
      lyricFontSizeMultiplier:
          lyricFontSizeMultiplier ?? this.lyricFontSizeMultiplier,
      translatedLyrics: translatedLyrics ?? this.translatedLyrics,
      isTranslating: isTranslating ?? this.isTranslating,
      audioCacheSize: audioCacheSize ?? this.audioCacheSize,
      weeklyListeningStats: weeklyListeningStats ?? this.weeklyListeningStats,
      sleepTimerVolumeMultiplier:
          sleepTimerVolumeMultiplier ?? this.sleepTimerVolumeMultiplier,
      isGeneratingMoodPlaylist:
          isGeneratingMoodPlaylist ?? this.isGeneratingMoodPlaylist,
      downloadedSongs: downloadedSongs ?? this.downloadedSongs,
      downloadingSongIds: downloadingSongIds ?? this.downloadingSongIds,
    );
  }

  @override
  List<Object?> get props => [
    playerState,
    currentSong,
    position,
    duration,
    queue,
    audioQuality,
    spatialAudioMode,
    headphoneProfile,
    eqBands,
    gaplessEnabled,
    crossfadeSeconds,
    eqPresetName,
    currentBitrate,
    shuffleEnabled,
    repeatMode,
    isDarkMode,
    sleepTimerRemaining,
    songPlayHistory,
    totalListeningDuration,
    geminiApiKey,
    apiServerUrl,
    customPlaylists,
    searchHistory,
    lyricDelayMs,
    appLocale,
    themeAccentColor,
    lyricFontSizeMultiplier,
    translatedLyrics,
    isTranslating,
    audioCacheSize,
    weeklyListeningStats,
    sleepTimerVolumeMultiplier,
    isGeneratingMoodPlaylist,
    downloadedSongs,
    downloadingSongIds,
  ];
}

// --- Bloc ---
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayerService audioPlayerService;
  final ToggleFavorite toggleFavoriteUseCase;

  StreamSubscription? _stateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _currentSongSubscription;
  Timer? _bitrateTimer;
  Timer? _sleepTimer;
  bool _hasCrossfadedCurrentSong = false;

  PlayerBloc({
    required this.audioPlayerService,
    required this.toggleFavoriteUseCase,
  }) : super(
         PlayerState(
           geminiApiKey: PersistenceService.getGeminiApiKey(),
           apiServerUrl: PersistenceService.getApiServerUrl(),
           customPlaylists: PersistenceService.getPlaylists()
               .map((json) => Playlist.fromJson(json))
               .toList(),
           searchHistory: PersistenceService.getSearchHistory(),
           songPlayHistory: PersistenceService.getRecentPlayed()
               .map((json) => Song.fromJson(json))
               .toList(),
           appLocale: PersistenceService.getLocale(),
           themeAccentColor: PersistenceService.getAccentColor(),
           lyricFontSizeMultiplier:
               PersistenceService.getLyricFontSizeMultiplier(),
           weeklyListeningStats: PersistenceService.getWeeklyListeningStats(),
           downloadedSongs: PersistenceService.getDownloadedSongs()
               .map((json) => Song.fromJson(json))
               .toList(),
           crossfadeSeconds: PersistenceService.getCrossfadeSeconds(),
         ),
       ) {
    // Set static base URL in remote datasource to match loaded setting
    HttpMusicRemoteDataSourceImpl.baseUrl =
        PersistenceService.getApiServerUrl();
    AppColors.primary = Color(PersistenceService.getAccentColor());
    audioPlayerService.setCrossfadeSeconds(
      PersistenceService.getCrossfadeSeconds(),
    );

    on<PlaySongEvent>(_onPlaySong);
    on<PauseSongEvent>(_onPauseSong);
    on<ResumeSongEvent>(_onResumeSong);
    on<StopSongEvent>(_onStopSong);
    on<SeekSongEvent>(_onSeekSong);
    on<SkipNextEvent>(_onSkipNext);
    on<SkipPreviousEvent>(_onSkipPrevious);
    on<ToggleFavoriteCurrentSongEvent>(_onToggleFavoriteCurrentSong);
    on<ToggleFavoriteSongIdEvent>(_onToggleFavoriteSongId);
    on<ChangeAudioQualityEvent>(_onChangeAudioQuality);

    // Advanced audio events
    on<UpdateSpatialAudioModeEvent>(_onUpdateSpatialAudioMode);
    on<UpdateHeadphoneProfileEvent>(_onUpdateHeadphoneProfile);
    on<UpdateEqBandEvent>(_onUpdateEqBand);
    on<SelectEqPresetEvent>(_onSelectEqPreset);
    on<ToggleGaplessEvent>(_onToggleGapless);
    on<UpdateCrossfadeEvent>(_onUpdateCrossfade);
    on<ToggleShuffleEvent>(_onToggleShuffle);
    on<ToggleRepeatModeEvent>(_onToggleRepeatMode);
    on<ToggleDarkModeEvent>((event, emit) {
      final newMode = !state.isDarkMode;
      AppColors.isDarkMode = newMode;
      emit(state.copyWith(isDarkMode: newMode));
    });
    on<_BitrateTickEvent>(
      (event, emit) => emit(state.copyWith(currentBitrate: event.bitrate)),
    );
    on<SetSleepTimerEvent>(_onSetSleepTimer);
    on<_SleepTimerTickEvent>((event, emit) async {
      emit(
        state.copyWith(
          sleepTimerRemaining: () => event.remaining,
          sleepTimerVolumeMultiplier: event.volumeMultiplier,
        ),
      );
      await _applyAudioEffects(state);
    });
    on<GenerateMoodPlaylistEvent>(_onGenerateMoodPlaylist);
    on<UpdateQueueEvent>(
      (event, emit) => emit(state.copyWith(queue: event.queue)),
    );
    on<DownloadSongEvent>(_onDownloadSong);
    on<DeleteDownloadedSongEvent>(_onDeleteDownloadedSong);
    on<UpdateGeminiApiKeyEvent>((event, emit) async {
      await PersistenceService.saveGeminiApiKey(event.apiKey);
      emit(state.copyWith(geminiApiKey: event.apiKey));
    });
    on<UpdateApiServerUrlEvent>((event, emit) async {
      await PersistenceService.saveApiServerUrl(event.serverUrl);
      HttpMusicRemoteDataSourceImpl.baseUrl = event.serverUrl;
      emit(state.copyWith(apiServerUrl: event.serverUrl));
    });

    on<ChangeLocaleEvent>((event, emit) async {
      await PersistenceService.saveLocale(event.locale);
      emit(state.copyWith(appLocale: event.locale));
    });

    on<ChangeAccentColorEvent>((event, emit) async {
      await PersistenceService.saveAccentColor(event.colorVal);
      AppColors.primary = Color(event.colorVal);
      emit(state.copyWith(themeAccentColor: event.colorVal));
    });

    on<ChangeLyricFontSizeEvent>((event, emit) async {
      await PersistenceService.saveLyricFontSizeMultiplier(event.multiplier);
      emit(state.copyWith(lyricFontSizeMultiplier: event.multiplier));
    });

    on<TranslateCurrentSongLyricsEvent>(_onTranslateCurrentSongLyrics);

    on<ClearAudioCacheEvent>(_onClearAudioCache);

    on<UpdateAudioCacheSizeEvent>((event, emit) {
      emit(state.copyWith(audioCacheSize: event.sizeMb));
    });

    _updateCacheSize();

    on<CreatePlaylistEvent>((event, emit) async {
      final String newId = DateTime.now().millisecondsSinceEpoch.toString();
      final newPlaylist = Playlist(
        id: newId,
        name: event.name,
        songs: const [],
      );
      final updatedList = List<Playlist>.from(state.customPlaylists)
        ..add(newPlaylist);

      await PersistenceService.savePlaylists(
        updatedList.map((p) => p.toJson()).toList(),
      );
      emit(state.copyWith(customPlaylists: updatedList));
    });

    on<DeletePlaylistEvent>((event, emit) async {
      final updatedList = state.customPlaylists
          .where((p) => p.id != event.playlistId)
          .toList();

      await PersistenceService.savePlaylists(
        updatedList.map((p) => p.toJson()).toList(),
      );
      emit(state.copyWith(customPlaylists: updatedList));
    });

    on<AddSongToPlaylistEvent>((event, emit) async {
      final updatedList = state.customPlaylists.map((playlist) {
        if (playlist.id == event.playlistId) {
          if (playlist.songs.any((s) => s.id == event.song.id)) {
            return playlist;
          }
          final updatedSongs = List<Song>.from(playlist.songs)..add(event.song);
          return playlist.copyWith(songs: updatedSongs);
        }
        return playlist;
      }).toList();

      await PersistenceService.savePlaylists(
        updatedList.map((p) => p.toJson()).toList(),
      );
      emit(state.copyWith(customPlaylists: updatedList));
    });

    on<RemoveSongFromPlaylistEvent>((event, emit) async {
      final updatedList = state.customPlaylists.map((playlist) {
        if (playlist.id == event.playlistId) {
          final updatedSongs = playlist.songs
              .where((s) => s.id != event.songId)
              .toList();
          return playlist.copyWith(songs: updatedSongs);
        }
        return playlist;
      }).toList();

      await PersistenceService.savePlaylists(
        updatedList.map((p) => p.toJson()).toList(),
      );
      emit(state.copyWith(customPlaylists: updatedList));
    });

    on<AddSearchQueryEvent>((event, emit) async {
      final query = event.query.trim();
      if (query.isEmpty) return;

      final updatedList = List<String>.from(state.searchHistory);
      updatedList.remove(query);
      updatedList.insert(0, query);

      if (updatedList.length > 10) {
        updatedList.removeLast();
      }

      await PersistenceService.saveSearchHistory(updatedList);
      emit(state.copyWith(searchHistory: updatedList));
    });

    on<ClearSearchHistoryEvent>((event, emit) async {
      await PersistenceService.saveSearchHistory(const []);
      emit(state.copyWith(searchHistory: const []));
    });

    on<AdjustLyricDelayEvent>((event, emit) {
      emit(state.copyWith(lyricDelayMs: event.ms));
    });

    // Internal stream updates
    on<_UpdatePlayerStateEvent>(
      (event, emit) => emit(state.copyWith(playerState: event.state)),
    );
    on<_UpdatePositionEvent>((event, emit) async {
      Duration timeDelta = Duration.zero;
      if (state.playerState == AudioPlayerState.playing) {
        final diff =
            event.position.inMilliseconds - state.position.inMilliseconds;
        // Count typical tick diffs under 3 seconds to exclude seeks
        if (diff > 0 && diff < 3000) {
          timeDelta = Duration(milliseconds: diff);
        }
      }
      Map<String, int> stats = Map.from(state.weeklyListeningStats);
      if (timeDelta.inSeconds > 0) {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final String currentDayKey = weekdays[DateTime.now().weekday - 1];
        final int currentSecs = stats[currentDayKey] ?? 0;
        stats[currentDayKey] = currentSecs + timeDelta.inSeconds;
        await PersistenceService.saveWeeklyListeningStats(stats);
      }

      // Crossfade logic: trigger next song early if remaining duration <= crossfadeSeconds
      if (state.crossfadeSeconds > 0 &&
          state.playerState == AudioPlayerState.playing &&
          !_hasCrossfadedCurrentSong &&
          state.currentSong != null &&
          state.duration > Duration.zero &&
          state.duration.inSeconds > state.crossfadeSeconds) {
        final remaining = state.duration - event.position;
        if (remaining.inSeconds <= state.crossfadeSeconds) {
          _hasCrossfadedCurrentSong = true;
          debugPrint(
            '[ChillMsic Crossfade] Kích hoạt trộn nhạc sớm trước ${remaining.inSeconds} giây',
          );

          if (state.repeatMode == 'one') {
            // Repeat one: crossfade back to the same song
            add(PlaySongEvent(song: state.currentSong!, queue: state.queue));
          } else if (state.repeatMode == 'off' &&
              state.queue.isNotEmpty &&
              state.queue.indexOf(state.currentSong!) ==
                  state.queue.length - 1) {
            // Repeat off and last song in queue: do not crossfade, complete naturally.
            debugPrint(
              '[ChillMsic Crossfade] Bài hát cuối cùng trong danh sách phát và chế độ lặp tắt: Chờ hoàn thành tự nhiên.',
            );
          } else {
            // Play next song early
            add(SkipNextEvent());
          }
        }
      }

      // Reset crossfade flag on rewind/manual seek
      if (state.crossfadeSeconds > 0 &&
          state.duration > Duration.zero &&
          event.position.inSeconds <
              state.duration.inSeconds - state.crossfadeSeconds) {
        _hasCrossfadedCurrentSong = false;
      }

      emit(
        state.copyWith(
          position: event.position,
          totalListeningDuration: state.totalListeningDuration + timeDelta,
          weeklyListeningStats: stats,
        ),
      );
    });
    on<_UpdateDurationEvent>(
      (event, emit) => emit(state.copyWith(duration: event.duration)),
    );
    on<_UpdateCurrentSongEvent>((event, emit) async {
      final newSong = event.song;
      List<Song> updatedHistory = List.from(state.songPlayHistory);
      if (newSong != null) {
        if (updatedHistory.isEmpty || updatedHistory.last.id != newSong.id) {
          // Remove if it exists elsewhere to avoid duplicate entries, pushing it to the end
          updatedHistory.removeWhere((s) => s.id == newSong.id);
          updatedHistory.add(newSong);
          if (updatedHistory.length > 50) {
            updatedHistory.removeAt(0);
          }
          await PersistenceService.saveRecentPlayed(
            updatedHistory.map((s) => s.toJson()).toList(),
          );
        }
      }
      emit(
        state.copyWith(currentSong: newSong, songPlayHistory: updatedHistory),
      );
    });

    // Subscribe to AudioPlayerService streams
    _stateSubscription = audioPlayerService.stateStream.listen((playerState) {
      add(_UpdatePlayerStateEvent(playerState));
      if (playerState == AudioPlayerState.playing) {
        _startBitrateTimer();
      } else {
        _stopBitrateTimer();
      }
      if (playerState == AudioPlayerState.completed) {
        if (state.repeatMode == 'one' && state.currentSong != null) {
          audioPlayerService.play(state.currentSong!);
        } else if (state.repeatMode == 'off' &&
            state.currentSong != null &&
            state.queue.isNotEmpty &&
            state.queue.indexOf(state.currentSong!) == state.queue.length - 1) {
          audioPlayerService.stop();
        } else {
          add(SkipNextEvent()); // Auto play next song on completion
        }
      }
    });

    _positionSubscription = audioPlayerService.positionStream.listen((pos) {
      add(_UpdatePositionEvent(pos));
    });

    _durationSubscription = audioPlayerService.durationStream.listen((dur) {
      add(_UpdateDurationEvent(dur));
    });

    _currentSongSubscription = audioPlayerService.currentSongStream.listen((
      song,
    ) {
      add(_UpdateCurrentSongEvent(song));
    });
  }

  void _startBitrateTimer() {
    _bitrateTimer?.cancel();
    _bitrateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final random = DateTime.now().millisecond;
      int baseBitrate = 920;
      int variance = 60;
      if (state.audioQuality.contains('128')) {
        baseBitrate = 124;
        variance = 4;
      } else if (state.audioQuality.contains('320')) {
        baseBitrate = 315;
        variance = 5;
      }
      final offset = (random % (variance * 2)) - variance;
      add(_BitrateTickEvent(baseBitrate + offset));
    });
  }

  void _stopBitrateTimer() {
    _bitrateTimer?.cancel();
    _bitrateTimer = null;
    add(const _BitrateTickEvent(0));
  }

  Future<void> _onPlaySong(
    PlaySongEvent event,
    Emitter<PlayerState> emit,
  ) async {
    _hasCrossfadedCurrentSong = false;
    audioPlayerService.setCrossfadeSeconds(state.crossfadeSeconds);
    emit(state.copyWith(queue: event.queue));

    // Set audio quality
    await audioPlayerService.setAudioQuality(state.audioQuality);

    await audioPlayerService.play(event.song);

    // Apply dynamic audio DSP and EQ settings
    await _applyAudioEffects(state);
  }

  Future<void> _onPauseSong(
    PauseSongEvent event,
    Emitter<PlayerState> emit,
  ) async {
    await audioPlayerService.pause();
  }

  Future<void> _onResumeSong(
    ResumeSongEvent event,
    Emitter<PlayerState> emit,
  ) async {
    await audioPlayerService.resume();
  }

  Future<void> _onStopSong(
    StopSongEvent event,
    Emitter<PlayerState> emit,
  ) async {
    await audioPlayerService.stop();
  }

  Future<void> _onSeekSong(
    SeekSongEvent event,
    Emitter<PlayerState> emit,
  ) async {
    await audioPlayerService.seek(event.position);
  }

  Future<void> _onSkipNext(
    SkipNextEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final current = state.currentSong;
    if (current == null || state.queue.isEmpty) return;

    if (state.shuffleEnabled && state.queue.length > 1) {
      final currentIndex = state.queue.indexWhere(
        (song) => song.id == current.id,
      );
      int nextIndex;
      final random = math.Random();
      do {
        nextIndex = random.nextInt(state.queue.length);
      } while (nextIndex == currentIndex);

      final nextSong = state.queue[nextIndex];
      await audioPlayerService.play(nextSong);
    } else {
      final index = state.queue.indexWhere((song) => song.id == current.id);
      if (index != -1) {
        final nextIndex = (index + 1) % state.queue.length;
        final nextSong = state.queue[nextIndex];
        await audioPlayerService.play(nextSong);
      }
    }
  }

  Future<void> _onSkipPrevious(
    SkipPreviousEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final current = state.currentSong;
    if (current == null || state.queue.isEmpty) return;

    if (state.shuffleEnabled && state.queue.length > 1) {
      final currentIndex = state.queue.indexWhere(
        (song) => song.id == current.id,
      );
      int prevIndex;
      final random = math.Random();
      do {
        prevIndex = random.nextInt(state.queue.length);
      } while (prevIndex == currentIndex);

      final prevSong = state.queue[prevIndex];
      await audioPlayerService.play(prevSong);
    } else {
      final index = state.queue.indexWhere((song) => song.id == current.id);
      if (index != -1) {
        final prevIndex = (index - 1 + state.queue.length) % state.queue.length;
        final prevSong = state.queue[prevIndex];
        await audioPlayerService.play(prevSong);
      }
    }
  }

  Future<void> _onToggleFavoriteCurrentSong(
    ToggleFavoriteCurrentSongEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final current = state.currentSong;
    if (current == null) return;

    try {
      final updatedSong = await toggleFavoriteUseCase(current.id);

      // Update favorite status in current state while preserving dynamic fields like lyrics/urls
      emit(
        state.copyWith(
          currentSong: current.copyWith(isFavorite: updatedSong.isFavorite),
        ),
      );

      // Update song in the queue list too, preserving dynamic fields
      final updatedQueue = state.queue.map((s) {
        return s.id == updatedSong.id
            ? s.copyWith(isFavorite: updatedSong.isFavorite)
            : s;
      }).toList();
      emit(state.copyWith(queue: updatedQueue));

      // Notify the service about song info change (primarily for stream updates)
      if (audioPlayerService.currentSong?.id == updatedSong.id) {
        if (audioPlayerService is MockAudioPlayerService) {
          final service = audioPlayerService as MockAudioPlayerService;
          await service.seek(service.currentPosition);
        }
      }
    } catch (e) {
      // Handle error quietly
    }
  }

  Future<void> _onToggleFavoriteSongId(
    ToggleFavoriteSongIdEvent event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      final updatedSong = await toggleFavoriteUseCase(event.songId);

      // If the favorited song is the currently playing song, update its favorite status
      if (state.currentSong?.id == updatedSong.id) {
        emit(
          state.copyWith(
            currentSong: state.currentSong!.copyWith(
              isFavorite: updatedSong.isFavorite,
            ),
          ),
        );
      }

      // Update song in the queue list too, preserving dynamic fields
      final updatedQueue = state.queue.map((s) {
        return s.id == updatedSong.id
            ? s.copyWith(isFavorite: updatedSong.isFavorite)
            : s;
      }).toList();
      emit(state.copyWith(queue: updatedQueue));
    } catch (e) {
      // Handle error quietly
    }
  }

  void _onChangeAudioQuality(
    ChangeAudioQualityEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(audioQuality: event.quality));
    audioPlayerService.setAudioQuality(event.quality);
    if (state.playerState == AudioPlayerState.playing) {
      _startBitrateTimer();
      // Re-trigger PlaySongEvent on the current song to re-fetch the stream with the new quality immediately
      if (state.currentSong != null) {
        add(PlaySongEvent(song: state.currentSong!, queue: state.queue));
      }
    }
  }

  Future<void> _onUpdateSpatialAudioMode(
    UpdateSpatialAudioModeEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final newState = state.copyWith(spatialAudioMode: event.mode);
    emit(newState);
    await _applyAudioEffects(newState);
  }

  Future<void> _onUpdateHeadphoneProfile(
    UpdateHeadphoneProfileEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final newState = state.copyWith(headphoneProfile: event.profile);
    emit(newState);
    await _applyAudioEffects(newState);
  }

  Future<void> _onUpdateEqBand(
    UpdateEqBandEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final updatedBands = Map<String, double>.from(state.eqBands);
    updatedBands[event.band] = event.value;
    final newState = state.copyWith(
      eqBands: updatedBands,
      eqPresetName: 'Tùy chỉnh',
    );
    emit(newState);
    await _applyAudioEffects(newState);
  }

  Future<void> _onSelectEqPreset(
    SelectEqPresetEvent event,
    Emitter<PlayerState> emit,
  ) async {
    Map<String, double> bands;
    switch (event.preset) {
      case 'Acoustic':
        bands = const {
          '60 Hz': 2.0,
          '230 Hz': 1.0,
          '910 Hz': 0.0,
          '4 kHz': 2.0,
          '14 kHz': 3.0,
        };
        break;
      case 'Pop':
        bands = const {
          '60 Hz': 1.0,
          '230 Hz': 2.0,
          '910 Hz': 1.0,
          '4 kHz': 1.0,
          '14 kHz': 2.0,
        };
        break;
      case 'EDM':
        bands = const {
          '60 Hz': 5.0,
          '230 Hz': 2.0,
          '910 Hz': -1.0,
          '4 kHz': 2.0,
          '14 kHz': 4.0,
        };
        break;
      case 'Lofi Thư giãn':
        bands = const {
          '60 Hz': 3.0,
          '230 Hz': 1.0,
          '910 Hz': 0.0,
          '4 kHz': -1.0,
          '14 kHz': -2.0,
        };
        break;
      case 'Tăng Bass (Bass Boost)':
        bands = const {
          '60 Hz': 6.0,
          '230 Hz': 3.0,
          '910 Hz': 0.0,
          '4 kHz': 0.0,
          '14 kHz': 0.0,
        };
        break;
      case 'Mặc định':
      default:
        bands = const {
          '60 Hz': 0.0,
          '230 Hz': 0.0,
          '910 Hz': 0.0,
          '4 kHz': 0.0,
          '14 kHz': 0.0,
        };
        break;
    }
    final newState = state.copyWith(eqPresetName: event.preset, eqBands: bands);
    emit(newState);
    await _applyAudioEffects(newState);
  }

  Future<void> _applyAudioEffects(PlayerState state) async {
    // 1. Headphone Base Volume Gain
    double baseVol = 0.4;
    if (state.headphoneProfile.contains('32Ω')) {
      baseVol = 0.7;
    } else if (state.headphoneProfile.contains('250Ω')) {
      baseVol = 1.0;
    }

    // 2. EQ Volume Multiplier (Average EQ gain dB to power scale)
    double totalGain = 0.0;
    state.eqBands.forEach((_, val) => totalGain += val);
    double avgGain = totalGain / state.eqBands.length;
    double eqVolMultiplier = math.pow(10, avgGain / 40.0).toDouble();

    // 3. Spatial Audio Modifiers
    double spatialVolMultiplier = 1.0;
    double speed = 1.0;
    double balance = 0.0;

    switch (state.spatialAudioMode) {
      case 'Phòng thu tiêu chuẩn (Studio)':
        spatialVolMultiplier = 1.05;
        break;
      case 'Sân khấu trực tiếp (Live Stage)':
        spatialVolMultiplier = 1.1;
        speed = 1.02;
        balance = -0.05;
        break;
      case 'Rạp hát vòm (Cinematic Surround)':
        spatialVolMultiplier = 1.25;
        speed = 0.97;
        balance = 0.05;
        break;
      default:
        break;
    }

    // 4. Preset Speed Modifiers (Lofi / EDM presets overrides)
    if (state.eqPresetName == 'Lofi Thư giãn') {
      speed = 0.94; // slow & warm relax tempo
    } else if (state.eqPresetName == 'EDM') {
      speed = 1.04; // fast & energetic tempo
    }

    // Compute effective volume (clamped to 0.0 - 1.0)
    double effectiveVolume =
        (baseVol *
                eqVolMultiplier *
                spatialVolMultiplier *
                state.sleepTimerVolumeMultiplier)
            .clamp(0.0, 1.0);

    // Apply to service
    await audioPlayerService.setVolume(effectiveVolume);
    await audioPlayerService.setPlaybackRate(speed);
    await audioPlayerService.setBalance(balance);

    // Dynamic bitrate adjust to simulate processing load
    if (state.playerState == AudioPlayerState.playing) {
      int baseBitrate = state.audioQuality.contains('Lossless')
          ? 920
          : (state.audioQuality.contains('320') ? 320 : 128);
      int modifier = (avgGain * 3).toInt();
      if (state.spatialAudioMode != 'Tắt (Stereo gốc)') {
        modifier += 15;
      }
      add(_BitrateTickEvent(baseBitrate + modifier));
    }

    debugPrint(
      '[ChillMsic DSP] Applied: Volume=$effectiveVolume (Base=$baseVol, EQ=$eqVolMultiplier, Spatial=$spatialVolMultiplier), Speed=$speed, Balance=$balance',
    );
  }

  void _onToggleGapless(ToggleGaplessEvent event, Emitter<PlayerState> emit) {
    emit(state.copyWith(gaplessEnabled: !state.gaplessEnabled));
  }

  void _onUpdateCrossfade(
    UpdateCrossfadeEvent event,
    Emitter<PlayerState> emit,
  ) async {
    await PersistenceService.saveCrossfadeSeconds(event.seconds);
    emit(state.copyWith(crossfadeSeconds: event.seconds));
    audioPlayerService.setCrossfadeSeconds(event.seconds);
  }

  void _onToggleShuffle(ToggleShuffleEvent event, Emitter<PlayerState> emit) {
    emit(state.copyWith(shuffleEnabled: !state.shuffleEnabled));
  }

  void _onToggleRepeatMode(
    ToggleRepeatModeEvent event,
    Emitter<PlayerState> emit,
  ) {
    String nextMode;
    switch (state.repeatMode) {
      case 'off':
        nextMode = 'all';
        break;
      case 'all':
        nextMode = 'one';
        break;
      case 'one':
      default:
        nextMode = 'off';
        break;
    }
    emit(state.copyWith(repeatMode: nextMode));
  }

  void _onSetSleepTimer(SetSleepTimerEvent event, Emitter<PlayerState> emit) {
    _sleepTimer?.cancel();
    _sleepTimer = null;

    if (event.minutes <= 0) {
      emit(
        state.copyWith(
          sleepTimerRemaining: () => null,
          sleepTimerVolumeMultiplier: 1.0,
        ),
      );
      _applyAudioEffects(state);
      return;
    }

    Duration remaining = Duration(minutes: event.minutes);
    emit(
      state.copyWith(
        sleepTimerRemaining: () => remaining,
        sleepTimerVolumeMultiplier: 1.0,
      ),
    );

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.sleepTimerRemaining == null) {
        timer.cancel();
        return;
      }
      final nextRemaining =
          state.sleepTimerRemaining! - const Duration(seconds: 1);
      if (nextRemaining.inSeconds <= 0) {
        timer.cancel();
        add(const _SleepTimerTickEvent(null, volumeMultiplier: 1.0));
        add(StopSongEvent()); // Stop playback when timer reaches zero
      } else {
        double multiplier = 1.0;
        if (nextRemaining.inSeconds <= 30) {
          multiplier = nextRemaining.inSeconds / 30.0;
        }
        add(_SleepTimerTickEvent(nextRemaining, volumeMultiplier: multiplier));
      }
    });
  }

  Future<void> _updateCacheSize() async {
    final size = await AudioCacheHelper.getCacheSizeMb();
    add(UpdateAudioCacheSizeEvent(size));
  }

  Future<void> _onClearAudioCache(
    ClearAudioCacheEvent event,
    Emitter<PlayerState> emit,
  ) async {
    await AudioCacheHelper.clearCache();
    final size = await AudioCacheHelper.getCacheSizeMb();
    emit(state.copyWith(audioCacheSize: size));
  }

  Future<void> _onTranslateCurrentSongLyrics(
    TranslateCurrentSongLyricsEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final currentSong = state.currentSong;
    if (currentSong == null || currentSong.lyrics.isEmpty) return;

    emit(state.copyWith(isTranslating: true, translatedLyrics: ''));

    final apiKey = state.geminiApiKey;
    if (apiKey.isEmpty) {
      emit(
        state.copyWith(
          isTranslating: false,
          translatedLyrics:
              'Error: Vui lòng nhập Gemini API Key trong Cài đặt.',
        ),
      );
      return;
    }

    try {
      final locale = state.appLocale.toLowerCase();
      String targetLanguage = 'tiếng Việt';
      String alternativeLanguage = 'tiếng Anh';

      switch (locale) {
        case 'vi':
          targetLanguage = 'tiếng Việt';
          alternativeLanguage = 'tiếng Anh';
          break;
        case 'en':
          targetLanguage = 'tiếng Anh';
          alternativeLanguage = 'tiếng Việt';
          break;
        case 'ko':
          targetLanguage = 'tiếng Hàn';
          alternativeLanguage = 'tiếng Anh';
          break;
        case 'ja':
          targetLanguage = 'tiếng Nhật';
          alternativeLanguage = 'tiếng Anh';
          break;
        case 'zh':
          targetLanguage = 'tiếng Trung';
          alternativeLanguage = 'tiếng Anh';
          break;
        case 'fr':
          targetLanguage = 'tiếng Pháp';
          alternativeLanguage = 'tiếng Anh';
          break;
        case 'de':
          targetLanguage = 'tiếng Đức';
          alternativeLanguage = 'tiếng Anh';
          break;
        case 'es':
          targetLanguage = 'tiếng Tây Ban Nha';
          alternativeLanguage = 'tiếng Anh';
          break;
        default:
          targetLanguage = 'ngôn ngữ mã "$locale"';
          alternativeLanguage = 'tiếng Anh';
      }

      final prompt =
          'Dịch lời bài hát sau đây sang $targetLanguage (nếu lời bài hát gốc không phải là $targetLanguage) hoặc sang $alternativeLanguage (nếu lời bài hát gốc đã là $targetLanguage) theo phong cách thơ ca, truyền cảm. Dịch song ngữ dòng-dòng (dòng gốc và dòng dịch ngay bên dưới nó) hoặc nếu có nhãn thời gian thì hãy giữ nguyên vị trí nhãn thời gian và dịch phần lời của dòng đó. Chỉ trả về kết quả lời dịch, không có tiêu đề hay giải thích nào khác.\n\nLời bài hát:\n${currentSong.lyrics}';

      final text = await GeminiService.generateContent(
        apiKey: apiKey,
        prompt: prompt,
      );
      emit(state.copyWith(isTranslating: false, translatedLyrics: text));
    } catch (e) {
      emit(
        state.copyWith(
          isTranslating: false,
          translatedLyrics: 'Error: Lỗi kết nối: $e',
        ),
      );
    }
  }

  Future<void> _onGenerateMoodPlaylist(
    GenerateMoodPlaylistEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final mood = event.mood.trim();
    if (mood.isEmpty) return;

    emit(state.copyWith(isGeneratingMoodPlaylist: true));

    final apiKey = state.geminiApiKey;
    if (apiKey.isEmpty) {
      emit(state.copyWith(isGeneratingMoodPlaylist: false));
      return;
    }

    try {
      final prompt =
          '''
Hãy đóng vai một chuyên gia âm nhạc và phân tích tâm trạng: "$mood".
Đề xuất 5 bài hát (tiếng Việt hoặc tiếng Anh nổi tiếng) phù hợp nhất với tâm trạng này.
Yêu cầu trả về kết quả định dạng JSON là một danh sách các đối tượng có tên bài hát (title) và ca sĩ (artist) chính xác như ví dụ sau, không chứa bất kỳ văn bản giải thích hay ký tự markdown nào:
[
  {"title": "Tên bài hát 1", "artist": "Ca sĩ 1"},
  {"title": "Tên bài hát 2", "artist": "Ca sĩ 2"}
]
''';

      String text = await GeminiService.generateContent(
        apiKey: apiKey,
        prompt: prompt,
      );
      text = text.trim();
      if (text.contains('```')) {
        text = text.replaceAll(RegExp(r'```json|```'), '').trim();
      }
      final List<dynamic> songListDecoded = jsonDecode(text);
      final List<Song> resolvedSongs = [];

      for (final songItem in songListDecoded) {
        final title = songItem['title'] ?? '';
        final artist = songItem['artist'] ?? '';
        if (title.isEmpty) continue;

        // Search on the backend
        try {
          final searchUrl = Uri.parse(
            '${state.apiServerUrl}/api/search?q=${Uri.encodeComponent('$title $artist')}',
          );
          final searchResponse = await http
              .get(searchUrl)
              .timeout(const Duration(seconds: 4));
          if (searchResponse.statusCode == 200) {
            final List<dynamic> searchResults = json.decode(
              utf8.decode(searchResponse.bodyBytes),
            );
            if (searchResults.isNotEmpty) {
              final item = searchResults.first;
              resolvedSongs.add(
                Song(
                  id: item['id'] as String? ?? '',
                  title: item['title'] as String? ?? title,
                  artist: item['artist'] as String? ?? artist,
                  album: 'AI Mood - $mood',
                  duration: '03:30',
                  coverUrl:
                      item['thumbnail'] as String? ??
                      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=90&w=1200',
                  audioUrl: '',
                  format: 'MP3 High-Res',
                  bitrate: '320 kbps',
                  sampleRate: '44.1 kHz',
                  releaseDate: 'AI Generated',
                  composer: 'AI Composer',
                  copyright: '© ChillMsic AI',
                  lyrics: 'Đang tải lời bài hát...',
                ),
              );
            }
          }
        } catch (_) {
          // Fallback placeholder
          resolvedSongs.add(
            Song(
              id: 'ai_${DateTime.now().microsecondsSinceEpoch}',
              title: title,
              artist: artist,
              album: 'AI Mood - $mood',
              duration: '03:00',
              coverUrl:
                  'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=90&w=1200',
              audioUrl: '',
              format: 'MP3 High-Res',
              bitrate: '320 kbps',
              sampleRate: '44.1 kHz',
              releaseDate: 'AI Generated',
              composer: 'AI Composer',
              copyright: '© ChillMsic AI',
              lyrics: 'Đang tải lời bài hát...',
            ),
          );
        }
      }

      if (resolvedSongs.isNotEmpty) {
        final String newPlaylistId =
            'ai_${DateTime.now().millisecondsSinceEpoch}';
        final String playlistName = 'AI: $mood';
        final newPlaylist = Playlist(
          id: newPlaylistId,
          name: playlistName,
          songs: resolvedSongs,
        );
        final updatedPlaylists = List<Playlist>.from(state.customPlaylists)
          ..add(newPlaylist);

        await PersistenceService.savePlaylists(
          updatedPlaylists.map((p) => p.toJson()).toList(),
        );
        emit(
          state.copyWith(
            customPlaylists: updatedPlaylists,
            isGeneratingMoodPlaylist: false,
          ),
        );
        return;
      }
    } catch (_) {}

    emit(state.copyWith(isGeneratingMoodPlaylist: false));
  }

  Future<void> _onDownloadSong(
    DownloadSongEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final song = event.song;
    if (state.downloadedSongs.any((s) => s.id == song.id)) {
      return;
    }
    if (state.downloadingSongIds.contains(song.id)) {
      return;
    }

    final updatedDownloading = Set<String>.from(state.downloadingSongIds)
      ..add(song.id);
    emit(state.copyWith(downloadingSongIds: updatedDownloading));

    try {
      final targetDir = await AudioCacheHelper.getCacheDirectory();
      final cacheFile = File('${targetDir.path}/${song.id}.mp3');
      if (!await cacheFile.exists()) {
        final String streamUrl =
            '${state.apiServerUrl}/api/stream/${song.id}?quality=lossless';
        debugPrint(
          '[ChillMsic Download] Bắt đầu tải nhạc offline cho ID ${song.id}: $streamUrl',
        );
        final response = await http
            .get(Uri.parse(streamUrl))
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          await cacheFile.writeAsBytes(response.bodyBytes);
          debugPrint(
            '[ChillMsic Download] Đã tải và lưu thành công bài hát ${song.id}',
          );
        } else {
          throw Exception(
            'Backend returned status code ${response.statusCode}',
          );
        }
      }

      // Add to downloaded lists
      final List<Song> newDownloaded = List<Song>.from(state.downloadedSongs);
      if (!newDownloaded.any((s) => s.id == song.id)) {
        newDownloaded.add(song);
      }
      await PersistenceService.saveDownloadedSongs(
        newDownloaded.map((s) => s.toJson()).toList(),
      );

      final updatedDownloadingFinished = Set<String>.from(
        state.downloadingSongIds,
      )..remove(song.id);
      emit(
        state.copyWith(
          downloadedSongs: newDownloaded,
          downloadingSongIds: updatedDownloadingFinished,
        ),
      );
    } catch (e) {
      debugPrint(
        '[ChillMsic Download] Lỗi tải nhạc offline cho ID ${song.id}: $e',
      );
      final updatedDownloadingError = Set<String>.from(state.downloadingSongIds)
        ..remove(song.id);
      emit(state.copyWith(downloadingSongIds: updatedDownloadingError));
    }
  }

  Future<void> _onDeleteDownloadedSong(
    DeleteDownloadedSongEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final songId = event.songId;
    try {
      final targetDir = await AudioCacheHelper.getCacheDirectory();
      final cacheFile = File('${targetDir.path}/$songId.mp3');
      if (await cacheFile.exists()) {
        await cacheFile.delete();
        debugPrint(
          '[ChillMsic Download] Đã xóa file nhạc offline của ID $songId',
        );
      }

      final List<Song> newDownloaded = state.downloadedSongs
          .where((s) => s.id != songId)
          .toList();
      await PersistenceService.saveDownloadedSongs(
        newDownloaded.map((s) => s.toJson()).toList(),
      );

      emit(state.copyWith(downloadedSongs: newDownloaded));
    } catch (e) {
      debugPrint('[ChillMsic Download] Lỗi khi xóa nhạc offline: $e');
    }
  }

  @override
  Future<void> close() {
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _currentSongSubscription?.cancel();
    _bitrateTimer?.cancel();
    _sleepTimer?.cancel();
    return super.close();
  }
}
