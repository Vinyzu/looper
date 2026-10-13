import 'dart:async';

import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PlaylistScrollToEnd extends StatefulWidget {
  const PlaylistScrollToEnd({
    super.key,
    required this.builder,
    this.enabled = true,
    this.bottomPadding = 16,
  });

  final Widget Function(ScrollController controller) builder;
  final bool enabled;
  final double bottomPadding;

  @override
  State<PlaylistScrollToEnd> createState() => _PlaylistScrollToEndState();
}

class _PlaylistScrollToEndState extends State<PlaylistScrollToEnd> {
  final _controller = ScrollController();
  final _visible = ValueNotifier(false);
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _visible.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (!widget.enabled || notification.depth != 0) return false;
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      _visible.value =
          metrics.pixels > 0 &&
          metrics.maxScrollExtent - metrics.pixels > metrics.viewportDimension;
      _hideTimer?.cancel();
      _hideTimer = Timer(
        const Duration(milliseconds: 1400),
        () => _visible.value = false,
      );
    }
    return false;
  }

  void _scrollToEnd() {
    _hideTimer?.cancel();
    _visible.value = false;
    // Skip building and decoding artwork for every intermediate row.
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Stack(
          children: [
            Positioned.fill(child: widget.builder(_controller)),
            PositionedDirectional(
              end: 16,
              bottom: widget.bottomPadding,
              child: ValueListenableBuilder<bool>(
                valueListenable: _visible,
                builder: (context, visible, _) => visible && widget.enabled
                    ? IconButton.filled(
                        tooltip: context.l10n.scrollToEnd,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF181818),
                          foregroundColor: Colors.white.withValues(alpha: 0.5),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        onPressed: _scrollToEnd,
                        icon: const Icon(LucideIcons.chevronsDown, size: 18),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      );
}
