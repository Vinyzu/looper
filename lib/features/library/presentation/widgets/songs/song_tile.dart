import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/common/highlighted_text.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/sheets/song_options_bottom_sheet.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/features/search/domain/lyric_snippet.dart'
    as search
    show lyricSnippet;

class SongTile extends ConsumerWidget {
  final Song song;
  final List<Song> songs;
  final AppLocalizations l10n;
  final String? searchQuery;
  final Playlist? playlist;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onEnterSelection;
  // Non-null only when this tile is rendered inside a SliverReorderableList
  // (a playlist showing its own saved order) - its presence is what decides
  // whether the drag-handle grip icon shows up at all.
  final int? reorderIndex;
  // Search-only extras: highlight the [searchQuery] match in the title, and
  // get told when a tap starts playback (not when it toggles a selection).
  final bool highlightTitle;
  final VoidCallback? onPlay;

  const SongTile({
    required this.song,
    required this.songs,
    required this.l10n,
    this.searchQuery,
    this.playlist,
    this.selectionMode = false,
    this.selected = false,
    this.onToggleSelect,
    this.onEnterSelection,
    this.reorderIndex,
    this.highlightTitle = false,
    this.onPlay,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(
      playbackProvider.select((s) => s.currentSong?.path == song.path),
    );
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));

    String? lyricSnippet;
    if (searchQuery != null && searchQuery!.isNotEmpty && song.lyrics != null) {
      lyricSnippet = search.lyricSnippet(song.lyrics!, searchQuery!);
    }

    final artistLink = InkWell(
      onTap: () async {
        if (song.artist != null) {
          final artistSongs = await DbService.isar.songs
              .filter()
              .artistEqualTo(song.artist!)
              .findAll();
          final artist = await DbService.isar.artists
              .filter()
              .nameEqualTo(song.artist!)
              .findFirst();
          ref
              .read(appNavigationProvider.notifier)
              .showCollection(
                title: song.artist!,
                subtitle: l10n.artists,
                art: artist?.artPath ?? song.artPath,
                imageUrl: artist?.artistImageUrl,
                songs: artistSongs,
              );
        }
      },
      child: Text(
        song.artist ?? l10n.unknownArtist,
        style: AppFonts.jostStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: _SongTileBouncyTap(
        onTap: () {
          if (selectionMode) {
            onToggleSelect?.call();
            return;
          }
          onPlay?.call();
          final index = songs.indexWhere((s) => s.path == song.path);
          if (index != -1) {
            ref
                .read(playbackProvider.notifier)
                .setPlaylist(
                  songs,
                  initialIndex: index,
                  sourcePlaylistId: playlist?.id,
                );
          } else {
            ref
                .read(playbackProvider.notifier)
                .play(song, sourcePlaylistId: playlist?.id);
          }
        },
        // A long-press on any row starts a selection (with that row already
        // checked) instead of requiring a separate "select" mode button -
        // there's nowhere else in this list a batch action could live.
        onLongPress: selectionMode ? null : onEnterSelection,
        child: ListTile(
          contentPadding: const EdgeInsets.only(
            left: 16,
            right: 4,
            top: 0,
            bottom: 0,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                isCurrent
                    ? Stack(
                        children: [
                          OptimizedImage(
                            imagePath: song.artPath,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                          Positioned.fill(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: isPlaying ? 1.0 : 0.0,
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.4),
                                child: Center(
                                  // Animated GIF frame decoding doesn't respect
                                  // TickerMode - an Image.asset(.gif) keeps
                                  // ticking on its own Timer even while offstage
                                  // (e.g. this tab sitting inactive behind
                                  // another one - see AndroidMainScreen). Skip
                                  // mounting it entirely while offstage, where
                                  // it wouldn't be visible anyway.
                                  child: TickerMode.of(context)
                                      ? Image.asset(
                                          AppAssets.playingGif,
                                          width: 24,
                                          height: 24,
                                          color: Colors.white,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : OptimizedImage(
                        imagePath: song.artPath,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                if (selectionMode)
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutCubic,
                      color: selected
                          ? Colors.black.withValues(alpha: 0.35)
                          : Colors.transparent,
                      child: selected
                          ? Icon(
                              LucideIcons.checkCircle2,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          title: highlightTitle && !isCurrent
              ? highlightedText(
                  text: song.title,
                  query: searchQuery ?? '',
                  baseStyle: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  highlightStyle: AppFonts.jostStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Text(
                  song.title,
                  style: AppFonts.jostStyle(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          subtitle: lyricSnippet != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    artistLink,
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.quote,
                            size: 9,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: highlightedText(
                              text: lyricSnippet,
                              query: searchQuery ?? '',
                              baseStyle: AppFonts.jostStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                              highlightStyle: AppFonts.jostStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : artistLink,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reorderIndex != null)
                ReorderableDragStartListener(
                  index: reorderIndex!,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      LucideIcons.gripVertical,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () => showSongOptionsBottomSheet(
                  context: context,
                  ref: ref,
                  song: song,
                  playlist: playlist,
                  showEqualizerAndTechnicalInfoOptions: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongTileBouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _SongTileBouncyTap({
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_SongTileBouncyTap> createState() => _SongTileBouncyTapState();
}

class _SongTileBouncyTapState extends State<_SongTileBouncyTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              AppHaptics.medium();
              widget.onLongPress!();
            },
      behavior: HitTestBehavior.opaque,
      // ScaleTransition builds a Transform, which always needs its own
      // compositing layer whenever it has a child -- even sitting still at
      // scale 1.0. With a long list of these tiles that's a permanent extra
      // layer per visible row for the ~99% of the time nothing's being
      // pressed, on top of the churn of allocating one per tile as
      // ListView.builder recycles rows during a fling. Only pay for that
      // layer while the press animation is actually running; otherwise
      // render the row directly with no Transform at all.
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.value == 0.0) return child!;
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
