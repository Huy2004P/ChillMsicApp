import 'dart:async';
import '../../features/music_player/domain/entities/song.dart';

enum AudioPlayerState {
  idle,
  buffering,
  ready,
  playing,
  paused,
  completed,
}

abstract class AudioPlayerService {
  Stream<AudioPlayerState> get stateStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<Song?> get currentSongStream;

  AudioPlayerState get currentState;
  Duration get currentPosition;
  Duration get currentDuration;
  Song? get currentSong;

  Future<void> play(Song song);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setPlaybackRate(double speed);
  Future<void> setBalance(double balance);
  Future<void> setAudioQuality(String quality);
  void setCrossfadeSeconds(int seconds);
  Future<void> dispose();
}
