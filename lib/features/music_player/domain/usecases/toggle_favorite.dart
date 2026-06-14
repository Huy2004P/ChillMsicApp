import '../entities/song.dart';
import '../repositories/music_repository.dart';

class ToggleFavorite {
  final MusicRepository repository;

  ToggleFavorite(this.repository);

  Future<Song> call(String songId) async {
    return await repository.toggleFavorite(songId);
  }
}
