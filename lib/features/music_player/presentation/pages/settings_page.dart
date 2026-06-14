import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/localization/localization_extension.dart';
import '../widgets/meta_components.dart';
import '../widgets/eq_curve_editor.dart';
import '../bloc/player_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'donation_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedTimerMinutes = 0;

  String _sdkInfo = 'Loading...';
  String _notificationStatus = 'Loading...';
  String _storageStatus = 'Loading...';
  String _audioStatus = 'Loading...';

  final TextEditingController _serverUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _serverUrlController.text = 'ChillMsicServer';
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      String sdk = 'Unknown Device';
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final brand = androidInfo.brand;
        final model = androidInfo.model;
        final release = androidInfo.version.release;
        final sdkInt = androidInfo.version.sdkInt;
        final capitalizedBrand = brand.isNotEmpty
            ? '${brand[0].toUpperCase()}${brand.substring(1)}'
            : '';
        sdk = '$capitalizedBrand $model (Android $release, SDK $sdkInt)';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final name = iosInfo.name;
        final model = iosInfo.model;
        final systemVersion = iosInfo.systemVersion;
        sdk = '$name $model (iOS $systemVersion)';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        sdk = '${macInfo.computerName} (macOS ${macInfo.osRelease})';
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        sdk = '${winInfo.computerName} (Windows ${winInfo.releaseId})';
      }

      final notif = await Permission.notification.status;
      final storage = await Permission.storage.status;
      final audio = await Permission.audio.status;

      if (mounted) {
        setState(() {
          _sdkInfo = sdk;
          _notificationStatus = notif.toString().split('.').last;
          _storageStatus = storage.toString().split('.').last;
          _audioStatus = audio.toString().split('.').last;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sdkInfo = 'Error: $e';
        });
      }
    }
  }

  String _getLocalizedPreset(BuildContext context, String name) {
    if (name == 'Mặc định') return context.tr('default_preset');
    if (name == 'Lofi Thư giãn') return context.tr('lofi_relax_preset');
    if (name == 'Tăng Bass (Bass Boost)')
      return context.tr('bass_boost_preset');
    if (name == 'Tùy chỉnh') return context.tr('custom_preset');
    return name;
  }

  Widget _buildColorCircle(
    BuildContext context,
    int colorVal,
    int activeColorVal,
  ) {
    final bool isActive = colorVal == activeColorVal;
    return GestureDetector(
      onTap: () {
        context.read<PlayerBloc>().add(ChangeAccentColorEvent(colorVal));
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Color(colorVal),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(colorVal).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isActive
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildSelectionRow({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmBold.copyWith(
                    color: AppColors.inkDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;

    final timerOptions = [
      {
        'minutes': 0,
        'title': context.tr('sleep_timer_off'),
        'desc': context.tr('app_timer_desc_off'),
        'label': context.tr('default_timer_label'),
      },
      {
        'minutes': 15,
        'title': context.tr('sleep_timer_format', args: {'min': '15'}),
        'desc': context.tr('app_timer_desc_format', args: {'min': '15'}),
        'label': context
            .tr('sleep_timer_format', args: {'min': '15'})
            .toUpperCase(),
      },
      {
        'minutes': 30,
        'title': context.tr('sleep_timer_format', args: {'min': '30'}),
        'desc': context.tr('app_timer_desc_format', args: {'min': '30'}),
        'label': context
            .tr('sleep_timer_format', args: {'min': '30'})
            .toUpperCase(),
      },
      {
        'minutes': 45,
        'title': context.tr('sleep_timer_format', args: {'min': '45'}),
        'desc': context.tr('app_timer_desc_format', args: {'min': '45'}),
        'label': context
            .tr('sleep_timer_format', args: {'min': '45'})
            .toUpperCase(),
      },
      {
        'minutes': 60,
        'title': context.tr('sleep_timer_format', args: {'min': '60'}),
        'desc': context.tr('app_timer_desc_format', args: {'min': '60'}),
        'label': context
            .tr('sleep_timer_format', args: {'min': '60'})
            .toUpperCase(),
      },
    ];

    final eqOptions = [
      'Mặc định',
      'Acoustic',
      'Pop',
      'EDM',
      'Lofi Thư giãn',
      'Tăng Bass (Bass Boost)',
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          context.tr('settings_title'),
          style: AppTypography.headingSm.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(paddingVal),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sleep Timer Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('sleep_timer'),
                          style: AppTypography.subtitleLg.copyWith(
                            color: AppColors.inkDeep,
                          ),
                        ),
                        if (state.sleepTimerRemaining != null)
                          Text(
                            '${state.sleepTimerRemaining!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${state.sleepTimerRemaining!.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                            style: AppTypography.bodySmBold.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('sleep_timer_desc'),
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.charcoal,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...timerOptions.map((opt) {
                      final title = opt['title'] as String;
                      final minutes = opt['minutes'] as int;
                      final isSelected = state.sleepTimerRemaining == null
                          ? minutes == 0
                          : (_selectedTimerMinutes == minutes && minutes != 0);
                      return RadioOptionWidget(
                        title: title,
                        subtitle: opt['desc'] as String,
                        trailingLabel: opt['label'] as String,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedTimerMinutes = minutes;
                          });
                          context.read<PlayerBloc>().add(
                            SetSleepTimerEvent(minutes),
                          );

                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                minutes == 0
                                    ? context.tr(
                                        'sleep_timer_cancelled',
                                        listen: false,
                                      )
                                    : context.tr(
                                        'sleep_timer_set',
                                        args: {'time': title},
                                        listen: false,
                                      ),
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      );
                    }),

                    const SizedBox(height: 20),

                    // Equalizer Section
                    Text(
                      context.tr('equalizer'),
                      style: AppTypography.subtitleLg.copyWith(
                        color: AppColors.inkDeep,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('equalizer_desc'),
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.charcoal,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal category preset selector
                    PillTabNav(
                      categories: eqOptions,
                      selectedCategory: state.eqPresetName,
                      onSelected: (cat) {
                        context.read<PlayerBloc>().add(
                          SelectEqPresetEvent(cat),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Interactive Bezier EQ Graphic Display
                    Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.isDarkMode
                              ? [
                                  const Color(0x1F172033),
                                  const Color(0x0D172033),
                                ]
                              : [
                                  const Color(0x33F2F4F8),
                                  const Color(0x11F2F4F8),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(
                            AppColors.isDarkMode ? 40 : 20,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(
                              AppColors.isDarkMode ? 15 : 5,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: EqCurveEditor(
                        bands: state.eqBands,
                        onBandChanged: (band, value) {
                          context.read<PlayerBloc>().add(
                            UpdateEqBandEvent(band: band, value: value),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Visual specs table for selected preset
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.isDarkMode
                            ? const Color(0x0F000000)
                            : const Color(0x0A000000),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.hairlineSoft.withAlpha(60),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${context.tr('frequency_spec')}: ${_getLocalizedPreset(context, state.eqPresetName)}',
                                style: AppTypography.bodySmBold.copyWith(
                                  color: AppColors.inkDeep,
                                ),
                              ),
                              Text(
                                context.tr('live_monitor'),
                                style: AppTypography.captionBold.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          EqBandLevelMeter(
                            bands: state.eqBands,
                            isDarkMode: AppColors.isDarkMode,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Headphone Impedance matching
                    Text(
                      context.tr('headphone_profile'),
                      style: AppTypography.subtitleLg.copyWith(
                        color: AppColors.inkDeep,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('headphone_profile_desc'),
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.charcoal,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...[
                      {
                        'key': 'Tai nghe In-Ear (IEM / Nhẹ - 16Ω)',
                        'profile': context.tr('headphone_iem'),
                        'desc': context.tr('headphone_iem_desc'),
                        'label': '0 dB',
                      },
                      {
                        'key': 'Tai nghe Chụp tai (On-Ear / Vừa - 32Ω)',
                        'profile': context.tr('headphone_onear'),
                        'desc': context.tr('headphone_onear_desc'),
                        'label': '+3 dB',
                      },
                      {
                        'key': 'Tai nghe Phòng thu (Audiophile / Cao - 250Ω)',
                        'profile': context.tr('headphone_studio'),
                        'desc': context.tr('headphone_studio_desc'),
                        'label': '+9 dB',
                      },
                    ].map((opt) {
                      final key = opt['key']!;
                      final profile = opt['profile']!;
                      final isSelected = state.headphoneProfile == key;
                      return RadioOptionWidget(
                        title: profile,
                        subtitle: opt['desc']!,
                        trailingLabel: opt['label']!,
                        isSelected: isSelected,
                        onTap: () {
                          context.read<PlayerBloc>().add(
                            UpdateHeadphoneProfileEvent(key),
                          );
                        },
                      );
                    }),

                    const SizedBox(height: 20),

                    // System settings toggle switches
                    Text(
                      context.tr('system_config'),
                      style: AppTypography.subtitleLg.copyWith(
                        color: AppColors.inkDeep,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Gapless Playback Switch
                    _buildToggleRow(
                      title: context.tr('gapless_playback'),
                      subtitle: context.tr('gapless_playback_desc'),
                      value: state.gaplessEnabled,
                      onChanged: (val) {
                        context.read<PlayerBloc>().add(ToggleGaplessEvent());
                      },
                    ),

                    Divider(color: AppColors.hairlineSoft, height: 12),

                    // Crossfade Controller
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('crossfade'),
                                    style: AppTypography.bodySmBold.copyWith(
                                      color: AppColors.inkDeep,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr('crossfade_desc'),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.charcoal,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              state.crossfadeSeconds == 0
                                  ? context.tr('off')
                                  : context.tr(
                                      'crossfade_value',
                                      args: {
                                        'sec': '${state.crossfadeSeconds}',
                                      },
                                    ),
                              style: AppTypography.bodySmBold.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.hairlineSoft,
                            thumbColor: AppColors.primary,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                          ),
                          child: Slider(
                            min: 0.0,
                            max: 12.0,
                            divisions: 12,
                            value: state.crossfadeSeconds.toDouble(),
                            onChanged: (val) {
                              context.read<PlayerBloc>().add(
                                UpdateCrossfadeEvent(val.toInt()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    Divider(color: AppColors.hairlineSoft, height: 12),

                    // Language Selector
                    _buildSelectionRow(
                      title: context.tr('app_language'),
                      subtitle: context.tr('app_language_desc'),
                      child: DropdownButton<String>(
                        value: state.appLocale,
                        dropdownColor: AppColors.surfaceSoft,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        style: AppTypography.bodySmBold.copyWith(
                          color: AppColors.inkDeep,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'vi',
                            child: Text('Tiếng Việt'),
                          ),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(
                            value: 'ko',
                            child: Text('한국어 (Korean)'),
                          ),
                          DropdownMenuItem(
                            value: 'ja',
                            child: Text('日本語 (Japanese)'),
                          ),
                          DropdownMenuItem(
                            value: 'zh',
                            child: Text('中文 (Chinese)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            context.read<PlayerBloc>().add(
                              ChangeLocaleEvent(val),
                            );
                          }
                        },
                      ),
                    ),

                    Divider(color: AppColors.hairlineSoft, height: 12),

                    // Theme Color selection circles
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('theme_color'),
                            style: AppTypography.bodySmBold.copyWith(
                              color: AppColors.inkDeep,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('theme_color_desc'),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildColorCircle(
                                context,
                                0xFF0054FF,
                                state.themeAccentColor,
                              ), // Cobalt Blue
                              const SizedBox(width: 12),
                              _buildColorCircle(
                                context,
                                0xFFFA3E3E,
                                state.themeAccentColor,
                              ), // Crimson Red
                              const SizedBox(width: 12),
                              _buildColorCircle(
                                context,
                                0xFF00A400,
                                state.themeAccentColor,
                              ), // Emerald Green
                              const SizedBox(width: 12),
                              _buildColorCircle(
                                context,
                                0xFFFF7A00,
                                state.themeAccentColor,
                              ), // Sunset Orange
                              const SizedBox(width: 12),
                              _buildColorCircle(
                                context,
                                0xFF7014F2,
                                state.themeAccentColor,
                              ), // Cyberpunk Purple
                            ],
                          ),
                        ],
                      ),
                    ),

                    Divider(color: AppColors.hairlineSoft, height: 12),

                    // Caching settings card
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('offline_caching'),
                                  style: AppTypography.bodySmBold.copyWith(
                                    color: AppColors.inkDeep,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${context.tr('cache_size')}: ${state.audioCacheSize.toStringAsFixed(1)} MB',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.charcoal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceSoft,
                              foregroundColor: AppColors.critical,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppColors.hairline),
                              ),
                            ),
                            onPressed: () {
                              context.read<PlayerBloc>().add(
                                ClearAudioCacheEvent(),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr('cache_cleared', listen: false),
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            child: Text(
                              context.tr('clear_cache_btn'),
                              style: AppTypography.bodySmBold.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(color: AppColors.hairlineSoft, height: 12),

                    // Dark mode switch
                    _buildToggleRow(
                      title: context.tr('dark_mode'),
                      subtitle: context.tr('dark_mode_desc'),
                      value: state.isDarkMode,
                      onChanged: (val) {
                        context.read<PlayerBloc>().add(ToggleDarkModeEvent());
                      },
                    ),

                    Divider(color: AppColors.hairlineSoft, height: 24),

                    // Cấu hình Kết nối Máy chủ API
                    Text(
                      context.tr('api_server_config'),
                      style: AppTypography.subtitleLg.copyWith(
                        color: AppColors.inkDeep,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('api_server_desc'),
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.critical,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.hairlineSoft,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _serverUrlController,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Server',
                              labelStyle: AppTypography.captionBold.copyWith(
                                color: AppColors.charcoal,
                              ),
                              hintText: 'http://192.168.1.X:3000',
                              filled: true,
                              fillColor: AppColors.canvas.withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.hairlineSoft,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.hairlineSoft,
                                ),
                              ),
                            ),
                            style: AppTypography.bodySmBold.copyWith(
                              color: AppColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(color: AppColors.hairlineSoft, height: 24),

                    // Hạng mục Quyên góp & 🎟️
                    _buildSettingsLinkRow(
                      title: context.tr('donation_title'),
                      subtitle: context.tr('donation_desc_short'),
                      icon: Icons.favorite_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DonationPage(),
                          ),
                        );
                      },
                    ),

                    Divider(color: AppColors.hairlineSoft, height: 16),
                    _buildSettingsLinkRow(
                      title: context.tr('privacy_policy'),
                      subtitle: context.tr('privacy_desc'),
                      icon: Icons.security_rounded,
                      onTap: () => _launchUrl(
                        'https://portfolio.vanhuy2004h.io.vn/privacy',
                      ),
                    ),
                    Divider(color: AppColors.hairlineSoft, height: 16),
                    _buildSettingsLinkRow(
                      title: context.tr('terms_of_service'),
                      subtitle: context.tr('terms_desc'),
                      icon: Icons.description_rounded,
                      onTap: () => _launchUrl(
                        'https://portfolio.vanhuy2004h.io.vn/terms',
                      ),
                    ),

                    Divider(color: AppColors.hairlineSoft, height: 24),
                    _buildDebugPermissionsSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebugPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('permissions_status'),
          style: AppTypography.subtitleLg.copyWith(color: AppColors.inkDeep),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('permissions_status_desc'),
          style: AppTypography.bodySm.copyWith(
            color: AppColors.charcoal,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
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
              _buildDebugRow(context.tr('device_sdk'), _sdkInfo),
              Divider(color: AppColors.hairlineSoft, height: 16),
              _buildDebugRow(
                context.tr('notification_permission'),
                _notificationStatus,
              ),
              Divider(color: AppColors.hairlineSoft, height: 16),
              _buildDebugRow(context.tr('storage_permission'), _storageStatus),
              Divider(color: AppColors.hairlineSoft, height: 16),
              _buildDebugRow(context.tr('audio_permission'), _audioStatus),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: MetaButton(
            label: context.tr('request_permissions_btn'),
            type: MetaButtonType.primary,
            onPressed: () async {
              await [
                Permission.notification,
                Permission.storage,
                Permission.audio,
              ].request();
              await _checkPermissions();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDebugRow(String label, String value) {
    Color valColor = AppColors.inkDeep;
    String displayVal = value;

    if (value == 'granted') {
      valColor = AppColors.primaryDeep;
      displayVal = context.tr('perm_granted');
    } else if (value == 'denied') {
      valColor = AppColors.criticalStrong;
      displayVal = context.tr('perm_denied');
    } else if (value == 'permanentlyDenied') {
      valColor = AppColors.criticalStrong;
      displayVal = context.tr('perm_permanently_denied');
    } else if (value.toLowerCase() == 'unknown') {
      displayVal = context.tr('perm_unknown');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmBold.copyWith(color: AppColors.charcoal),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            displayVal,
            style: AppTypography.bodySmBold.copyWith(color: valColor),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String urlStr) async {
    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlStr';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'cannot_open_link',
                args: {'error': '$e'},
                listen: false,
              ),
            ),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  Widget _buildSettingsLinkRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmBold.copyWith(
                      color: AppColors.inkDeep,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.charcoal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmBold.copyWith(
                  color: AppColors.inkDeep,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.charcoal,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withAlpha(51),
          inactiveThumbColor: AppColors.stone,
          inactiveTrackColor: AppColors.surfaceSoft,
        ),
      ],
    );
  }
}
