part of 'collection_detail_view.dart';

extension _CollectionHeader on CollectionDetailView {
  Widget _buildArt(
    BuildContext context,
    bool isNarrow,
    String? artOverride, {
    Playlist? playlist,
  }) {
    final double size = 140; // Unified size for a cleaner Row look
    if (playlist != null) {
      return PlaylistArtwork(
        songPaths: playlist.songPaths,
        size: size,
        borderRadius: BorderRadius.circular(16),
      );
    }
    return OptimizedImage(
      imagePath: artOverride,
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(16),
      placeholder: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.music, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfo(
    BuildContext context,
    WidgetRef ref,
    bool isNarrow,
    String? activeArtworkPath,
    Playlist? reactivePlaylist,
    Album? reactiveAlbum,
    String titleToRender,
    String? subtitleToRender,
    List<Song> songsToRender,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isShuffle = ref.watch(playbackProvider.select((s) => s.isShuffle));
    final subtitle = reactivePlaylist != null
        ? _playlistSubtitle(songsToRender, l10n)
        : subtitleToRender;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleToRender,
          style: AppFonts.jostStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppFonts.jostStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            PremiumSection(
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 44,
              useExpanded: false,
              onTap: () {
                AppHaptics.medium();
                final playback = ref.read(playbackProvider.notifier);
                if (reactivePlaylist != null) {
                  playback.playCollection(songsToRender);
                } else {
                  playback.setPlaylist(songsToRender);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    reactivePlaylist != null ? l10n.play : l10n.playAll,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PremiumSection(
              borderRadius: BorderRadius.circular(12),
              width: 44,
              height: 44,
              useExpanded: false,
              onTap: () {
                AppHaptics.light();
                ref
                    .read(playbackProvider.notifier)
                    .toggleCollectionShuffle(songsToRender);
              },
              child: Semantics(
                label: l10n.shuffleTitle,
                toggled: isShuffle,
                child: Icon(
                  LucideIcons.shuffle,
                  size: 16,
                  color: isShuffle
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PremiumSection(
              borderRadius: BorderRadius.circular(12),
              width: 44,
              height: 44,
              useExpanded: false,
              onTap: () {
                AppHaptics.light();
                _showSortBottomSheet(context, ref);
              },
              child: const Icon(
                LucideIcons.arrowUpDown,
                size: 16,
                color: Colors.white,
              ),
            ),
            if (reactivePlaylist != null) ...[
              const SizedBox(width: 8),
              PremiumSection(
                borderRadius: BorderRadius.circular(12),
                width: 44,
                height: 44,
                useExpanded: false,
                onTap: () =>
                    _showPlaylistOptions(context, ref, reactivePlaylist),
                child: const Icon(
                  LucideIcons.moreHorizontal,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ] else if (reactiveAlbum != null) ...[
              const SizedBox(width: 8),
              PremiumSection(
                borderRadius: BorderRadius.circular(12),
                width: 44,
                height: 44,
                useExpanded: false,
                onTap: () {
                  AppHaptics.light();
                  _showEditAlbumSheet(context, ref, reactiveAlbum);
                },
                child: const Icon(
                  LucideIcons.edit2,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
