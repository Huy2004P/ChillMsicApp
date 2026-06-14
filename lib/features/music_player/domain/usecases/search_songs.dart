import '../entities/song.dart';
import '../repositories/music_repository.dart';

class SearchSongs {
  final MusicRepository repository;

  SearchSongs(this.repository);

  Future<List<Song>> call(String query) async {
    return await repository.searchSongs(query);
  }
}
