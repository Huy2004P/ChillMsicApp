import '../entities/song.dart';

abstract class MusicRepository {
  Future<List<Song>> getSongs();
  Future<List<Song>> searchSongs(String query);
  Future<Song> toggleFavorite(String songId);
}
