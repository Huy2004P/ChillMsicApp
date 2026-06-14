import 'dart:async';
import '../../features/music_player/domain/entities/song.dart';
import 'audio_player_service.dart';

class MockAudioPlayerService implements AudioPlayerService {
  final _stateController = StreamController<AudioPlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _currentSongController = StreamController<Song?>.broadcast();

  AudioPlayerState _state = AudioPlayerState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Song? _currentSong;
  Timer? _timer;

  MockAudioPlayerService() {
    // Emit initial states
    _emitState();
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
  Future<void> play(Song song) async {
    _timer?.cancel();
    _state = AudioPlayerState.buffering;
    _stateController.add(_state);

    // Simulate network buffering delay of 400ms
    await Future.delayed(const Duration(milliseconds: 400));

    _currentSong = song;
    _currentSongController.add(_currentSong);

    // Set duration from song
    final parts = song.duration.split(':');
    if (parts.length == 2) {
      final minutes = int.parse(parts[0]);
      final seconds = int.parse(parts[1]);
      _duration = Duration(minutes: minutes, seconds: seconds);
    } else {
      _duration = const Duration(minutes: 3, seconds: 30); // fallback
    }
    _durationController.add(_duration);

    // Reset position if playing a new song or if it was completed
    if (_state == AudioPlayerState.completed || _position >= _duration) {
      _position = Duration.zero;
    }

    _state = AudioPlayerState.playing;
    _stateController.add(_state);
    _positionController.add(_position);

    _startTimer();
  }

  @override
  Future<void> pause() async {
    _timer?.cancel();
    if (_state == AudioPlayerState.playing) {
      _state = AudioPlayerState.paused;
      _stateController.add(_state);
    }
  }

  @override
  Future<void> resume() async {
    if (_currentSong != null && _state == AudioPlayerState.paused) {
      _state = AudioPlayerState.playing;
      _stateController.add(_state);
      _startTimer();
    }
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _state = AudioPlayerState.idle;
    _position = Duration.zero;
    _stateController.add(_state);
    _positionController.add(_position);
  }

  @override
  Future<void> seek(Duration position) async {
    if (position < Duration.zero) {
      _position = Duration.zero;
    } else if (position > _duration) {
      _position = _duration;
    } else {
      _position = position;
    }
    _positionController.add(_position);

    if (_state == AudioPlayerState.completed && _position < _duration) {
      _state = AudioPlayerState.paused;
      _stateController.add(_state);
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    // Mock volume update
  }

  @override
  Future<void> setPlaybackRate(double speed) async {
    // Mock playback rate update
  }

  @override
  Future<void> setBalance(double balance) async {
    // Mock balance update
  }

  @override
  Future<void> setAudioQuality(String quality) async {
    // Mock audio quality update
  }

  @override
  void setCrossfadeSeconds(int seconds) {
    // Mock crossfade configuration
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _currentSongController.close();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_state == AudioPlayerState.playing) {
        final newPosition = _position + const Duration(milliseconds: 200);
        if (newPosition >= _duration) {
          _position = _duration;
          _positionController.add(_position);
          _state = AudioPlayerState.completed;
          _stateController.add(_state);
          _timer?.cancel();
        } else {
          _position = newPosition;
          _positionController.add(_position);
        }
      }
    });
  }
}
