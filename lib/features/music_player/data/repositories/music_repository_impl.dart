import '../../domain/entities/song.dart';
import '../../domain/repositories/music_repository.dart';
import '../datasources/music_remote_data_source.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicRemoteDataSource remoteDataSource;
  
  // Local cache to preserve state modifications during app execution
  List<Song>? _cachedSongs;
  
  // Cache of all resolved songs to prevent "Song not found" errors
  final Map<String, Song> _allResolvedSongs = {};

  MusicRepositoryImpl({required this.remoteDataSource});

  Future<List<Song>> _getOrFetchSongs() async {
    if (_cachedSongs != null) {
      return _cachedSongs!;
    }
    final songModels = await remoteDataSource.getSongs();
    _cachedSongs = List<Song>.from(songModels);
    for (final song in _cachedSongs!) {
      _allResolvedSongs[song.id] = song;
    }
    return _cachedSongs!;
  }

  @override
  Future<List<Song>> getSongs() async {
    return await _getOrFetchSongs();
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      return await _getOrFetchSongs();
    }
    
    // 1. Fetch remote search results from backend
    final searchModels = await remoteDataSource.searchSongs(query);
    
    // 2. Fetch full details in parallel for each search result (gets duration, lyrics, composer etc.)
    final resolvedModels = await Future.wait(searchModels.map((model) async {
      try {
        final existing = _allResolvedSongs[model.id];
        if (existing != null && existing.duration != '00:00' && existing.duration != '0::00' && existing.duration.isNotEmpty) {
          return existing;
        }
        final detailed = await remoteDataSource.getSongDetail(model.id);
        return detailed;
      } catch (e) {
        return model;
      }
    }));

    final searchSongs = List<Song>.from(resolvedModels);
    
    // 3. Register them in _allResolvedSongs and synchronize favorite state
    for (var i = 0; i < searchSongs.length; i++) {
      final s = searchSongs[i];
      final existing = _allResolvedSongs[s.id];
      if (existing != null) {
        searchSongs[i] = s.copyWith(isFavorite: existing.isFavorite);
        _allResolvedSongs[s.id] = searchSongs[i];
      } else {
        _allResolvedSongs[s.id] = s;
      }
    }
    
    return searchSongs;
  }

  @override
  Future<Song> toggleFavorite(String songId) async {
    // Ensure home list is loaded so _cachedSongs is initialized
    await _getOrFetchSongs();
    
    final song = _allResolvedSongs[songId];
    if (song != null) {
      final updatedSong = song.copyWith(isFavorite: !song.isFavorite);
      _allResolvedSongs[songId] = updatedSong;
      
      // Update in cached songs list
      final index = _cachedSongs!.indexWhere((s) => s.id == songId);
      if (index != -1) {
        _cachedSongs![index] = updatedSong;
      } else {
        _cachedSongs!.add(updatedSong);
      }
      return updatedSong;
    }
    
    throw Exception('Song not found');
  }
}
