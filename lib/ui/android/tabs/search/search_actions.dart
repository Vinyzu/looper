part of 'android_search_tab.dart';

/// Every song [artistName] is credited on: their own, shared ones, and ones
/// where they are a featured guest on someone else's track.
Future<List<Song>> _songsCrediting(String artistName) async {
  final candidates = await DbService.isar.songs
      .filter()
      .artistContains(artistName, caseSensitive: false)
      .or()
      .titleContains(artistName, caseSensitive: false)
      .findAll();
  final credited = candidates
      .where((song) => songCreditsArtist(song, artistName))
      .toList();
  if (credited.isNotEmpty) return credited;
  // A tag the credit splitter can't read still gets the exact-tag match the
  // rest of the app uses, rather than an empty page.
  return DbService.isar.songs.filter().artistEqualTo(artistName).findAll();
}

Future<void> _openArtist(
  WidgetRef ref,
  AppLocalizations l10n,
  Artist artist,
) async {
  final navigation = ref.read(appNavigationProvider.notifier);
  final songs = await _songsCrediting(artist.name);
  navigation.showCollection(
    title: artist.name,
    subtitle: l10n.artist,
    songs: songs,
    art: artist.artPath,
  );
}

Future<void> _openAlbum(WidgetRef ref, AppLocalizations l10n, Album album) =>
    ref
        .read(appNavigationProvider.notifier)
        .showAlbum(album, unknownArtist: l10n.unknownArtist);

Future<void> _openPlaylist(
  WidgetRef ref,
  AppLocalizations l10n,
  Playlist playlist,
) async {
  final navigation = ref.read(appNavigationProvider.notifier);
  final songs = await DbService.isar.songs
      .filter()
      .anyOf(playlist.songPaths, (q, path) => q.pathEqualTo(path))
      .findAll();
  // Keep the playlist's own order, as the Playlists screen does.
  final songMap = {for (final s in songs) s.path: s};
  navigation.showCollection(
    title: playlist.name,
    subtitle: l10n.playlist,
    songs: playlist.songPaths
        .map((path) => songMap[path])
        .whereType<Song>()
        .toList(),
    playlist: playlist,
  );
}

Future<void> _openGenre(
  WidgetRef ref,
  AppLocalizations l10n,
  String genre,
) async {
  final navigation = ref.read(appNavigationProvider.notifier);
  final songs = await DbService.isar.songs
      .filter()
      .genreEqualTo(genre, caseSensitive: false)
      .findAll();
  if (songs.isEmpty) return;
  final withArt = songs.firstWhere(
    (s) => s.artPath != null,
    orElse: () => songs.first,
  );
  navigation.showCollection(
    title: genre,
    subtitle: l10n.genre,
    art: withArt.artPath,
    songs: songs,
  );
}

/// Asks which playlist [songs] should go to - an existing one or a new one,
/// whose name starts out as [suggestedName] - and adds them. Returns the
/// playlist's name, or null if the user backed out.
Future<String?> _addSongsToPlaylist(
  BuildContext context,
  WidgetRef ref,
  List<Song> songs, {
  required String suggestedName,
}) async {
  final l10n = context.l10n;
  final playlists = ref.read(playlistProvider);
  const createNew = Object();
  final choice = await showDialog<Object>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        title: Text(l10n.addToPlaylists),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: Icon(LucideIcons.plus, color: colorScheme.primary),
                title: Text(l10n.newPlaylist),
                onTap: () => Navigator.pop(dialogContext, createNew),
              ),
              for (final playlist in playlists)
                ListTile(
                  leading: const Icon(LucideIcons.listMusic),
                  title: Text(playlist.name),
                  subtitle: Text(l10n.songsCount(playlist.songPaths.length)),
                  onTap: () => Navigator.pop(dialogContext, playlist),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      );
    },
  );
  if (choice == null || !context.mounted) return null;

  if (choice is Playlist) {
    await PlaylistService.addSongsToPlaylist(choice, songs);
    return choice.name;
  }

  final controller = TextEditingController(text: suggestedName);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: suggestedName.length,
  );
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      void submit() {
        final name = controller.text.trim();
        if (name.isNotEmpty) Navigator.pop(dialogContext, name);
      }

      return AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surfaceContainer,
        title: Text(l10n.newPlaylist),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => submit(),
          decoration: InputDecoration(hintText: l10n.playlistNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(onPressed: submit, child: Text(l10n.create)),
        ],
      );
    },
  );
  if (name == null) return null;
  // Playlist names are unique, so "new" with a name already in use adds to
  // that playlist instead of failing.
  final sameName = playlists.where((p) => p.name == name).firstOrNull;
  if (sameName != null) {
    await PlaylistService.addSongsToPlaylist(sameName, songs);
  } else {
    await PlaylistService.createWithSongs(name, songs);
  }
  return name;
}
