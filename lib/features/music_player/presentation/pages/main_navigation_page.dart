import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/service/audio_player_service.dart';
import '../../../../core/localization/localization_extension.dart';
import '../bloc/player_bloc.dart';
import '../widgets/meta_components.dart';
import 'home_music_page.dart';
import 'library_page.dart';
import 'settings_page.dart';
import 'analytics_page.dart';
import 'player_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermissions();
    });
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      debugPrint('[ChillMsic Debug] --- Bắt đầu kiểm tra quyền ---');
      
      bool needsNotification = false;
      bool needsStorage = false;
      bool needsAudio = false;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        debugPrint('[ChillMsic Debug] Thiết bị Android SDK: $sdkInt');

        if (sdkInt >= 33) {
          // Android 13+ requires Notification and Audio permissions, storage is not used/needed
          final notificationStatus = await Permission.notification.status;
          final audioStatus = await Permission.audio.status;
          debugPrint('[ChillMsic Debug] Android 13+ -> Trạng thái Notification: $notificationStatus, Audio: $audioStatus');
          
          needsNotification = notificationStatus.isDenied;
          needsAudio = audioStatus.isDenied;
        } else {
          // Android 12 and below requires Storage permission, notification is granted by default
          final storageStatus = await Permission.storage.status;
          debugPrint('[ChillMsic Debug] Android 12- -> Trạng thái Storage: $storageStatus');
          
          needsStorage = storageStatus.isDenied;
        }
      } else if (Platform.isIOS) {
        final notificationStatus = await Permission.notification.status;
        debugPrint('[ChillMsic Debug] iOS -> Trạng thái Notification: $notificationStatus');
        needsNotification = notificationStatus.isDenied;
      }

      if (needsNotification || needsStorage || needsAudio) {
        debugPrint('[ChillMsic Debug] Phát hiện có quyền chưa được cấp. Hiển thị Bottom Sheet giải thích.');
        if (mounted) {
          _showPermissionExplanationSheet(context, needsNotification, needsStorage, needsAudio);
        }
      } else {
        debugPrint('[ChillMsic Debug] Tất cả các quyền cần thiết đã được cấp trước đó.');
      }
    } catch (e, stack) {
      debugPrint('[ChillMsic Debug] Lỗi khi kiểm tra trạng thái quyền: $e');
      debugPrint(stack.toString());
    }
  }

  void _showPermissionExplanationSheet(
    BuildContext context, 
    bool needsNotification, 
    bool needsStorage, 
    bool needsAudio,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.hairlineSoft, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag indicator
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stone,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Notification/Security Icon with clean border
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Icon(
                  needsNotification ? Icons.notifications_active_rounded : Icons.audio_file_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                context.tr('permission_need_title'),
                style: AppTypography.headingSm.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('permission_need_desc'),
                    style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
                  ),
                  const SizedBox(height: 16),
                  if (needsNotification)
                    _buildPermissionTile(
                      icon: Icons.notifications_active_rounded,
                      title: context.tr('permission_notification_title'),
                      description: context.tr('permission_notification_desc'),
                    ),
                  if (needsNotification && (needsStorage || needsAudio))
                    const SizedBox(height: 12),
                  if (needsStorage || needsAudio)
                    _buildPermissionTile(
                      icon: Icons.audio_file_rounded,
                      title: context.tr('permission_storage_title'),
                      description: context.tr('permission_storage_desc'),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        side: BorderSide(color: AppColors.hairlineSoft, width: 1.5),
                      ),
                      onPressed: () {
                        debugPrint('[ChillMsic Debug] Người dùng bấm "Để sau"');
                        Navigator.pop(context);
                      },
                      child: Text(
                        context.tr('permission_later'),
                        style: AppTypography.bodySmBold.copyWith(color: AppColors.charcoal),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.canvas,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      onPressed: () {
                        debugPrint('[ChillMsic Debug] Người dùng bấm "Cho phép", đóng Bottom Sheet.');
                        Navigator.pop(context);
                        _requestNativePermissions(needsNotification, needsStorage, needsAudio);
                      },
                      child: Text(
                        context.tr('permission_allow'),
                        style: AppTypography.bodySmBold.copyWith(color: AppColors.canvas),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.caption.copyWith(color: AppColors.charcoal, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _requestNativePermissions(
    bool needsNotification, 
    bool needsStorage, 
    bool needsAudio,
  ) async {
    try {
      final List<Permission> permissionsToRequest = [];
      if (needsNotification) permissionsToRequest.add(Permission.notification);
      if (needsStorage) permissionsToRequest.add(Permission.storage);
      if (needsAudio) permissionsToRequest.add(Permission.audio);

      if (permissionsToRequest.isEmpty) return;

      debugPrint('[ChillMsic Debug] Đang gửi yêu cầu xin quyền lên HĐH cho: $permissionsToRequest');
      final statuses = await permissionsToRequest.request();
      
      debugPrint('[ChillMsic Debug] Kết quả yêu cầu cấp quyền:');
      statuses.forEach((permission, status) {
        debugPrint('  - $permission: $status');
      });

      bool isAnyPermanentlyDenied = false;
      for (var permission in permissionsToRequest) {
        if (statuses[permission]?.isPermanentlyDenied ?? false) {
          isAnyPermanentlyDenied = true;
          break;
        }
      }

      if (isAnyPermanentlyDenied) {
        debugPrint('[ChillMsic Debug] Có quyền bị từ chối vĩnh viễn. Hiển thị Dialog hướng dẫn Cài đặt.');
        if (mounted) {
          _showSettingsDialog();
        }
      }
    } catch (e, stack) {
      debugPrint('[ChillMsic Debug] Lỗi khi gửi yêu cầu xin quyền: $e');
      debugPrint(stack.toString());
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.hairlineSoft, width: 1.5),
          ),
          title: Text(
            context.tr('permission_denied_title'),
            style: AppTypography.subtitleLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.inkDeep),
          ),
          content: Text(
            context.tr('permission_denied_desc'),
            style: AppTypography.bodySm.copyWith(color: AppColors.charcoal, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () {
                debugPrint('[ChillMsic Debug] Người dùng bấm từ chối mở cài đặt');
                Navigator.pop(context);
              },
              child: Text(
                context.tr('permission_later'),
                style: AppTypography.bodySmBold.copyWith(color: AppColors.steel),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.canvas,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              onPressed: () {
                debugPrint('[ChillMsic Debug] Người dùng đồng ý, mở Cài đặt hệ thống.');
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text(
                context.tr('permission_open_settings'),
                style: AppTypography.bodySmBold.copyWith(color: AppColors.canvas),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // List of screens to display in IndexedStack to preserve scroll state
    final List<Widget> pages = [
      HomeMusicPage(),
      LibraryPage(
        onNavigateToDiscover: () {
          setState(() {
            _currentIndex = 0; // Switch to Discover tab
          });
        },
      ),
      SettingsPage(),
      AnalyticsPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          
          // Floating Mini Player (Sticky summary layout)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: _buildFloatingMiniPlayer(context),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.hairlineSoft, width: 1.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.canvas,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.steel,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: AppTypography.captionBold.copyWith(fontSize: 10, color: AppColors.primary),
          unselectedLabelStyle: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.steel),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: const Icon(Icons.explore),
              label: context.tr('explore'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_outline_rounded),
              activeIcon: const Icon(Icons.favorite_rounded),
              label: context.tr('library'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: context.tr('settings'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_outlined),
              activeIcon: const Icon(Icons.bar_chart_rounded),
              label: context.tr('listening_stats'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingMiniPlayer(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) =>
          prev.currentSong != curr.currentSong ||
          prev.playerState != curr.playerState ||
          prev.isDarkMode != curr.isDarkMode,
      builder: (context, playerState) {
        final song = playerState.currentSong;
        if (song == null || playerState.playerState == AudioPlayerState.idle) {
          return const SizedBox.shrink();
        }

        final isPlaying = playerState.playerState == AudioPlayerState.playing;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerPage()),
            );
          },
          child: Container(
            height: 72,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12), // Floating above bottom bar
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(100), // fully pill shaped
              border: Border.all(color: AppColors.hairlineSoft, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Stack(
                children: [
                  // Progress indicator bar at the bottom (isolated rebuilds & repaints)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: RepaintBoundary(
                      child: BlocBuilder<PlayerBloc, PlayerState>(
                        buildWhen: (prev, curr) =>
                            prev.position != curr.position ||
                            prev.duration != curr.duration,
                        builder: (context, progressState) {
                          final progress = progressState.duration.inMilliseconds > 0
                              ? progressState.position.inMilliseconds / progressState.duration.inMilliseconds
                              : 0.0;
                          return LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                            backgroundColor: AppColors.hairlineSoft,
                            minHeight: 3,
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Inside elements
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Cover artwork
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: ClipOval(
                            child: Image.network(
                              song.coverUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Text metadata (Fixed potential overflow using Expanded + ellipsis)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                song.title,
                                style: AppTypography.bodySmBold.copyWith(color: AppColors.inkDeep),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Controls
                        if (!isSmallScreen) ...[
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.skip_previous, color: AppColors.inkDeep),
                            onPressed: () {
                              context.read<PlayerBloc>().add(SkipPreviousEvent());
                            },
                          ),
                          const SizedBox(width: 12),
                        ],
                        MetaIconCircularButton(
                          icon: isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 40,
                          iconColor: AppColors.canvas,
                          backgroundColor: AppColors.inkDeep,
                          onPressed: () {
                            if (isPlaying) {
                              context.read<PlayerBloc>().add(PauseSongEvent());
                            } else {
                              context.read<PlayerBloc>().add(ResumeSongEvent());
                            }
                          },
                        ),
                        if (!isSmallScreen) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.skip_next, color: AppColors.inkDeep),
                            onPressed: () {
                              context.read<PlayerBloc>().add(SkipNextEvent());
                            },
                          ),
                        ],
                      ],
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
}
