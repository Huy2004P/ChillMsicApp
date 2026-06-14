import '../entities/song.dart';
import '../repositories/music_repository.dart';

class GetSongs {
  final MusicRepository repository;

  GetSongs(this.repository);

  Future<List<Song>> call() async {
    return await repository.getSongs();
  }
}
