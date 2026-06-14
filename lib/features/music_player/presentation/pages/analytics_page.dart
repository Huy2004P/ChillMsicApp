import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../core/service/gemini_service.dart';
import '../../domain/entities/song.dart';
import '../bloc/player_bloc.dart';
import '../widgets/meta_components.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _isLoading = false;
  String? _analysisResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize controller with current state value
    final currentKey = context.read<PlayerBloc>().state.geminiApiKey;
    _apiKeyController.text = currentKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _startGeminiAnalysis(PlayerState state) async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _errorMessage = context.tr('no_key_warning', listen: false);
      });
      return;
    }

    // Save API key to state
    context.read<PlayerBloc>().add(UpdateGeminiApiKeyEvent(apiKey));

    final int minutes = state.totalListeningDuration.inMinutes;
    final int seconds = state.totalListeningDuration.inSeconds % 60;

    // Get recently played songs
    final songsList = state.songPlayHistory;
    final String songTitles = songsList.isEmpty 
        ? context.tr('no_songs_played_yet', listen: false)
        : songsList.map((s) => '"${s.title}" - ${s.artist}').join(', ');

    // Calculate genre breakdown
    final String genreList = _getGenreBreakdownString(songsList);

    final locale = state.appLocale.toLowerCase();
    String targetLanguage = 'Vietnamese';
    switch (locale) {
      case 'vi':
        targetLanguage = 'Vietnamese';
        break;
      case 'en':
        targetLanguage = 'English';
        break;
      case 'ko':
        targetLanguage = 'Korean';
        break;
      case 'ja':
        targetLanguage = 'Japanese';
        break;
      case 'zh':
        targetLanguage = 'Chinese';
        break;
      case 'fr':
        targetLanguage = 'French';
        break;
      case 'de':
        targetLanguage = 'German';
        break;
      case 'es':
        targetLanguage = 'Spanish';
        break;
      default:
        targetLanguage = 'the language corresponding to code "$locale"';
    }

    final prompt = '''
You are a Music Psychologist, extremely witty, wise, and humorous, analyzing music tastes for the ChillMsic app.
Please analyze my music taste based on these parameters:
- Total listening duration in this session: $minutes minutes $seconds seconds.
- Recently played songs: $songTitles.
- Genres: $genreList.

Output Requirements:
1. Write ENTIRELY in $targetLanguage, with a sharp, witty, musically therapeutic, and highly entertaining tone.
2. Provide a brief analysis (about 150-200 words) about my current mood and outstanding personality traits based on this music style.
3. Suggest a humorous music tip or an interesting music quote to conclude.
4. Format in clean Markdown with headings (###) and bullet points, utilizing emojis.
''';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      final text = await GeminiService.generateContent(
        apiKey: apiKey,
        prompt: prompt,
      );
      setState(() {
        _analysisResult = text;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi phân tích: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getGenreBreakdownString(List<Song> songs) {
    if (songs.isEmpty) {
      return 'Dữ liệu Demo (V-POP: 50%, Lo-Fi Chill: 30%, Nhạc không lời: 20%)';
    }
    
    final Map<String, int> counts = {};
    for (final song in songs) {
      String genre = 'Nhạc Trẻ';
      final albumLower = song.album.toLowerCase();
      final titleLower = song.title.toLowerCase();
      if (albumLower.contains('lofi') || titleLower.contains('lofi') || albumLower.contains('vietnam lofi')) {
        genre = 'Lo-Fi Chill';
      } else if (albumLower.contains('ost') || albumLower.contains('mắt biếc')) {
        genre = 'Nhạc Phim (OST)';
      } else if (albumLower.contains('dance') || albumLower.contains('edm')) {
        genre = 'EDM / Dance';
      } else if (song.album.isNotEmpty && !song.album.contains('Kết quả') && !song.album.contains('Top')) {
        genre = song.album;
      }
      counts[genre] = (counts[genre] ?? 0) + 1;
    }
    
    return counts.entries.map((e) {
      final double percent = (e.value / songs.length) * 100;
      return '${e.key} (${percent.toStringAsFixed(0)}%)';
    }).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;
    
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          context.tr('analytics_title'),
          style: AppTypography.headingSm.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        buildWhen: (prev, curr) => 
            prev.songPlayHistory != curr.songPlayHistory ||
            prev.totalListeningDuration != curr.totalListeningDuration ||
            prev.isDarkMode != curr.isDarkMode ||
            prev.geminiApiKey != curr.geminiApiKey,
        builder: (context, state) {
          final history = state.songPlayHistory;
          final totalMins = state.totalListeningDuration.inMinutes;
          final totalSecs = state.totalListeningDuration.inSeconds % 60;
          
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(paddingVal),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Dynamic Telemetry Overview
                    Text(
                      context.tr('listening_stats'),
                      style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('listening_stats_desc'),
                      style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 16),
                    
                    // Large glowing circle for Total Listening Time
                    Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceSoft,
                          border: Border.all(
                            color: AppColors.primary.withAlpha(state.isDarkMode ? 50 : 20),
                            width: 6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(state.isDarkMode ? 40 : 10),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$totalMins',
                              style: AppTypography.headingLg.copyWith(
                                fontSize: 44, 
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              context.tr('minutes_seconds_format', args: {'min': '$totalMins', 'sec': '$totalSecs'}),
                              style: AppTypography.captionBold.copyWith(
                                fontSize: 9, 
                                color: AppColors.charcoal,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('total_listening').toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                fontSize: 8, 
                                color: AppColors.steel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Grid of other stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: context.tr('songs_listened').toUpperCase(),
                            value: '${history.length}',
                            sub: context.tr('songs_in_history'),
                            icon: Icons.music_note_rounded,
                            isDarkMode: state.isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: context.tr('hifi_resolution'),
                            value: '24-bit',
                            sub: context.tr('avg_decoding_stream'),
                            icon: Icons.equalizer_rounded,
                            isDarkMode: state.isDarkMode,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Weekly listening habits bar chart
                    _buildWeeklyHabitsChart(state.weeklyListeningStats, state.isDarkMode),
                    
                    const SizedBox(height: 20),
                    _buildGenreBreakdownCard(history, state.isDarkMode),
                    
                    const SizedBox(height: 24),
                    
                    // Section 3: Gemini AI Music Psychologist
                    Text(
                      context.tr('gemini_analysis'),
                      style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('analysis_desc'),
                      style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 16),
                    
                    // Input Gemini API Key Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.hairlineSoft, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('gemini_config'),
                            style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('api_key_ram_warning'),
                            style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _apiKeyController,
                            obscureText: _obscureApiKey,
                            style: AppTypography.bodySm.copyWith(color: AppColors.inkDeep),
                            decoration: InputDecoration(
                              labelText: 'Gemini API Key',
                              labelStyle: TextStyle(color: AppColors.charcoal, fontSize: 13),
                              hintText: 'AIzaSy...',
                              hintStyle: TextStyle(color: AppColors.stone),
                              filled: true,
                              fillColor: AppColors.canvas.withAlpha(state.isDarkMode ? 80 : 180),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.hairline, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureApiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppColors.charcoal,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureApiKey = !_obscureApiKey;
                                  });
                                },
                              ),
                            ),
                            onChanged: (val) {
                              context.read<PlayerBloc>().add(UpdateGeminiApiKeyEvent(val.trim()));
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: _isLoading
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(color: AppColors.primary),
                                    ),
                                  )
                                : MetaButton(
                                    label: context.tr('start_analysis_btn'),
                                    type: MetaButtonType.primary,
                                    icon: Icons.psychology_rounded,
                                    onPressed: () => _startGeminiAnalysis(state),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.critical.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.critical.withAlpha(90), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.critical, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTypography.caption.copyWith(color: AppColors.critical),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // AI Response Card
                    if (_analysisResult != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: state.isDarkMode
                                ? [
                                    const Color(0x1A0054FF),
                                    const Color(0x050054FF),
                                  ]
                                : [
                                    const Color(0x1F0054FF),
                                    const Color(0x050054FF),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withAlpha(50), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00FFCC), size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      context.tr('gemini_analysis_result'),
                                      style: AppTypography.bodySmBold.copyWith(
                                        color: AppColors.primaryDeep,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'GEMINI-1.5-FLASH',
                                  style: AppTypography.captionBold.copyWith(
                                    color: AppColors.steel,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: AppColors.primarySoft),
                            const SizedBox(height: 12),
                            _buildMarkdownText(_analysisResult!, state.isDarkMode),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineSoft, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.captionBold.copyWith(fontSize: 9, color: AppColors.charcoal),
              ),
              Icon(icon, size: 16, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.headingMd.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.inkDeep),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTypography.caption.copyWith(color: AppColors.steel, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGenreBreakdownCard(List<Song> history, bool isDarkMode) {
    // Collect genres and counts
    final Map<String, int> counts = {};
    
    // Add default values for demo if history is empty
    if (history.isEmpty) {
      counts['Lo-Fi Chill'] = 4;
      counts['V-POP / Nhạc Trẻ'] = 3;
      counts['EDM / Dance'] = 2;
      counts['Khác'] = 1;
    } else {
      for (final song in history) {
        String genre = 'Nhạc trẻ';
        final albumLower = song.album.toLowerCase();
        final titleLower = song.title.toLowerCase();
        if (albumLower.contains('lofi') || titleLower.contains('lofi') || albumLower.contains('vietnam lofi')) {
          genre = 'Lo-Fi Chill';
        } else if (albumLower.contains('ost') || albumLower.contains('mắt biếc')) {
          genre = 'Nhạc Phim (OST)';
        } else if (albumLower.contains('dance') || albumLower.contains('edm')) {
          genre = 'EDM / Dance';
        } else if (song.album.isNotEmpty && !song.album.contains('Kết quả') && !song.album.contains('Top')) {
          genre = song.album;
        }
        counts[genre] = (counts[genre] ?? 0) + 1;
      }
    }

    final totalCount = history.isEmpty ? 10 : history.length;
    final sortedGenres = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineSoft, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('favorite_genre').toUpperCase(),
                style: AppTypography.captionBold.copyWith(fontSize: 10, color: AppColors.charcoal),
              ),
              if (history.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.attention.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    context.tr('demo_data'),
                    style: const TextStyle(color: AppColors.attention, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedGenres.map((e) {
            final double percentage = (e.value / totalCount) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key,
                        style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: AppTypography.bodySmBold.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: percentage / 100.0,
                      minHeight: 6,
                      backgroundColor: AppColors.hairline,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMarkdownText(String text, bool isDarkMode) {
    final List<Widget> children = [];
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }
      
      if (trimmed.startsWith('###') || trimmed.startsWith('##') || trimmed.startsWith('#')) {
        final content = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              content,
              style: AppTypography.bodyMdBold.copyWith(
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('*') || trimmed.startsWith('-')) {
        final content = trimmed.replaceAll(RegExp(r'^[\*\-]\s*'), '');
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                Expanded(
                  child: Text(
                    content,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.ink,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Simple regex replace for bold texts in Markdown like **Text**
        String displayLine = trimmed.replaceAll('**', '');
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              displayLine,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.ink,
                height: 1.45,
              ),
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  String _getLocalizedDay(String day, BuildContext context) {
    final Map<String, String> viDays = {
      'Mon': 'T2',
      'Tue': 'T3',
      'Wed': 'T4',
      'Thu': 'T5',
      'Fri': 'T6',
      'Sat': 'T7',
      'Sun': 'CN',
    };
    final Map<String, String> enDays = {
      'Mon': 'Mon',
      'Tue': 'Tue',
      'Wed': 'Wed',
      'Thu': 'Thu',
      'Fri': 'Fri',
      'Sat': 'Sat',
      'Sun': 'Sun',
    };
    final isVi = context.read<PlayerBloc>().state.appLocale == 'vi';
    return isVi ? (viDays[day] ?? day) : (enDays[day] ?? day);
  }

  Widget _buildWeeklyHabitsChart(Map<String, int> weeklyStats, bool isDarkMode) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    int maxSeconds = weeklyStats.values.map((v) => v).fold(0, (max, val) => val > max ? val : max);
    if (maxSeconds < 60) maxSeconds = 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineSoft, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.tr('weekly_habits_title'),
                  style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.tr('weekly_habits_subtitle'),
                  style: AppTypography.caption.copyWith(color: AppColors.steel, fontSize: 10),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekdays.map((day) {
                final int seconds = weeklyStats[day] ?? 0;
                final double mins = seconds / 60.0;
                final double ratio = (seconds / maxSeconds).clamp(0.02, 1.0);
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      mins > 0 ? mins.toStringAsFixed(1) : '0',
                      style: AppTypography.captionBold.copyWith(
                        fontSize: 8, 
                        color: mins > 0 ? AppColors.primary : AppColors.steel,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 16,
                      height: 90 * ratio,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.primary.withAlpha(50),
                            AppColors.primary,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(mins > 0 ? 80 : 0),
                            blurRadius: 6,
                            offset: const Offset(0, -2),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getLocalizedDay(day, context),
                      style: AppTypography.captionBold.copyWith(
                        fontSize: 9,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
