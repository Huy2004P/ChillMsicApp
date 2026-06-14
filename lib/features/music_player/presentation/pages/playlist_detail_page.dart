import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/service/audio_player_service.dart';
import '../../../../core/localization/localization_extension.dart';
import '../bloc/player_bloc.dart';
import '../widgets/meta_components.dart';

class PlaylistDetailPage extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        final playlistIndex = state.customPlaylists.indexWhere((p) => p.id == playlistId);
        if (playlistIndex == -1) {
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: AppBar(backgroundColor: AppColors.canvas, elevation: 0),
            body: Center(
              child: Text(
                context.tr('playlist_not_found'),
                style: AppTypography.bodyMd,
              ),
            ),
          );
        }

        final playlist = state.customPlaylists[playlistIndex];
        final songs = playlist.songs;

        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            backgroundColor: AppColors.canvas,
            elevation: 0,
            title: Text(
              playlist.name,
              style: AppTypography.headingSm.copyWith(fontWeight: FontWeight.w700),
            ),
            centerTitle: false,
            leading: Center(
              child: MetaIconCircularButton(
                icon: Icons.keyboard_arrow_left,
                size: 32,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: songs.isEmpty
                  ? _buildEmptyState(context, playlist.name)
                  : Column(
                      children: [
                        // Header info
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  color: AppColors.surfaceSoft,
                                  child: songs.isNotEmpty
                                      ? Image.network(
                                          songs.first.coverUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(Icons.music_note, size: 48, color: AppColors.stone),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playlist.name,
                                      style: AppTypography.subtitleLg.copyWith(fontSize: 22, color: AppColors.inkDeep),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.tr('songs_count', args: {'count': '${songs.length}'}),
                                      style: AppTypography.bodySm.copyWith(color: AppColors.charcoal),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Play all action button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: MetaButton(
                              label: context.tr('play_all').toUpperCase(),
                              type: MetaButtonType.primary,
                              icon: Icons.play_arrow_rounded,
                              onPressed: () {
                                context.read<PlayerBloc>().add(PlaySongEvent(
                                  song: songs.first,
                                  queue: songs,
                                ));
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // List of songs
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            physics: const BouncingScrollPhysics(),
                            itemCount: songs.length,
                            itemBuilder: (context, index) {
                              final song = songs[index];
                              final isPlayingThis = state.currentSong?.id == song.id;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPlayingThis ? AppColors.surfaceSoft : AppColors.canvas,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isPlayingThis ? AppColors.primary : AppColors.hairlineSoft,
                                    width: isPlayingThis ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        song.coverUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 44,
                                          height: 44,
                                          color: AppColors.steel,
                                          child: const Icon(Icons.music_note, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.title,
                                            style: AppTypography.bodySmBold.copyWith(
                                              color: isPlayingThis ? AppColors.primaryDeep : AppColors.inkDeep,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            song.artist,
                                            style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      song.duration,
                                      style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.critical, size: 20),
                                      onPressed: () {
                                        context.read<PlayerBloc>().add(RemoveSongFromPlaylistEvent(
                                          playlistId: playlistId,
                                          songId: song.id,
                                        ));
                                      },
                                    ),
                                    MetaIconCircularButton(
                                      icon: isPlayingThis && state.playerState == AudioPlayerState.playing
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 32,
                                      iconColor: isPlayingThis ? AppColors.canvas : AppColors.inkDeep,
                                      backgroundColor: isPlayingThis ? AppColors.primary : AppColors.surfaceSoft,
                                      onPressed: () {
                                        if (isPlayingThis) {
                                          if (state.playerState == AudioPlayerState.playing) {
                                            context.read<PlayerBloc>().add(PauseSongEvent());
                                          } else {
                                            context.read<PlayerBloc>().add(ResumeSongEvent());
                                          }
                                        } else {
                                          context.read<PlayerBloc>().add(PlaySongEvent(
                                            song: song,
                                            queue: songs,
                                          ));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String playlistName) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.hairlineSoft, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add_check_rounded, size: 64, color: AppColors.stone),
            const SizedBox(height: 16),
            Text(
              context.tr('playlist_empty'),
              style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('playlist_empty_desc', args: {'name': playlistName}),
              style: AppTypography.bodySm.copyWith(color: AppColors.charcoal, height: 1.45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
