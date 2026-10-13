import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final _favoriteProvider = StreamProvider.autoDispose.family<bool, int>(
  (ref, id) => DbService.isar.songs
      .watchObject(id, fireImmediately: true)
      .map((song) => song?.isFavorite ?? false),
);

class PlaylistFavoriteButton extends ConsumerWidget {
  const PlaylistFavoriteButton({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite =
        ref.watch(_favoriteProvider(song.id)).value ?? song.isFavorite;
    return IconButton(
      tooltip: context.l10n.toggleFavorite,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 36),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(
        LucideIcons.star300,
        size: 16,
        color: favorite
            ? Theme.of(context).colorScheme.primary
            : Colors.white.withValues(alpha: 0.5),
      ),
      onPressed: () {
        if (ref.read(playbackProvider).currentSong?.path == song.path) {
          ref.read(playbackProvider.notifier).toggleFavorite();
        } else {
          ref.read(libraryProvider.notifier).toggleFavorite(song);
        }
      },
    );
  }
}
