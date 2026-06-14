import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final String coverUrl;
  final String audioUrl;
  final bool isFavorite;
  
  // Technical details according to DESIGN.md specs
  final String format;
  final String bitrate;
  final String sampleRate;
  final String releaseDate;
  final String composer;
  final String copyright;
  final String lyrics;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.coverUrl,
    required this.audioUrl,
    this.isFavorite = false,
    required this.format,
    required this.bitrate,
    required this.sampleRate,
    required this.releaseDate,
    required this.composer,
    required this.copyright,
    required this.lyrics,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? duration,
    String? coverUrl,
    String? audioUrl,
    bool? isFavorite,
    String? format,
    String? bitrate,
    String? sampleRate,
    String? releaseDate,
    String? composer,
    String? copyright,
    String? lyrics,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      format: format ?? this.format,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      releaseDate: releaseDate ?? this.releaseDate,
      composer: composer ?? this.composer,
      copyright: copyright ?? this.copyright,
      lyrics: lyrics ?? this.lyrics,
    );
  }

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

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      album: json['album'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
      format: json['format'] as String? ?? '',
      bitrate: json['bitrate'] as String? ?? '',
      sampleRate: json['sampleRate'] as String? ?? '',
      releaseDate: json['releaseDate'] as String? ?? '',
      composer: json['composer'] as String? ?? '',
      copyright: json['copyright'] as String? ?? '',
      lyrics: json['lyrics'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        duration,
        coverUrl,
        audioUrl,
        isFavorite,
        format,
        bitrate,
        sampleRate,
        releaseDate,
        composer,
        copyright,
        lyrics,
      ];
}
