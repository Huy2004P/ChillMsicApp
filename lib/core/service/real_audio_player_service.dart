import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import '../../features/music_player/domain/entities/song.dart';
import '../../features/music_player/data/datasources/music_remote_data_source.dart';
import 'audio_player_service.dart';

class RealAudioPlayerService implements AudioPlayerService {
  final _player1 = ap.AudioPlayer();
  final _player2 = ap.AudioPlayer();
  bool _isPlayer1Active = true;
  int _crossfadeSeconds = 0;
  Timer? _crossfadeTimer;

  final _stateController = StreamController<AudioPlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _currentSongController = StreamController<Song?>.broadcast();

  AudioPlayerState _state = AudioPlayerState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Song? _currentSong;
  String _audioQuality = 'lossless';

  // Subscriptions for Player 1
  StreamSubscription? _p1StateSub;
  StreamSubscription? _p1PositionSub;
  StreamSubscription? _p1DurationSub;
  StreamSubscription? _p1CompleteSub;

  // Subscriptions for Player 2
  StreamSubscription? _p2StateSub;
  StreamSubscription? _p2PositionSub;
  StreamSubscription? _p2DurationSub;
  StreamSubscription? _p2CompleteSub;

  ap.AudioPlayer get _activePlayer => _isPlayer1Active ? _player1 : _player2;

  RealAudioPlayerService() {
    _emitState();

    // Setup Player 1 Listeners
    _p1StateSub = _player1.onPlayerStateChanged.listen((apState) {
      if (_isPlayer1Active) {
        _handleStateChange(apState);
      }
    });

    _p1PositionSub = _player1.onPositionChanged.listen((pos) {
      if (_isPlayer1Active) {
        _position = pos;
        _positionController.add(_position);
      }
    });

    _p1DurationSub = _player1.onDurationChanged.listen((dur) {
      if (_isPlayer1Active) {
        _duration = dur;
        _durationController.add(_duration);
      }
    });

    _p1CompleteSub = _player1.onPlayerComplete.listen((_) {
      if (_isPlayer1Active) {
        _state = AudioPlayerState.completed;
        _stateController.add(_state);
      }
    });

    // Setup Player 2 Listeners
    _p2StateSub = _player2.onPlayerStateChanged.listen((apState) {
      if (!_isPlayer1Active) {
        _handleStateChange(apState);
      }
    });

    _p2PositionSub = _player2.onPositionChanged.listen((pos) {
      if (!_isPlayer1Active) {
        _position = pos;
        _positionController.add(_position);
      }
    });

    _p2DurationSub = _player2.onDurationChanged.listen((dur) {
      if (!_isPlayer1Active) {
        _duration = dur;
        _durationController.add(_duration);
      }
    });

    _p2CompleteSub = _player2.onPlayerComplete.listen((_) {
      if (!_isPlayer1Active) {
        _state = AudioPlayerState.completed;
        _stateController.add(_state);
      }
    });
  }

  void _handleStateChange(ap.PlayerState apState) {
    switch (apState) {
      case ap.PlayerState.playing:
        _state = AudioPlayerState.playing;
        break;
      case ap.PlayerState.paused:
        _state = AudioPlayerState.paused;
        break;
      case ap.PlayerState.stopped:
        _state = AudioPlayerState.idle;
        break;
      case ap.PlayerState.completed:
        _state = AudioPlayerState.completed;
        break;
      default:
        _state = AudioPlayerState.idle;
        break;
    }
    _stateController.add(_state);
  }

  void _emitState() {
    _stateController.add(_state);
    _positionController.add(_position);
    _durationController.add(_duration);
    _currentSongController.add(_currentSong);
  }

  @override
  Stream<AudioPlayerState> get stateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<Song?> get currentSongStream => _currentSongController.stream;

  @override
  AudioPlayerState get currentState => _state;

  @override
  Duration get currentPosition => _position;

  @override
  Duration get currentDuration => _duration;

  @override
  Song? get currentSong => _currentSong;

  @override
  void setCrossfadeSeconds(int seconds) {
    _crossfadeSeconds = seconds;
    debugPrint('[ChillMsic Crossfade] Cập nhật thời gian trộn nhạc: $seconds giây');
  }

