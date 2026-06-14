import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/entities/song.dart';
import '../bloc/player_bloc.dart';

class QueueDrawer extends StatelessWidget {
  const QueueDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) =>
          prev.queue != curr.queue ||
          prev.currentSong != curr.currentSong ||
          prev.isDarkMode != curr.isDarkMode,
      builder: (context, state) {
        final currentSong = state.currentSong;
        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        final queue = state.queue;
        final currentIndex = queue.indexWhere((s) => s.id == currentSong.id);
        
        final List<Song> nextSongs = currentIndex != -1 && currentIndex < queue.length - 1
            ? queue.sublist(currentIndex + 1)
            : [];

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.canvas.withAlpha(state.isDarkMode ? 200 : 230),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: AppColors.hairlineSoft.withAlpha(state.isDarkMode ? 80 : 30),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Center drag indicator handle
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
                  const SizedBox(height: 16),
                  
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DANH SÁCH PHÁT',
                            style: AppTypography.headingSm.copyWith(
                              color: AppColors.inkDeep,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${queue.length} bài hát trong hàng đợi',
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
                          'TIẾP THEO',
                          style: AppTypography.captionBold.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Currently Playing Section
                  Text(
                    'Đang phát',
                    style: AppTypography.bodySmBold.copyWith(color: AppColors.slate),
                  ),
                  const SizedBox(height: 8),
                  _buildSongTile(context, currentSong, isCurrent: true),
                  const SizedBox(height: 16),

                  // Next Up Header
                  Text(
                    'Tiếp theo',
                    style: AppTypography.bodySmBold.copyWith(color: AppColors.slate),
                  ),
                  const SizedBox(height: 8),

                  // Next Up List
                  Expanded(
                    child: nextSongs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Hết bài hát trong hàng đợi',
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.charcoal,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        : Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.transparent,
                            ),
                            child: ReorderableListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: nextSongs.length,
                              onReorderItem: (oldIdx, newIdx) {
                                final List<Song> updatedQueue = List.from(queue);
                                final targetIdx = currentIndex + 1 + oldIdx;
                                final destIdx = currentIndex + 1 + newIdx;

                                final Song item = updatedQueue.removeAt(targetIdx);
                                updatedQueue.insert(destIdx, item);

                                context.read<PlayerBloc>().add(UpdateQueueEvent(updatedQueue));
                              },
                              itemBuilder: (context, index) {
                                final song = nextSongs[index];
                                return Dismissible(
                                  key: ValueKey('dismiss_${song.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.criticalStrong.withAlpha(50),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.delete_sweep_rounded,
                                      color: AppColors.criticalStrong,
                                    ),
                                  ),
                                  onDismissed: (direction) {
                                    final List<Song> updatedQueue = List.from(queue);
                                    final targetIdx = currentIndex + 1 + index;
                                    updatedQueue.removeAt(targetIdx);
                                    context.read<PlayerBloc>().add(UpdateQueueEvent(updatedQueue));

                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đã xóa "${song.title}" khỏi hàng đợi'),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    key: ValueKey('tile_${song.id}'),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildSongTile(context, song, isCurrent: false),
                                        ),
                                        const SizedBox(width: 8),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Icon(
                                            Icons.drag_indicator_rounded,
                                            color: AppColors.steel,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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

  Widget _buildSongTile(BuildContext context, Song song, {required bool isCurrent}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primarySoft.withAlpha(150) : AppColors.surfaceSoft.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.primary.withAlpha(100) : AppColors.hairlineSoft.withAlpha(80),
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Cover artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              song.coverUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          
          // Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  song.title,
                  style: AppTypography.bodySmBold.copyWith(
                    color: isCurrent ? AppColors.primary : AppColors.inkDeep,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          if (isCurrent) ...[
            const SizedBox(width: 8),
            // Playing indicator icon or text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ĐANG PHÁT',
                style: AppTypography.captionBold.copyWith(color: Colors.white, fontSize: 8),
              ),
            ),
          ] else ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.play_arrow_rounded, color: AppColors.primary),
              onPressed: () {
                // If clicked, play this song from the queue immediately
                context.read<PlayerBloc>().add(PlaySongEvent(
                  song: song,
                  queue: context.read<PlayerBloc>().state.queue,
                ));
              },
            ),
          ],
        ],
      ),
    );
  }
}
