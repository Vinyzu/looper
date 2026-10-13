import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_assets.dart';

class SongPlaybackOverlay extends StatelessWidget {
  const SongPlaybackOverlay({super.key, required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black.withValues(alpha: 0.4),
    child: Center(
      // A GIF keeps decoding offstage and while paused, so only mount it when
      // the row is visible and playback is active.
      child: isPlaying && TickerMode.of(context)
          ? Image.asset(
              AppAssets.playingGif,
              width: 24,
              height: 24,
              color: Colors.white,
            )
          : SizedBox(
              width: 24,
              height: 24,
              // Match the GIF's four columns and baseline, flattened while paused.
              child: Padding(
                padding: const EdgeInsets.only(top: 5.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 0.8,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: 2.2,
                        height: 2.2,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(1.1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    ),
  );
}
