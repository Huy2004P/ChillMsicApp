import '../../domain/entities/song.dart';

class SongModel extends Song {
  const SongModel({
    required super.id,
    required super.title,
    required super.artist,
    required super.album,
    required super.duration,
    required super.coverUrl,
    required super.audioUrl,
    super.isFavorite,
    required super.format,
    required super.bitrate,
    required super.sampleRate,
    required super.releaseDate,
    required super.composer,
    required super.copyright,
    required super.lyrics,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      duration: json['duration'] as String,
      coverUrl: json['coverUrl'] as String,
      audioUrl: json['audioUrl'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      format: json['format'] as String,
      bitrate: json['bitrate'] as String,
      sampleRate: json['sampleRate'] as String,
      releaseDate: json['releaseDate'] as String,
      composer: json['composer'] as String,
      copyright: json['copyright'] as String,
      lyrics: json['lyrics'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'isFavorite': isFavorite,
      'format': format,
      'bitrate': bitrate,
      'sampleRate': sampleRate,
      'releaseDate': releaseDate,
      'composer': composer,
      'copyright': copyright,
      'lyrics': lyrics,
    };
  }

  factory SongModel.fromEntity(Song entity) {
    return SongModel(
      id: entity.id,
      title: entity.title,
      artist: entity.artist,
      album: entity.album,
      duration: entity.duration,
      coverUrl: entity.coverUrl,
      audioUrl: entity.audioUrl,
      isFavorite: entity.isFavorite,
      format: entity.format,
      bitrate: entity.bitrate,
      sampleRate: entity.sampleRate,
      releaseDate: entity.releaseDate,
      composer: entity.composer,
      copyright: entity.copyright,
      lyrics: entity.lyrics,
    );
  }
}
