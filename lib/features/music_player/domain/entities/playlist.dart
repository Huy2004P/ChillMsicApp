import 'package:equatable/equatable.dart';
import 'song.dart';

class Playlist extends Equatable {
  final String id;
  final String name;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.name,
    required this.songs,
  });

  Playlist copyWith({
    String? id,
    String? name,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((s) => s.toJson()).toList(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final songsJson = json['songs'] as List? ?? [];
    return Playlist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      songs: songsJson.map((s) => Song.fromJson(Map<String, dynamic>.from(s))).toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, songs];
}
