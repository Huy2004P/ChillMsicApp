import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../core/service/audio_player_service.dart';
import '../../domain/entities/song.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/player_bloc.dart';
import '../widgets/meta_components.dart';
import 'player_page.dart';
import '../../data/datasources/music_remote_data_source.dart';

class HomeMusicPage extends StatefulWidget {
  const HomeMusicPage({super.key});

  @override
  State<HomeMusicPage> createState() => _HomeMusicPageState();
}

class _HomeMusicPageState extends State<HomeMusicPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _suggestions = [];
  bool _isSearchFocused = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
    // Fetch initial list of songs
    context.read<CatalogBloc>().add(FetchSongsEvent());
  }

  void _onFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    try {
      final url = '${HttpMusicRemoteDataSourceImpl.baseUrl}/api/search/suggest?q=${Uri.encodeComponent(query.trim())}';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _suggestions = data.map((item) => item.toString()).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('[ChillMsic Debug] Lỗi khi tải gợi ý tìm kiếm: $e');
    }
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _searchFocusNode.unfocus();
    setState(() {
      _suggestions = [];
    });
    context.read<CatalogBloc>().add(SearchSongsEvent(suggestion));
    context.read<PlayerBloc>().add(AddSearchQueryEvent(suggestion));
  }

  @override
  Widget build(BuildContext context) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, catalogState) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        // 1. Desktop/Mobile Navigation Header
                        _buildHeader(context),
                        
                        // 3. Scrollable Page Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 0),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hero Banner
                                _buildHeroBanner(context, catalogState.allSongs),
                                
                                const SizedBox(height: 16),
                                
                                // Category Selector
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: paddingVal),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('explore_music'),
                                        style: AppTypography.headingSm.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      PillTabNav(
                                        categories: const ['Discover', 'My Playlist', 'Charts'],
                                        selectedCategory: catalogState.selectedCategory,
                                        onSelected: (category) {
                                          context.read<CatalogBloc>().add(SelectCategoryEvent(category));
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Search History Block
                                BlocBuilder<PlayerBloc, PlayerState>(
                                  buildWhen: (prev, curr) => prev.searchHistory != curr.searchHistory,
                                  builder: (context, playerState) {
                                    return _buildSearchHistory(context, playerState);
                                  },
                                ),
                                
                                // Track List Section
                                _buildTrackList(context, catalogState),
                                
                                const SizedBox(height: 20),
                                
                                // Recently Played Block
                                BlocBuilder<PlayerBloc, PlayerState>(
                                  buildWhen: (prev, curr) => prev.songPlayHistory != curr.songPlayHistory,
                                  builder: (context, playerState) {
                                    return _buildRecentlyPlayed(context, playerState);
                                  },
                                ),
                                
                                // Why ChillMsic (Feature Icon Row)
                                _buildFeatureIconRow(),
                                
                                const SizedBox(height: 24),
                                
                                // Footer Region
                                _buildFooter(context),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Floating Search Suggestions Dropdown Overlay
                    if (_suggestions.isNotEmpty && _isSearchFocused)
                      Positioned(
                        top: 64, // Directly below the header (height 64)
                        left: 80, // Align under the search input
                        right: 16,
                        child: Material(
                          elevation: 12,
                          color: AppColors.surfaceSoft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppColors.hairlineSoft, width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _suggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = _suggestions[index];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: Icon(Icons.search, color: AppColors.steel, size: 16),
                                  title: Text(
                                    suggestion,
                                    style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
                                  ),
                                  onTap: () => _selectSuggestion(suggestion),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- Sub-widgets ---



  Widget _buildHeader(BuildContext context) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: paddingVal),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          bottom: BorderSide(color: AppColors.hairlineSoft, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Logo
          Text(
            'ChillMsic',
            style: AppTypography.headingSm.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.inkDeep,
            ),
          ),
          // Search Bar (Fixed Text Overflow using Expanded)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: SearchPill(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: context.tr('search_placeholder'),
                onChanged: (value) {
                  context.read<CatalogBloc>().add(SearchSongsEvent(value));
                  
                  // Debounce search suggest requests to honor backend rate limiting (300 reqs / 15 mins)
                  _debounceTimer?.cancel();
                  if (value.trim().isEmpty) {
                    setState(() {
                      _suggestions = [];
                    });
                    return;
                  }
                  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                    _fetchSuggestions(value);
                  });
                },
                onSubmitted: (value) {
                  setState(() {
                    _suggestions = [];
                  });
                  if (value.trim().length > 2) {
                    context.read<PlayerBloc>().add(AddSearchQueryEvent(value.trim()));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, List<Song> allSongs) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;
    return Container(
      margin: EdgeInsets.all(paddingVal),
      constraints: const BoxConstraints(minHeight: 220),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // {rounded.xxl}
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?q=90&w=1200'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withAlpha(217), // Dark overlay for text readability
            ],
            stops: const [0.3, 1.0],
          ),
        ),
        padding: EdgeInsets.all(paddingVal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Badge
            Container(
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(100), // {rounded.full}
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                context.tr('featured_playlist'),
                style: AppTypography.captionBold.copyWith(color: const Color(0xFF0A1317)),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              context.tr('hero_title'),
              style: AppTypography.headingLg.copyWith(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width < 360 ? 22 : 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              context.tr('hero_subtitle'),
              style: AppTypography.bodySm.copyWith(color: Colors.white70, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            // CTAs
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                MetaButton(
                  label: context.tr('play_now'),
                  type: MetaButtonType.primary,
                  icon: Icons.play_arrow,
                  onPressed: () {
                    if (allSongs.isNotEmpty) {
                      context.read<PlayerBloc>().add(PlaySongEvent(
                            song: allSongs[0],
                            queue: allSongs,
                          ));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlayerPage()),
                      );
                    }
                  },
                ),
                MetaButton(
                  label: context.tr('details'),
                  type: MetaButtonType.secondary,
                  onPressed: () {
                    // Navigate to details page of the first song
                    if (allSongs.isNotEmpty) {
                      context.read<PlayerBloc>().add(PlaySongEvent(
                            song: allSongs[0],
                            queue: allSongs,
                          ));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlayerPage()),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList(BuildContext context, CatalogState catalogState) {
    if (catalogState.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (catalogState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            catalogState.errorMessage!,
            style: AppTypography.bodyMd.copyWith(color: AppColors.criticalStrong),
          ),
        ),
      );
    }

    final songs = catalogState.filteredSongs;
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            context.tr('no_songs_in_genre'),
            style: AppTypography.bodyMd.copyWith(color: AppColors.charcoal),
          ),
        ),
      );
    }

    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: paddingVal),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return BlocBuilder<PlayerBloc, PlayerState>(
          buildWhen: (previous, current) {
            final wasPlayingThis = previous.currentSong?.id == song.id;
            final isPlayingThis = current.currentSong?.id == song.id;
            if (wasPlayingThis != isPlayingThis) return true;
            if (isPlayingThis && previous.playerState != current.playerState) return true;

            final wasDownloaded = previous.downloadedSongs.any((s) => s.id == song.id);
            final isDownloaded = current.downloadedSongs.any((s) => s.id == song.id);
            if (wasDownloaded != isDownloaded) return true;

            final wasDownloading = previous.downloadingSongIds.contains(song.id);
            final isDownloading = current.downloadingSongIds.contains(song.id);
            if (wasDownloading != isDownloading) return true;

            return false;
          },
          builder: (context, playerState) {
            final isPlayingThis = playerState.currentSong?.id == song.id;
            final isDownloaded = playerState.downloadedSongs.any((s) => s.id == song.id);
            final isDownloading = playerState.downloadingSongIds.contains(song.id);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPlayingThis ? AppColors.surfaceSoft : AppColors.canvas,
                borderRadius: BorderRadius.circular(12), // {rounded.xl}
                border: Border.all(
                  color: isPlayingThis ? AppColors.primary : AppColors.hairlineSoft,
                  width: isPlayingThis ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Artwork
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8), // {rounded.md}
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
                  
                  // Title + Artist
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
                            if (isDownloaded) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.download_done_rounded,
                                color: Color(0xFF00FFCC),
                                size: 16,
                              ),
                            ],
                            if (isDownloading) ...[
                              const SizedBox(width: 6),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FFCC)),
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
                  
                  // Song length
                  Text(
                    song.duration,
                    style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                  ),
                  const SizedBox(width: 12),
                  
                  // Favorite button
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
                  
                  // Play button icon
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
                        final query = _searchController.text.trim();
                        if (query.length > 2) {
                          context.read<PlayerBloc>().add(AddSearchQueryEvent(query));
                        }
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

  Widget _buildFeatureIconRow() {
    final features = [
      {'icon': Icons.audiotrack_rounded, 'title': context.tr('feature_hifi_title'), 'desc': context.tr('feature_hifi_desc')},
      {'icon': Icons.download_done_rounded, 'title': context.tr('feature_offline_title'), 'desc': context.tr('feature_offline_desc')},
      {'icon': Icons.surround_sound_rounded, 'title': context.tr('feature_spatial_title'), 'desc': context.tr('feature_spatial_desc')},
      {'icon': Icons.snooze_rounded, 'title': context.tr('feature_timer_title'), 'desc': context.tr('feature_timer_desc')},
    ];

    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingVal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('experience_chillmsic'),
            style: AppTypography.headingSm.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Column(
            children: features.map((f) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(16), // {rounded.xl}
                  border: Border.all(color: AppColors.hairlineSoft, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(f['icon'] as IconData, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['title'] as String,
                            style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            f['desc'] as String,
                            style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          top: BorderSide(color: AppColors.hairlineSoft, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: paddingVal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ChillMsic',
            style: AppTypography.bodyMdBold.copyWith(letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('footer_copyright'),
            style: AppTypography.caption.copyWith(color: AppColors.slate, height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text(context.tr('privacy_policy'), style: AppTypography.captionBold.copyWith(fontSize: 11)),
              Text(context.tr('terms_of_service'), style: AppTypography.captionBold.copyWith(fontSize: 11)),
              Text(context.tr('cookie_settings'), style: AppTypography.captionBold.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory(BuildContext context, PlayerState playerState) {
    final history = playerState.searchHistory;
    if (history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('recent_searches'),
                style: AppTypography.captionBold.copyWith(color: AppColors.charcoal),
              ),
              GestureDetector(
                onTap: () {
                  context.read<PlayerBloc>().add(ClearSearchHistoryEvent());
                },
                child: Text(
                  context.tr('clear_history'),
                  style: AppTypography.caption.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: history.map((query) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = query;
                    context.read<CatalogBloc>().add(SearchSongsEvent(query));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.hairlineSoft, width: 1),
                    ),
                    child: Text(
                      query,
                      style: AppTypography.caption.copyWith(color: AppColors.inkDeep),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyPlayed(BuildContext context, PlayerState playerState) {
    final history = playerState.songPlayHistory;
    if (history.isEmpty) return const SizedBox.shrink();

    final reversedSongs = history.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            context.tr('recently_played'),
            style: AppTypography.headingSm.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: reversedSongs.length,
            itemBuilder: (context, index) {
              final song = reversedSongs[index];
              return GestureDetector(
                onTap: () {
                  context.read<PlayerBloc>().add(PlaySongEvent(song: song, queue: reversedSongs));
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerPage()),
                  );
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          song.coverUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            color: AppColors.steel,
                            child: const Icon(Icons.music_note, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        song.title,
                        style: AppTypography.captionBold.copyWith(color: AppColors.inkDeep),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: AppTypography.caption.copyWith(color: AppColors.charcoal, fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Mini Player removed here as it is now managed globally by MainNavigationPage.
}