  void _startCrossfadeTransition(ap.AudioPlayer fadeOutPlayer, ap.AudioPlayer fadeInPlayer, int durationSeconds) {
    _crossfadeTimer?.cancel();

    fadeOutPlayer.setVolume(1.0);
    fadeInPlayer.setVolume(0.0);

    final int steps = durationSeconds * 10; // 10 steps per second (100ms interval)
    if (steps <= 0) {
      fadeOutPlayer.stop();
      fadeOutPlayer.setVolume(1.0);
      fadeInPlayer.setVolume(1.0);
      return;
    }

    int currentStep = 0;
    _crossfadeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      currentStep++;
      final double progress = currentStep / steps;
      
      try {
        await fadeOutPlayer.setVolume((1.0 - progress).clamp(0.0, 1.0));
        await fadeInPlayer.setVolume(progress.clamp(0.0, 1.0));
      } catch (e) {
        debugPrint('[ChillMsic Crossfade] Lỗi setVolume trong quá trình trộn: $e');
      }

      if (currentStep >= steps) {
        timer.cancel();
        try {
          await fadeOutPlayer.stop();
          await fadeOutPlayer.setVolume(1.0);
          await fadeInPlayer.setVolume(1.0);
          debugPrint('[ChillMsic Crossfade] Quá trình trộn nhạc hoàn tất.');
        } catch (e) {
          debugPrint('[ChillMsic Crossfade] Lỗi kết thúc trộn nhạc: $e');
        }
      }
    });
  }

  @override
  Future<void> play(Song song) async {
    final bool shouldCrossfade = _crossfadeSeconds > 0 && 
                                 _state == AudioPlayerState.playing && 
                                 _currentSong != null;

    ap.AudioPlayer targetPlayer;
    ap.AudioPlayer? oldPlayer;

    if (shouldCrossfade) {
      oldPlayer = _activePlayer;
      _isPlayer1Active = !_isPlayer1Active;
      targetPlayer = _activePlayer;
      debugPrint('[ChillMsic Crossfade] Trộn nhạc: ${_isPlayer1Active ? "Player 2 -> Player 1" : "Player 1 -> Player 2"}');
    } else {
      _crossfadeTimer?.cancel();
      try {
        await _player1.stop().timeout(const Duration(seconds: 1));
        await _player2.stop().timeout(const Duration(seconds: 1));
        await _player1.setVolume(1.0);
        await _player2.setVolume(1.0);
      } catch (e) {
        debugPrint('[ChillMsic Debug] Lỗi khi dừng các trình phát: $e');
      }
      targetPlayer = _activePlayer;
    }

    _state = AudioPlayerState.buffering;
    _stateController.add(_state);

    _position = Duration.zero;
    _positionController.add(_position);

    _currentSong = song;
    _currentSongController.add(_currentSong);

    final bool isMockOrLocal =
        song.audioUrl.contains('soundhelix.com') ||
        song.audioUrl.startsWith('file://');

    // Check offline audio cache
    final cacheDir = await getTemporaryDirectory();
    final cacheFile = File('${cacheDir.path}/cached_songs/${song.id}.mp3');
    bool isCached = await cacheFile.exists();

    String streamUrl = song.audioUrl;
    Song updatedSong = song;

    if (isCached) {
      debugPrint(
        '[ChillMsic Cache] Đang phát bài hát từ cache cục bộ: ${cacheFile.path}',
      );
      try {
        await targetPlayer
            .play(ap.DeviceFileSource(cacheFile.path))
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint(
          '[ChillMsic Cache] Lỗi phát file cache, chuyển sang phát online: $e',
        );
        isCached = false;
      }

      // Load details & lyrics asynchronously if empty
      if (!isMockOrLocal &&
          (song.lyrics.isEmpty || song.composer == 'Không rõ')) {
        _fetchAndEmitSongDetails(song, _audioQuality);
      }
    }

    if (!isCached && !isMockOrLocal) {
      final proxyUrl = '${HttpMusicRemoteDataSourceImpl.baseUrl}/api/stream/${song.id}?quality=$_audioQuality';
      streamUrl = proxyUrl;

      try {
        debugPrint(
          '[ChillMsic Debug] Đang lấy thông tin chi tiết bài hát từ BE cho ID: ${song.id} (Chất lượng: $_audioQuality)',
        );
        final response = await http.get(
          Uri.parse(
            '${HttpMusicRemoteDataSourceImpl.baseUrl}/api/song/${song.id}?quality=$_audioQuality',
          ),
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(
            utf8.decode(response.bodyBytes),
          );
          final freshLyric = data['lyric'] as String? ?? '';
          final freshComposer = data['composer'] as String? ?? 'Không rõ';
          final freshGenre = data['genre'] as String? ?? 'N/A';

          debugPrint(
            '[ChillMsic Debug] Lấy chi tiết thành công. Sử dụng URL proxy: $proxyUrl',
          );

          updatedSong = song.copyWith(
            audioUrl: proxyUrl,
            lyrics: freshLyric,
            composer: freshComposer,
            album: freshGenre,
          );
          _currentSong = updatedSong;
          _currentSongController.add(_currentSong);
        } else {
          debugPrint(
            '[ChillMsic Debug] Lỗi phản hồi HTTP: ${response.statusCode}, sử dụng URL proxy làm mặc định',
          );
          updatedSong = song.copyWith(audioUrl: proxyUrl);
          _currentSong = updatedSong;
          _currentSongController.add(_currentSong);
        }
      } catch (e) {
        debugPrint(
          '[ChillMsic Debug] Lỗi khi tải chi tiết bài hát ($e), sử dụng URL proxy làm mặc định',
        );
        updatedSong = song.copyWith(audioUrl: proxyUrl);
        _currentSong = updatedSong;
        _currentSongController.add(_currentSong);
      }
    }

    if (!isCached) {
      try {
        await targetPlayer
            .play(ap.UrlSource(streamUrl))
            .timeout(const Duration(seconds: 3));

        // Background cache download
        if (!isMockOrLocal && streamUrl.startsWith('http')) {
          _downloadToCache(song.id, streamUrl);
        }
      } catch (e) {
        debugPrint('[ChillMsic Debug] Lỗi phát nhạc: $e');
        _state = AudioPlayerState.idle;
        _stateController.add(_state);
      }
    }

    if (shouldCrossfade && oldPlayer != null) {
      _startCrossfadeTransition(oldPlayer, targetPlayer, _crossfadeSeconds);
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _activePlayer.pause().timeout(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('[ChillMsic Debug] Lỗi khi tạm dừng: $e');
    }
  }

  @override
  Future<void> resume() async {
    try {
      await _activePlayer.resume().timeout(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('[ChillMsic Debug] Lỗi khi tiếp tục phát: $e');
    }
  }

  @override
  Future<void> stop() async {
    _crossfadeTimer?.cancel();
    try {
      await _player1.stop().timeout(const Duration(seconds: 1));
      await _player2.stop().timeout(const Duration(seconds: 1));
      await _player1.setVolume(1.0);
      await _player2.setVolume(1.0);
    } catch (e) {
      debugPrint('[ChillMsic Debug] Lỗi khi dừng các trình phát: $e');
    }
    _state = AudioPlayerState.idle;
    _stateController.add(_state);
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _activePlayer.seek(position).timeout(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('[ChillMsic Debug] Lỗi/Timeout khi seek: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      await _activePlayer
          .setVolume(volume)
          .timeout(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('[ChillMsic Debug] Lỗi khi cài âm lượng: $e');
    }
  }

  @override
  Future<void> setPlaybackRate(double speed) async {
    try {
      await _activePlayer
          .setPlaybackRate(speed)
          .timeout(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('[ChillMsic Debug] Lỗi khi cài tốc độ phát: $e');
    }
  }

  @override
  Future<void> setBalance(double balance) async {
    try {
      await _activePlayer
          .setBalance(balance)
          .timeout(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('[ChillMsic Debug] Lỗi khi cài balance: $e');
    }
  }

  @override
  Future<void> setAudioQuality(String quality) async {
    if (quality.contains('128')) {
      _audioQuality = 'standard';
    } else if (quality.contains('320')) {
      _audioQuality = 'high';
    } else {
      _audioQuality = 'lossless';
    }
  }

  @override
  Future<void> dispose() async {
    _crossfadeTimer?.cancel();
    await _p1StateSub?.cancel();
    await _p1PositionSub?.cancel();
    await _p1DurationSub?.cancel();
    await _p1CompleteSub?.cancel();
    await _p2StateSub?.cancel();
    await _p2PositionSub?.cancel();
    await _p2DurationSub?.cancel();
    await _p2CompleteSub?.cancel();
    await _player1.dispose();
    await _player2.dispose();
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _currentSongController.close();
  }

  Future<void> _fetchAndEmitSongDetails(Song song, String quality) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${HttpMusicRemoteDataSourceImpl.baseUrl}/api/song/${song.id}?quality=$quality',
        ),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final freshLyric = data['lyric'] as String? ?? '';
        final freshComposer = data['composer'] as String? ?? 'Không rõ';
        final freshGenre = data['genre'] as String? ?? 'N/A';

        if (_currentSong?.id == song.id) {
          _currentSong = _currentSong?.copyWith(
            lyrics: freshLyric,
            composer: freshComposer,
            album: freshGenre,
          );
          _currentSongController.add(_currentSong);
        }
      }
    } catch (_) {}
  }

  Future<void> _downloadToCache(String id, String url) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final targetDir = Directory('${cacheDir.path}/cached_songs');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final cacheFile = File('${targetDir.path}/$id.mp3');
      if (await cacheFile.exists()) return;

      debugPrint(
        '[ChillMsic Cache] Bắt đầu tải bài hát $id về bộ nhớ đệm: $url',
      );
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await cacheFile.writeAsBytes(response.bodyBytes);
        debugPrint(
          '[ChillMsic Cache] Đã lưu nhạc vào cache thành công: ${cacheFile.path}',
        );
      }
    } catch (e) {
      debugPrint('[ChillMsic Cache] Lỗi tải nhạc về bộ nhớ đệm: $e');
    }
  }
}
