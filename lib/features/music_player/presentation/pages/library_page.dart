import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/service/audio_player_service.dart';
import '../../../../core/localization/localization_extension.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/player_bloc.dart';
import '../widgets/meta_components.dart';
import 'playlist_detail_page.dart';
import '../../domain/entities/song.dart';

class LibraryPage extends StatelessWidget {
  final VoidCallback onNavigateToDiscover;

  const LibraryPage({super.key, required this.onNavigateToDiscover});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          title: Text(
            context.tr('library'),
            style: AppTypography.headingSm.copyWith(fontWeight: FontWeight.w700),
          ),
          centerTitle: false,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.charcoal,
            labelStyle: AppTypography.bodySmBold,
            unselectedLabelStyle: AppTypography.bodySm,
            tabs: [
              Tab(text: context.tr('favorites').toUpperCase()),
              Tab(text: context.tr('my_playlists').toUpperCase()),
              Tab(text: context.tr('downloads').toUpperCase()),
            ],
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            // Tab 1: Favorites
            BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, catalogState) {
                final favoriteSongs = catalogState.allSongs.where((s) => s.isFavorite).toList();
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: favoriteSongs.isEmpty
                        ? _buildEmptyState(context)
                        : _buildFavoritesList(context, favoriteSongs),
                  ),
                );
              },
            ),
            // Tab 2: Custom Playlists
            BlocBuilder<PlayerBloc, PlayerState>(
              builder: (context, playerState) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: _buildPlaylistsTab(context, playerState),
                  ),
                );
              },
            ),
            // Tab 3: Downloads (Offline)
            BlocBuilder<PlayerBloc, PlayerState>(
              builder: (context, playerState) {
                final downloadedSongs = playerState.downloadedSongs;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: downloadedSongs.isEmpty
                        ? _buildEmptyOfflineState(context)
                        : _buildOfflineSongsList(context, downloadedSongs),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistsTab(BuildContext context, PlayerState playerState) {
    final playlists = playerState.customPlaylists;
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;

    return Column(
      children: [
        // Create Playlist Banner/Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingVal, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${context.tr('my_playlists')} (${playlists.length})',
                style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showCreatePlaylistDialog(context),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          context.tr('create_new'),
                          style: AppTypography.bodySmBold.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showMoodPlaylistDialog(context),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'AI Playlist',
                          style: AppTypography.bodySmBold.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Playlists List
        Expanded(
          child: playlists.isEmpty
              ? _buildEmptyPlaylistsState(context)
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: paddingVal),
                  physics: const BouncingScrollPhysics(),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: AppColors.canvas,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.hairlineSoft, width: 1.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: playlist.songs.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      playlist.songs.first.coverUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(Icons.playlist_play_rounded, color: AppColors.primary, size: 28),
                          ),
                          title: Text(
                            playlist.name,
                            style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
                          ),
                          subtitle: Text(
                            context.tr('songs_count', args: {'count': '${playlist.songs.length}'}),
                            style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.critical, size: 20),
                                onPressed: () {
                                  _showDeletePlaylistConfirm(context, playlist.id, playlist.name);
                                },
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppColors.stone),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailPage(playlistId: playlist.id),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyPlaylistsState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.hairlineSoft, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_music_rounded, size: 64, color: AppColors.stone),
            const SizedBox(height: 16),
            Text(
              context.tr('no_playlists'),
              style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('no_playlists_desc'),
              style: AppTypography.bodySm.copyWith(color: AppColors.charcoal, height: 1.45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            MetaButton(
              label: context.tr('create_playlist'),
              type: MetaButtonType.primary,
              onPressed: () => _showCreatePlaylistDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.canvas,
          title: Text(context.tr('create_playlist'), style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep)),
          content: TextField(
            controller: controller,
            style: AppTypography.bodySm.copyWith(color: AppColors.inkDeep),
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.tr('playlist_name_hint'),
              hintStyle: TextStyle(color: AppColors.stone),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.hairline)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel').toUpperCase(), style: TextStyle(color: AppColors.charcoal)),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  context.read<PlayerBloc>().add(CreatePlaylistEvent(name));
                }
                Navigator.pop(dialogContext);
              },
              child: Text(context.tr('create'), style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePlaylistConfirm(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.canvas,
          title: Text(context.tr('delete_playlist_title'), style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep)),
          content: Text(
            context.tr('delete_playlist_confirm', args: {'name': name}),
            style: AppTypography.bodySm.copyWith(color: AppColors.charcoal),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel').toUpperCase(), style: TextStyle(color: AppColors.charcoal)),
            ),
            TextButton(
              onPressed: () {
                context.read<PlayerBloc>().add(DeletePlaylistEvent(id));
                Navigator.pop(dialogContext);
              },
              child: Text(context.tr('delete').toUpperCase(), style: const TextStyle(color: AppColors.critical)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingVal),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.hairlineSoft, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: AppColors.stone,
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('no_favorite_songs'),
                style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('no_favorite_songs_desc'),
                style: AppTypography.bodySm.copyWith(color: AppColors.charcoal, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              MetaButton(
                label: context.tr('explore_songs'),
                type: MetaButtonType.primary,
                onPressed: onNavigateToDiscover,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, List<dynamic> songs) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) {
        return previous.currentSong?.id != current.currentSong?.id ||
            previous.playerState != current.playerState;
      },
      builder: (context, playerState) {
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: paddingVal, vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final isPlayingThis = playerState.currentSong?.id == song.id;

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
                  // Cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song.coverUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.steel,
                        child: const Icon(Icons.music_note, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                song.title,
                                style: AppTypography.bodyMdBold.copyWith(
                                  color: isPlayingThis ? AppColors.primaryDeep : AppColors.inkDeep,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (song.format.contains('Lossless')) ...[
                              const SizedBox(width: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Text(
                                  'HI-FI',
                                  style: AppTypography.captionBold.copyWith(fontSize: 9, color: AppColors.inkDeep),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: AppTypography.bodySm.copyWith(color: AppColors.charcoal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Duration
                  Text(
                    song.duration,
                    style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                  ),
                  const SizedBox(width: 12),

                  // Favorite action
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      song.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: song.isFavorite ? AppColors.criticalStrong : AppColors.steel,
                      size: 20,
                    ),
                    onPressed: () {
                      context.read<PlayerBloc>().add(ToggleFavoriteSongIdEvent(song.id));
                      context.read<CatalogBloc>().add(ToggleCatalogFavoriteEvent(song.id));
                    },
                  ),

                  // Play Button
                  MetaIconCircularButton(
                    icon: isPlayingThis && playerState.playerState == AudioPlayerState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 36,
                    iconColor: isPlayingThis ? AppColors.canvas : AppColors.inkDeep,
                    backgroundColor: isPlayingThis ? AppColors.primary : AppColors.surfaceSoft,
                    onPressed: () {
                      if (isPlayingThis) {
                        if (playerState.playerState == AudioPlayerState.playing) {
                          context.read<PlayerBloc>().add(PauseSongEvent());
                        } else {
                          context.read<PlayerBloc>().add(ResumeSongEvent());
                        }
                      } else {
                        context.read<PlayerBloc>().add(PlaySongEvent(
                              song: song,
                              queue: songs.cast(),
                            ));
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMoodPlaylistDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return BlocConsumer<PlayerBloc, PlayerState>(
          listener: (context, state) {
            if (!state.isGeneratingMoodPlaylist) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('ai_playlist_success', args: {'name': 'AI: ${controller.text.trim()}'}, listen: false)),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          builder: (context, state) {
            final isGenerating = state.isGeneratingMoodPlaylist;

            return AlertDialog(
              backgroundColor: AppColors.canvas,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('ai_playlist_title'),
                    style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep),
                  ),
                ],
              ),
              content: isGenerating
                  ? SizedBox(
                      height: 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('ai_playlist_generating'),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm.copyWith(color: AppColors.charcoal),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('ai_playlist_prompt'),
                          style: AppTypography.bodySmBold.copyWith(color: AppColors.charcoal),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: controller,
                          maxLines: 2,
                          style: AppTypography.bodySm.copyWith(color: AppColors.inkDeep),
                          decoration: InputDecoration(
                            hintText: context.tr('ai_playlist_placeholder'),
                            hintStyle: TextStyle(color: AppColors.stone),
                            filled: true,
                            fillColor: AppColors.surfaceSoft,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.hairlineSoft),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
              actions: isGenerating
                  ? null
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          context.tr('cancel').toUpperCase(),
                          style: TextStyle(color: AppColors.charcoal),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final mood = controller.text.trim();
                          if (mood.isNotEmpty) {
                            if (state.geminiApiKey.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('ai_playlist_error', listen: false)),
                                  backgroundColor: AppColors.critical,
                                ),
                              );
                              return;
                            }
                            context.read<PlayerBloc>().add(GenerateMoodPlaylistEvent(mood));
                          }
                        },
                        child: Text(
                          context.tr('create').toUpperCase(),
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyOfflineState(BuildContext context) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingVal),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.hairlineSoft, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.download_for_offline_rounded,
                size: 64,
                color: AppColors.stone,
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('downloads'),
                style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('feature_offline_desc'),
                style: AppTypography.bodySm.copyWith(color: AppColors.charcoal, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              MetaButton(
                label: context.tr('explore_songs'),
                type: MetaButtonType.primary,
                onPressed: onNavigateToDiscover,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineSongsList(BuildContext context, List<Song> songs) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) {
        return previous.currentSong?.id != current.currentSong?.id ||
            previous.playerState != current.playerState;
      },
      builder: (context, playerState) {
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: paddingVal, vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final isPlayingThis = playerState.currentSong?.id == song.id;

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
                  // Cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song.coverUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.steel,
                        child: const Icon(Icons.music_note, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                song.title,
                                style: AppTypography.bodyMdBold.copyWith(
                                  color: isPlayingThis ? AppColors.primaryDeep : AppColors.inkDeep,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FFCC).withAlpha(40),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                'OFFLINE',
                                style: AppTypography.captionBold.copyWith(fontSize: 8, color: const Color(0xFF00FFCC)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: AppTypography.bodySm.copyWith(color: AppColors.charcoal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Delete offline button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.critical,
                      size: 20,
                    ),
                    onPressed: () {
                      _showDeleteOfflineSongConfirm(context, song.id, song.title);
                    },
                  ),
                  const SizedBox(width: 12),

                  // Play Button
                  MetaIconCircularButton(
                    icon: isPlayingThis && playerState.playerState == AudioPlayerState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 36,
                    iconColor: isPlayingThis ? AppColors.canvas : AppColors.inkDeep,
                    backgroundColor: isPlayingThis ? AppColors.primary : AppColors.surfaceSoft,
                    onPressed: () {
                      if (isPlayingThis) {
                        if (playerState.playerState == AudioPlayerState.playing) {
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
        );
      },
    );
  }

  void _showDeleteOfflineSongConfirm(BuildContext context, String songId, String songTitle) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.canvas,
          title: Text(context.tr('delete_download'), style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep)),
          content: Text(
            context.tr('delete_download_confirm'),
            style: AppTypography.bodySm.copyWith(color: AppColors.charcoal),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel').toUpperCase(), style: TextStyle(color: AppColors.charcoal)),
            ),
            TextButton(
              onPressed: () {
                context.read<PlayerBloc>().add(DeleteDownloadedSongEvent(songId));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('delete_download_success', args: {'title': songTitle})),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(context.tr('delete').toUpperCase(), style: const TextStyle(color: AppColors.critical)),
            ),
          ],
        );
      },
    );
  }
}
