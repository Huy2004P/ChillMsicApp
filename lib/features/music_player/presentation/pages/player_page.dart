import 'dart:ui' show ImageFilter;
import 'dart:ui' as ui show Image, ImageByteFormat;
import 'dart:io' show File;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/service/audio_player_service.dart';
import '../../domain/entities/song.dart';
import '../bloc/player_bloc.dart';
import '../bloc/catalog_bloc.dart';
import '../widgets/meta_components.dart';
import '../widgets/eq_curve_editor.dart';
import '../widgets/queue_drawer.dart';
import '../widgets/audio_spectrum_visualizer.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) {
        return previous.currentSong != current.currentSong ||
               previous.isDarkMode != current.isDarkMode ||
               previous.playerState != current.playerState ||
               previous.audioQuality != current.audioQuality ||
               previous.shuffleEnabled != current.shuffleEnabled ||
               previous.repeatMode != current.repeatMode ||
               previous.spatialAudioMode != current.spatialAudioMode ||
               previous.headphoneProfile != current.headphoneProfile ||
               previous.eqPresetName != current.eqPresetName;
      },
      builder: (context, state) {
        final song = state.currentSong;
        if (song == null) {
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: AppBar(backgroundColor: AppColors.canvas, elevation: 0),
            body: Center(
              child: Text(
                'Chưa chọn bài hát nào',
                style: AppTypography.bodyMd,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: Stack(
            children: [
              // Background blurred album art wrapped in RepaintBoundary to cache the heavy blur filter
              Positioned.fill(
                child: RepaintBoundary(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          song.coverUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Blur filter overlay with dynamic canvas tint
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                          child: Container(
                            color: AppColors.canvas.withAlpha(state.isDarkMode ? 153 : 179),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: LayoutBuilder(
                  builder: (layoutContext, constraints) {
                    final isDesktop = constraints.maxWidth >= 768;
                    
                    if (isDesktop) {
                      return _buildDesktopLayout(context, state, song);
                    } else {
                      return _buildMobileLayout(context, state, song);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Layout Builders ---

  Widget _buildDesktopLayout(BuildContext context, PlayerState state, Song song) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Desktop Header Breadcrumb
              _buildBreadcrumb(context, state, song),
              const SizedBox(height: 16),
              
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Album Art or Lyrics (58% width)
                    Expanded(
                      flex: 58,
                      child: Column(
                        children: [
                          Expanded(
                            child: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 300),
                        crossFadeState: _showLyrics ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        firstChild: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showLyrics = true;
                            });
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32), // {rounded.xxxl}
                                  image: DecorationImage(
                                    image: NetworkImage(song.coverUrl),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(color: AppColors.hairlineSoft.withAlpha(120), width: 1),
                                ),
                              ),
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(150),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.music_note_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'LỜI BÀI HÁT',
                                        style: AppTypography.captionBold.copyWith(color: Colors.white, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        secondChild: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: AppColors.hairlineSoft.withAlpha(120), width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.network(
                                    song.coverUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      color: AppColors.canvas.withAlpha(state.isDarkMode ? 160 : 185),
                                    ),
                                  ),
                                ),
                                LyricsView(
                                  song: song,
                                  duration: state.duration,
                                  isDarkMode: state.isDarkMode,
                                  onBackToCover: () {
                                    setState(() {
                                      _showLyrics = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                key: bottomChildKey,
                                left: 0,
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: bottomChild,
                              ),
                              Positioned(
                                key: topChildKey,
                                left: 0,
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: topChild,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                          const SizedBox(height: 16),
                          const RepaintBoundary(
                            child: AudioSpectrumVisualizer(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    
                    // Right Column: Sticky controls rail (42% width, max-width: 380px)
                    Expanded(
                      flex: 42,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStickySummaryCard(context, state, song),
                              const SizedBox(height: 20),
                              _buildAudiophileDashboard(context, state),
                              const SizedBox(height: 20),
                              _buildAudioQualitySelector(context, state),
                              const SizedBox(height: 20),
                              _buildTechnicalSpecs(song),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, PlayerState state, Song song) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: paddingVal, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MetaIconCircularButton(
                icon: Icons.keyboard_arrow_left,
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'ĐANG PHÁT',
                style: AppTypography.bodySmBold.copyWith(letterSpacing: 1.5, color: AppColors.slate),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MetaIconCircularButton(
                    icon: Icons.playlist_add_rounded,
                    onPressed: () {
                      _showAddToPlaylistBottomSheet(context, song);
                    },
                  ),
                  const SizedBox(width: 8),
                  MetaIconCircularButton(
                    icon: Icons.queue_music_rounded,
                    onPressed: () {
                      _showQueueBottomSheet(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  MetaIconCircularButton(
                    icon: song.isFavorite ? Icons.favorite : Icons.favorite_border,
                    iconColor: song.isFavorite ? AppColors.criticalStrong : AppColors.steel,
                    onPressed: () {
                      context.read<PlayerBloc>().add(ToggleFavoriteCurrentSongEvent());
                      context.read<CatalogBloc>().add(ToggleCatalogFavoriteEvent(song.id));
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDownloadButton(context, state, song),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Album Art or Lyrics Center Row
          Center(
            child: AspectRatio(
              aspectRatio: 1 / 1,
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showLyrics ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showLyrics = true;
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32), // {rounded.xxxl}
                          image: DecorationImage(
                            image: NetworkImage(song.coverUrl),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: AppColors.hairlineSoft.withAlpha(120), width: 1),
                        ),
                      ),
                      // Corner Lyric Label Overlay
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(150),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.music_note_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'LỜI BÀI HÁT',
                                style: AppTypography.captionBold.copyWith(color: Colors.white, fontSize: 8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                secondChild: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.hairlineSoft.withAlpha(120), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            song.coverUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              color: AppColors.canvas.withAlpha(state.isDarkMode ? 160 : 185),
                            ),
                          ),
                        ),
                        LyricsView(
                          song: song,
                          duration: state.duration,
                          isDarkMode: state.isDarkMode,
                          onBackToCover: () {
                            setState(() {
                              _showLyrics = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        key: bottomChildKey,
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: bottomChild,
                      ),
                      Positioned(
                        key: topChildKey,
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: topChild,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Audiophile telemetry board
          _buildAudiophileDashboard(context, state),
          const SizedBox(height: 16),
          
          // Mobile Controls Panel
          _buildStickySummaryCard(context, state, song),
          const SizedBox(height: 20),
          
          // Audio Quality
          _buildAudioQualitySelector(context, state),
          const SizedBox(height: 20),
          
          // Technical Specifications
          _buildTechnicalSpecs(song),
          const SizedBox(height: 16),
          // Dynamic Neon Audio Visualizer (isolated repaint boundary)
          const RepaintBoundary(
            child: AudioSpectrumVisualizer(),
          ),
        ],
      ),
    );
  }

  // --- Sub-widgets ---

  Widget _buildDownloadButton(BuildContext context, PlayerState state, Song song) {
    final isDownloading = state.downloadingSongIds.contains(song.id);
    final isDownloaded = state.downloadedSongs.any((s) => s.id == song.id);

    if (isDownloading) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FFCC)),
          ),
        ),
      );
    }

    return MetaIconCircularButton(
      icon: isDownloaded ? Icons.download_done_rounded : Icons.download_for_offline_outlined,
      iconColor: isDownloaded ? const Color(0xFF00FFCC) : AppColors.steel,
      onPressed: () {
        if (isDownloaded) {
          _showDeleteDownloadConfirm(context, song);
        } else {
          context.read<PlayerBloc>().add(DownloadSongEvent(song));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('download_started', args: {'title': song.title})),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  void _showDeleteDownloadConfirm(BuildContext context, Song song) {
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
                context.read<PlayerBloc>().add(DeleteDownloadedSongEvent(song.id));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('delete_download_success', args: {'title': song.title})),
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

  Widget _buildBreadcrumb(BuildContext context, PlayerState state, Song song) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text('ChillMsic', style: AppTypography.bodySm.copyWith(color: AppColors.steel)),
        ),
        Text('  ›  ', style: AppTypography.bodySm.copyWith(color: AppColors.stone)),
        Text('Danh sách phát', style: AppTypography.bodySm.copyWith(color: AppColors.steel)),
        Text('  ›  ', style: AppTypography.bodySm.copyWith(color: AppColors.stone)),
        Expanded(
          child: Text(
            song.title,
            style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        MetaIconCircularButton(
          icon: Icons.playlist_add_rounded,
          onPressed: () {
            _showAddToPlaylistBottomSheet(context, song);
          },
        ),
        const SizedBox(width: 8),
        MetaIconCircularButton(
          icon: Icons.queue_music_rounded,
          onPressed: () {
            _showQueueBottomSheet(context);
          },
        ),
        const SizedBox(width: 8),
        _buildDownloadButton(context, state, song),
      ],
    );
  }

  void _showQueueBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return const QueueDrawer();
      },
    );
  }

  void _showAddToPlaylistBottomSheet(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocBuilder<PlayerBloc, PlayerState>(
          builder: (context, state) {
            final playlists = state.customPlaylists;
            return Container(
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thêm vào Danh sách phát',
                    style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep),
                  ),
                  const SizedBox(height: 12),
                  if (playlists.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Chưa có danh sách phát nào.\nHãy tạo danh sách phát mới tại Thư viện.',
                          style: AppTypography.bodySm.copyWith(color: AppColors.charcoal),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ] else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          final bool containsSong = playlist.songs.any((s) => s.id == song.id);

                          return ListTile(
                            leading: Icon(
                              Icons.playlist_play_rounded,
                              color: containsSong ? AppColors.primary : AppColors.steel,
                            ),
                            title: Text(
                              playlist.name,
                              style: AppTypography.bodySmBold.copyWith(
                                color: containsSong ? AppColors.primaryDeep : AppColors.inkDeep,
                              ),
                            ),
                            subtitle: Text('${playlist.songs.length} bài hát', style: AppTypography.caption),
                            trailing: containsSong
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                                : null,
                            onTap: () {
                              context.read<PlayerBloc>().add(AddSongToPlaylistEvent(
                                    playlistId: playlist.id,
                                    song: song,
                                  ));
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    containsSong
                                        ? 'Bài hát đã có trong "${playlist.name}"'
                                        : 'Đã thêm vào "${playlist.name}"',
                                  ),
                                  backgroundColor: containsSong ? AppColors.attention : AppColors.success,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStickySummaryCard(BuildContext context, PlayerState state, Song song) {
    final isPlaying = state.playerState == AudioPlayerState.playing;
    final isBuffering = state.playerState == AudioPlayerState.buffering;

    // Formatting durations to MM:SS
    String formatDuration(Duration d) {
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }


    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas.withAlpha(state.isDarkMode ? 89 : 166),
        borderRadius: BorderRadius.circular(16), // {rounded.xl}
        border: Border.all(color: AppColors.hairlineSoft.withAlpha(128), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F14161A), // rgba(20, 22, 26, 0.06)
            offset: Offset(0, 1),
            blurRadius: 4,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: AppTypography.subtitleLg.copyWith(fontSize: 22, color: AppColors.inkDeep),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: AppTypography.bodyMd.copyWith(color: AppColors.charcoal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(100), // {rounded.full}
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  'CHẤT LƯỢNG HIFI',
                  style: AppTypography.captionBold.copyWith(color: AppColors.canvas, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress slider wrapped in BlocBuilder for high-frequency position ticks
          RepaintBoundary(
            child: BlocBuilder<PlayerBloc, PlayerState>(
              buildWhen: (prev, curr) => prev.position != curr.position || prev.duration != curr.duration,
              builder: (context, sliderState) {
                final double sliderValue = sliderState.duration.inSeconds > 0
                    ? sliderState.position.inSeconds / sliderState.duration.inSeconds
                    : 0.0;
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.hairlineSoft,
                      thumbColor: AppColors.primary,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: sliderValue.clamp(0.0, 1.0),
                      onChanged: (val) {
                        final newPos = Duration(seconds: (val * sliderState.duration.inSeconds).toInt());
                        context.read<PlayerBloc>().add(SeekSongEvent(newPos));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDuration(sliderState.position),
                          style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                        ),
                        Text(
                          formatDuration(sliderState.duration),
                          style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),

          // Playback mode selectors (Shuffle and Repeat)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Shuffle Button
                GestureDetector(
                  onTap: () {
                    context.read<PlayerBloc>().add(ToggleShuffleEvent());
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: state.shuffleEnabled ? AppColors.primarySoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shuffle,
                          size: 16,
                          color: state.shuffleEnabled ? AppColors.primary : const Color(0xFF8D99AE),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.shuffleEnabled ? 'XÁO TRỘN: BẬT' : 'PHÁT TUẦN TỰ',
                          style: AppTypography.captionBold.copyWith(
                            color: state.shuffleEnabled ? AppColors.primary : const Color(0xFF8D99AE),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Repeat Button
                GestureDetector(
                  onTap: () {
                    context.read<PlayerBloc>().add(ToggleRepeatModeEvent());
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: state.repeatMode != 'off' ? AppColors.primarySoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          state.repeatMode == 'one' ? Icons.repeat_one : Icons.repeat,
                          size: 16,
                          color: state.repeatMode != 'off' ? AppColors.primary : const Color(0xFF8D99AE),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.repeatMode == 'one'
                              ? 'LẶP 1 BÀI'
                              : (state.repeatMode == 'all' ? 'LẶP DANH SÁCH' : 'KHÔNG LẶP'),
                          style: AppTypography.captionBold.copyWith(
                            color: state.repeatMode != 'off' ? AppColors.primary : const Color(0xFF8D99AE),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Main playback controllers
          Builder(
            builder: (context) {
              final double screenWidth = MediaQuery.of(context).size.width;
              final double buttonGap = screenWidth < 360 ? 8 : 16;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Equalizer bottom sheet trigger
                  MetaIconCircularButton(
                    icon: Icons.tune_rounded,
                    onPressed: () {
                      _showEqualizerBottomSheet(context);
                    },
                  ),
                  SizedBox(width: buttonGap),

                  MetaIconCircularButton(
                    icon: Icons.skip_previous,
                    onPressed: () {
                      context.read<PlayerBloc>().add(SkipPreviousEvent());
                    },
                  ),
                  SizedBox(width: buttonGap),
                  
                  // Premium Circular Play/Pause Button
                  isBuffering
                      ? SizedBox(
                          width: 56,
                          height: 56,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            if (isPlaying) {
                              context.read<PlayerBloc>().add(PauseSongEvent());
                            } else {
                              context.read<PlayerBloc>().add(ResumeSongEvent());
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x400054FF),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                  
                  SizedBox(width: buttonGap),
                  MetaIconCircularButton(
                    icon: Icons.skip_next,
                    onPressed: () {
                      context.read<PlayerBloc>().add(SkipNextEvent());
                    },
                  ),
                  SizedBox(width: buttonGap),

                  // Spatial Audio toggle shortcut
                  MetaIconCircularButton(
                    icon: Icons.surround_sound_rounded,
                    onPressed: () {
                      final modes = [
                        'Tắt (Stereo gốc)',
                        'Phòng thu tiêu chuẩn (Studio)',
                        'Sân khấu trực tiếp (Live Stage)',
                        'Rạp hát vòm (Cinematic Surround)',
                      ];
                      final currentIdx = modes.indexOf(state.spatialAudioMode);
                      final nextIdx = (currentIdx + 1) % modes.length;
                      context.read<PlayerBloc>().add(UpdateSpatialAudioModeEvent(modes[nextIdx]));
                      
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chế độ âm thanh: ${modes[nextIdx]}'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAudioQualitySelector(BuildContext context, PlayerState state) {
    final options = [
      {
        'title': 'Âm thanh Lossless (24-bit/192kHz)',
        'subtitle': 'Độ phân giải phòng thu. Âm học cực chân thực.',
        'label': '24-BIT',
      },
      {
        'title': 'Chất lượng cao (320kbps)',
        'subtitle': 'Nén MP3 tiêu chuẩn. Tiết kiệm dữ liệu.',
        'label': '320 KBPS',
      },
      {
        'title': 'Chất lượng tiêu chuẩn (128kbps)',
        'subtitle': 'Nén mạnh. Dành cho mạng yếu.',
        'label': '128 KBPS',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn Chất Lượng Âm Thanh',
          style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep),
        ),
        const SizedBox(height: 16),
        ...options.map((opt) {
          final title = opt['title']!;
          final isSelected = state.audioQuality == title;
          return RadioOptionWidget(
            title: title,
            subtitle: opt['subtitle']!,
            trailingLabel: opt['label']!,
            isSelected: isSelected,
            onTap: () {
              context.read<PlayerBloc>().add(ChangeAudioQualityEvent(title));
            },
          );
        }),
      ],
    );
  }

  Widget _buildTechnicalSpecs(Song song) {
    final specs = {
      'Định dạng Âm thanh': song.format,
      'Tốc độ Bit tối đa': song.bitrate,
      'Tần số lấy mẫu': song.sampleRate,
      'Ngày phát hành': song.releaseDate,
      'Nhạc sĩ': song.composer,
      'Bản quyền': song.copyright,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông số Kỹ thuật',
          style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep),
        ),
        const SizedBox(height: 8),
        SpecsTable(specs: specs),
      ],
    );
  }



  Widget _buildAudiophileDashboard(BuildContext context, PlayerState state) {
    // Determine active DAC specs based on quality
    String dacSpec = '44.1 kHz / 16-bit';
    if (state.audioQuality.contains('24-bit')) {
      dacSpec = '192.0 kHz / 24-bit';
    } else if (state.audioQuality.contains('320')) {
      dacSpec = '48.0 kHz / 16-bit';
    }

    // Determine Gain specs based on headphone profile
    String gainSpec = '0 dB (Low)';
    if (state.headphoneProfile.contains('32Ω')) {
      gainSpec = '+3 dB (Mid)';
    } else if (state.headphoneProfile.contains('250Ω')) {
      gainSpec = '+9 dB (High)';
    }

    final isPlaying = state.playerState == AudioPlayerState.playing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xDD0A1317), // Slightly translucent dark background to blend with backdrop blur
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(51), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPlaying ? const Color(0xFF00FF66) : const Color(0xFF8D99AE),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GIÁM SÁT ÂM THANH HI-RES',
                    style: AppTypography.captionBold.copyWith(
                      color: isPlaying ? const Color(0xFF00FF66) : const Color(0xFF8D99AE),
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              BlocBuilder<PlayerBloc, PlayerState>(
                buildWhen: (prev, curr) => prev.sleepTimerRemaining != curr.sleepTimerRemaining,
                builder: (context, timerState) {
                  final remaining = timerState.sleepTimerRemaining;
                  if (remaining != null) {
                    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
                    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, color: AppColors.primary, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          'HẸN GIỜ: $minutes:$seconds',
                          style: AppTypography.captionBold.copyWith(
                            color: AppColors.primary,
                            fontSize: 9,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    );
                  }
                  return Text(
                    'DSP ACTIVE',
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.primary,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: BlocBuilder<PlayerBloc, PlayerState>(
                  buildWhen: (prev, curr) => prev.currentBitrate != curr.currentBitrate || prev.playerState != curr.playerState,
                  builder: (context, dbState) {
                    return _buildDashboardItem(
                      'TỐC ĐỘ BIT',
                      dbState.playerState == AudioPlayerState.playing
                          ? '${dbState.currentBitrate} kbps'
                          : '-- kbps',
                      Colors.white,
                    );
                  },
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white.withAlpha(26)),
              Expanded(
                flex: 6,
                child: _buildDashboardItem(
                  'BỘ GIẢI MÃ DAC',
                  dacSpec,
                  AppColors.warning,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Divider(color: Colors.white.withAlpha(26), height: 1),
          ),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _buildDashboardItem(
                  'ĐỘ LỢI ĐẦU RA',
                  gainSpec,
                  const Color(0xFF00FF99),
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white.withAlpha(26)),
              Expanded(
                flex: 6,
                child: GestureDetector(
                  onTap: () {
                    final modes = [
                      'Tắt (Stereo gốc)',
                      'Phòng thu tiêu chuẩn (Studio)',
                      'Sân khấu trực tiếp (Live Stage)',
                      'Rạp hát vòm (Cinematic Surround)',
                    ];
                    final currentIdx = modes.indexOf(state.spatialAudioMode);
                    final nextIdx = (currentIdx + 1) % modes.length;
                    context.read<PlayerBloc>().add(UpdateSpatialAudioModeEvent(modes[nextIdx]));
                    
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chế độ âm thanh: ${modes[nextIdx]}'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: _buildDashboardItem(
                    'ÂM THANH 3D (CHẠM ĐỔI)',
                    state.spatialAudioMode.split(' (')[0],
                    AppColors.fbBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(String title, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.captionBold.copyWith(
              color: const Color(0xFF8D99AE),
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodySmBold.copyWith(
              color: valueColor,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showEqualizerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return BlocBuilder<PlayerBloc, PlayerState>(
          buildWhen: (prev, curr) =>
              prev.eqPresetName != curr.eqPresetName ||
              prev.eqBands != curr.eqBands ||
              prev.isDarkMode != curr.isDarkMode,
          builder: (context, state) {
            final eqOptions = [
              'Mặc định',
              'Acoustic',
              'Pop',
              'EDM',
              'Lofi Thư giãn',
              'Tăng Bass (Bass Boost)',
            ];

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.canvas.withAlpha(state.isDarkMode ? 200 : 230),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(
                      color: AppColors.hairlineSoft.withAlpha(state.isDarkMode ? 80 : 30),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.hairline.withAlpha(150),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BỘ CHỈNH ÂM',
                                style: AppTypography.headingSm.copyWith(
                                  color: AppColors.inkDeep,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Parametric DSP Equalizer',
                                style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Text(
                              state.eqPresetName,
                              style: AppTypography.captionBold.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Interactive Bezier EQ Curve Editor container with glass glow
                      Container(
                        height: 180,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: state.isDarkMode
                                ? [const Color(0x1F172033), const Color(0x0D172033)]
                                : [const Color(0x33F2F4F8), const Color(0x11F2F4F8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(state.isDarkMode ? 40 : 20),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(state.isDarkMode ? 15 : 5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: EqCurveEditor(
                          bands: state.eqBands,
                          onBandChanged: (band, value) {
                            context.read<PlayerBloc>().add(UpdateEqBandEvent(
                                  band: band,
                                  value: value,
                                ));
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Bộ lập sẵn (Presets)',
                        style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: eqOptions.length,
                          itemBuilder: (context, index) {
                            final preset = eqOptions[index];
                            final isSelected = state.eqPresetName == preset;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(preset),
                                selected: isSelected,
                                onSelected: (_) {
                                  context.read<PlayerBloc>().add(SelectEqPresetEvent(preset));
                                },
                                labelStyle: AppTypography.captionBold.copyWith(
                                  color: isSelected ? Colors.white : AppColors.charcoal,
                                ),
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.surfaceSoft.withAlpha(120),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : AppColors.hairlineSoft.withAlpha(100),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                showCheckmark: false,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Modern 5-Band Level Grid Dashboard
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: state.isDarkMode ? const Color(0x0F000000) : const Color(0x0A000000),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.hairlineSoft.withAlpha(60), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đặc tả Tần số',
                                  style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
                                ),
                                Text(
                                  'LIVE MONITOR',
                                  style: AppTypography.captionBold.copyWith(color: AppColors.primary, fontSize: 9),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            EqBandLevelMeter(
                              bands: state.eqBands,
                              isDarkMode: state.isDarkMode,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class LyricsView extends StatefulWidget {
  final Song song;
  final Duration duration;
  final bool isDarkMode;
  final VoidCallback onBackToCover;

  const LyricsView({
    super.key,
    required this.song,
    required this.duration,
    required this.isDarkMode,
    required this.onBackToCover,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  List<LyricLine> _lyricLines = [];
  List<LyricLine> _translatedLyricLines = [];
  String _translatedRaw = '';
  final Set<int> _selectedIndices = {};
  final GlobalKey _cardBoundaryKey = GlobalKey();
  int _activeIndex = -1;
  bool _showTranslation = false;

  @override
  void initState() {
    super.initState();
    _parseLyrics();
    final state = context.read<PlayerBloc>().state;
    _updateActiveIndex(state.position + Duration(milliseconds: state.lyricDelayMs));
    if (state.translatedLyrics.isNotEmpty) {
      _translatedRaw = state.translatedLyrics;
      _parseTranslatedLyrics(state.translatedLyrics);
    }
  }

  @override
  void didUpdateWidget(covariant LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.lyrics != widget.song.lyrics ||
        oldWidget.duration != widget.duration) {
      _parseLyrics();
      final state = context.read<PlayerBloc>().state;
      _updateActiveIndex(state.position + Duration(milliseconds: state.lyricDelayMs));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _parseLyrics() {
    final rawLyrics = widget.song.lyrics;
    final lines = rawLyrics.split('\n');
    final List<LyricLine> parsed = [];

    // RegExp to match LRC timestamps, e.g. [01:23.45] or [01:23]
    final regExp = RegExp(r'^\[(\d+):(\d+)(?:\.(\d+))?\](.*)$');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Skip LRC metadata tags like [ti: Song Title], [ar: Artist], etc.
      if (trimmed.startsWith('[') && !trimmed.startsWith(RegExp(r'\[\d'))) {
        continue;
      }

      final match = regExp.firstMatch(trimmed);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3) ?? '00';
        final ms = int.parse(msStr.padRight(3, '0').substring(0, 3));
        final text = match.group(4)!.trim();

        final time = Duration(minutes: min, seconds: sec, milliseconds: ms);
        parsed.add(LyricLine(time, text));
      } else {
        // Line without timestamp, check if we want to fallback
        parsed.add(LyricLine(Duration.zero, trimmed));
      }
    }

    // Check if lyrics are plain text (i.e. all times are zero)
    final allZero = parsed.every((l) => l.time == Duration.zero);
    if (allZero && parsed.isNotEmpty && widget.duration.inSeconds > 0) {
      // Distribute plain text lyrics intelligently over duration
      final double totalDurationSec = widget.duration.inSeconds.toDouble();
      final double introSec = (totalDurationSec * 0.08).clamp(6.0, 18.0);
      final double remainingSec = totalDurationSec - introSec;
      
      double lineSec = remainingSec / (parsed.length + 2);
      lineSec = lineSec.clamp(4.0, 10.0); // Keep highlighting duration readable

      final int maxSeconds = widget.duration.inSeconds > 0 ? widget.duration.inSeconds - 1 : 0;

      _lyricLines = List.generate(parsed.length, (i) {
        final double timeInSeconds = (introSec + (i * lineSec)).clamp(0.0, maxSeconds.toDouble());
        return LyricLine(
          Duration(milliseconds: (timeInSeconds * 1000).toInt()),
          parsed[i].text,
        );
      });
    } else {
      _lyricLines = parsed;
    }
  }

  void _parseTranslatedLyrics(String rawTranslation) {
    if (rawTranslation.isEmpty || rawTranslation.startsWith('Error:')) {
      _translatedLyricLines = [];
      return;
    }
    final lines = rawTranslation.split('\n');
    final List<LyricLine> parsed = [];
    final regExp = RegExp(r'^\[(\d+):(\d+)(?:\.(\d+))?\](.*)$');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('[') && !trimmed.startsWith(RegExp(r'\[\d'))) {
        continue;
      }

      final match = regExp.firstMatch(trimmed);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3) ?? '00';
        final ms = int.parse(msStr.padRight(3, '0').substring(0, 3));
        final text = match.group(4)!.trim();

        final time = Duration(minutes: min, seconds: sec, milliseconds: ms);
        parsed.add(LyricLine(time, text));
      } else {
        parsed.add(LyricLine(Duration.zero, trimmed));
      }
    }
    _translatedLyricLines = parsed;
  }

  void _updateActiveIndex(Duration currentPos) {
    if (_lyricLines.isEmpty) return;

    int index = -1;

    for (int i = 0; i < _lyricLines.length; i++) {
      if (currentPos >= _lyricLines[i].time) {
        index = i;
      } else {
        break;
      }
    }

    if (index != _activeIndex) {
      setState(() {
        _activeIndex = index;
      });
      _scrollToActiveIndex();
    }
  }

  void _scrollToActiveIndex() {
    if (_activeIndex < 0 || !_scrollController.hasClients || _selectedIndices.isNotEmpty) return;

    // Standard height of each item is 56 pixels, slightly larger if translation is active
    final double itemHeight = _showTranslation && _translatedLyricLines.isNotEmpty ? 76.0 : 56.0;
    final double viewHeight = _scrollController.position.viewportDimension;
    final double scrollOffset = (_activeIndex * itemHeight) - (viewHeight / 2.0) + (itemHeight / 2.0);

    _scrollController.animateTo(
      scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildDelayButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.inkDeep.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.inkDeep.withAlpha(200)),
            const SizedBox(width: 3),
            Text(
              label,
              style: AppTypography.captionBold.copyWith(
                color: AppColors.inkDeep.withAlpha(200),
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLineSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        if (_selectedIndices.length < 4) {
          _selectedIndices.add(index);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('select_lyrics_hint', listen: false)),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  Future<void> _captureAndSaveCard(GlobalKey key, BuildContext context) async {
    try {
      final RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/lyric_card_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);
        
        if (context.mounted) {
          Navigator.pop(context); // Close preview dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('image_saved', listen: false)),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing lyric card: $e');
    }
  }

  void _showLyricCardGenerator() {
    if (_selectedIndices.isEmpty) return;

    final sortedIndices = _selectedIndices.toList()..sort();
    final selectedLines = sortedIndices.map((i) => _lyricLines[i]).toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _cardBoundaryKey,
                child: Container(
                  width: 320,
                  height: 480,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                      ],
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Blurred Album Cover background
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.35,
                          child: Image.network(
                            widget.song.coverUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      // Card Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.music_note_rounded, color: Colors.white70, size: 20),
                                Text(
                                  'ChillMsic',
                                  style: AppTypography.captionBold.copyWith(
                                    color: Colors.white38,
                                    letterSpacing: 1.5,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(flex: 2),
                            // Selected Lines
                            ...selectedLines.map((line) => Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: Text(
                                line.text,
                                style: GoogleFonts.outfit(
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            )),
                            const Spacer(flex: 3),
                            // Song Info
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.song.coverUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.song.title,
                                        style: AppTypography.bodySmBold.copyWith(color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.song.artist,
                                        style: AppTypography.caption.copyWith(color: Colors.white60),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      context.tr('cancel'),
                      style: AppTypography.bodySmBold.copyWith(color: Colors.white),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text(
                      context.tr('save_image_btn'),
                      style: AppTypography.bodySmBold,
                    ),
                    onPressed: () => _captureAndSaveCard(_cardBoundaryKey, context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();
    return BlocListener<PlayerBloc, PlayerState>(
      listenWhen: (prev, curr) =>
          prev.position != curr.position ||
          prev.lyricDelayMs != curr.lyricDelayMs ||
          prev.translatedLyrics != curr.translatedLyrics ||
          prev.appLocale != curr.appLocale,
      listener: (context, state) {
        _updateActiveIndex(state.position + Duration(milliseconds: state.lyricDelayMs));
        if (state.translatedLyrics.isNotEmpty && _translatedRaw != state.translatedLyrics) {
          _translatedRaw = state.translatedLyrics;
          setState(() {
            _parseTranslatedLyrics(state.translatedLyrics);
          });
        }
      },
      child: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          final fontMultiplier = state.lyricFontSizeMultiplier;
          
          return Column(
            children: [
              const SizedBox(height: 12),
              // Top control row with Cover view, Font adjustment and Translation options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tap to return header
                    GestureDetector(
                      onTap: widget.onBackToCover,
                      child: Row(
                        children: [
                          Icon(Icons.photo_size_select_actual_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('view_cover'),
                            style: AppTypography.captionBold.copyWith(color: AppColors.primary, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    
                    // Font sizes and AI Translate actions
                    Row(
                      children: [
                        // Font Size buttons
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: fontMultiplier > 0.8
                              ? () => playerBloc.add(ChangeLyricFontSizeEvent(fontMultiplier - 0.2))
                              : null,
                        ),
                        Text(
                          'Aa',
                          style: AppTypography.captionBold.copyWith(fontSize: 11 * fontMultiplier),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: fontMultiplier < 1.4
                              ? () => playerBloc.add(ChangeLyricFontSizeEvent(fontMultiplier + 0.2))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        
                        // AI Translate
                        if (state.isTranslating)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              if (state.translatedLyrics.isEmpty) {
                                playerBloc.add(TranslateCurrentSongLyricsEvent());
                              }
                              setState(() {
                                _showTranslation = !_showTranslation;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: _showTranslation ? AppColors.primary : AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.hairline),
                              ),
                              child: Text(
                                _showTranslation ? context.tr('original') : context.tr('ai_translate_btn'),
                                style: AppTypography.captionBold.copyWith(
                                  fontSize: 8,
                                  color: _showTranslation ? Colors.white : AppColors.inkDeep,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1, color: Colors.transparent),
              
              // Hint for selection if indices selected
              if (_selectedIndices.isNotEmpty)
                Container(
                  color: AppColors.primarySoft,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('select_lyrics_hint'),
                        style: AppTypography.captionBold.copyWith(color: AppColors.primary, fontSize: 10),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _selectedIndices.clear()),
                            child: Text(
                              context.tr('cancel'),
                              style: AppTypography.captionBold.copyWith(color: AppColors.charcoal, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _showLyricCardGenerator,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${context.tr('lyric_card_btn')} (${_selectedIndices.length})',
                                style: AppTypography.captionBold.copyWith(color: Colors.white, fontSize: 9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _lyricLines.isEmpty
                    ? Center(
                        child: Text(
                          widget.song.lyrics.isEmpty
                              ? context.tr('error')
                              : widget.song.lyrics,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.charcoal,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : RepaintBoundary(
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.white,
                                Colors.white,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.15, 0.85, 1.0],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstIn,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
                            itemCount: _lyricLines.length,
                            itemBuilder: (context, index) {
                              final line = _lyricLines[index];
                              final isActive = index == _activeIndex;
                              final isSelected = _selectedIndices.contains(index);
                              
                              final translatedLine = _showTranslation && index < _translatedLyricLines.length
                                  ? _translatedLyricLines[index]
                                  : null;

                              final int distance = (index - _activeIndex).abs();
                              final double opacity = (1.0 - distance * 0.25).clamp(0.15, 1.0);
                              final double scale = (1.0 - distance * 0.05).clamp(0.85, 1.0);

                              return InkWell(
                                onTap: () => _toggleLineSelection(index),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: opacity,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 300),
                                    scale: scale,
                                    child: Container(
                                      height: _showTranslation && _translatedLyricLines.isNotEmpty ? 76 : 56, // Adjusted height
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 250),
                                        style: AppTypography.bodyMd.copyWith(
                                          fontSize: (isActive ? 16 : 14) * fontMultiplier,
                                          height: 1.2,
                                          color: isActive
                                              ? AppColors.primary
                                              : AppColors.inkDeep.withAlpha(isActive ? 255 : 100),
                                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                                        ),
                                        child: Text(
                                          line.text,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (translatedLine != null && translatedLine.text.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            translatedLine.text,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.caption.copyWith(
                                              fontSize: 11 * fontMultiplier,
                                              color: isActive
                                                  ? AppColors.primary.withOpacity(0.8)
                                                  : AppColors.inkDeep.withOpacity(0.4),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                          ),
                        ),
                      ),
              ),
              // Lyrics delay sync adjuster bar
              BlocBuilder<PlayerBloc, PlayerState>(
                buildWhen: (prev, curr) => prev.lyricDelayMs != curr.lyricDelayMs || prev.appLocale != curr.appLocale,
                builder: (context, state) {
                  final delaySeconds = state.lyricDelayMs / 1000.0;
                  final delayText = delaySeconds > 0 ? '+${delaySeconds.toStringAsFixed(1)}s' : '${delaySeconds.toStringAsFixed(1)}s';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${context.tr('lyrics_delay')}:',
                            style: AppTypography.captionBold.copyWith(
                              color: AppColors.inkDeep.withAlpha(150),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildDelayButton(
                            icon: Icons.remove_circle_outline,
                            label: '-0.5s',
                            onPressed: () {
                              context.read<PlayerBloc>().add(
                                AdjustLyricDelayEvent(state.lyricDelayMs - 500),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withAlpha(50), width: 1),
                            ),
                            child: Text(
                              delayText,
                              style: AppTypography.captionBold.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildDelayButton(
                            icon: Icons.add_circle_outline,
                            label: '+0.5s',
                            onPressed: () {
                              context.read<PlayerBloc>().add(
                                AdjustLyricDelayEvent(state.lyricDelayMs + 500),
                              );
                            },
                          ),
                          if (state.lyricDelayMs != 0) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                context.read<PlayerBloc>().add(
                                  const AdjustLyricDelayEvent(0),
                                );
                              },
                              child: Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

class LyricLine {
  final Duration time;
  final String text;
  LyricLine(this.time, this.text);
}
