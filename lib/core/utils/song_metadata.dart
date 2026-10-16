import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/l10n/app_localizations.dart';

String artistAlbumLabel(Song song, AppLocalizations l10n) {
  final artist = song.artist?.trim();
  final album = song.album?.trim();
  return '${artist == null || artist.isEmpty ? l10n.unknownArtist : artist} • '
      '${album == null || album.isEmpty ? l10n.unknownAlbum : album}';
}
