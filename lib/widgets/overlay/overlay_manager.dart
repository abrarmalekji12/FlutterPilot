import 'package:flutter/material.dart';

class OverlayConfig {
  final OverlayEntry overlayEntry;
  final List<ScrollController>? scrollable;

  OverlayConfig({
    required this.overlayEntry,
    required this.scrollable,
  });
}

mixin OverlayManager<T extends State> {
  final Map<String, OverlayConfig> overlays = {};

  EdgeInsets _getPosition(GlobalKey areaKey) {
    final pos = (areaKey.currentContext!.findRenderObject() as RenderBox)
        .localToGlobal(Offset.zero);
    return EdgeInsets.only(left: pos.dx, top: pos.dy);
  }

  void rebuild(String key) {
    overlays[key]?.overlayEntry.markNeedsBuild();
  }

  void showOverlay(
      BuildContext context, String key, Function(BuildContext, Offset) widget,
      {GlobalKey? areaKey,
      List<ScrollController>? scrollWith,
      bool dismissible = false,
      VoidCallback? onRemove,
      OverlayState? overlay}) {
    final overlayEntry = OverlayEntry(builder: (context) {
      final padding = areaKey != null ? _getPosition(areaKey) : EdgeInsets.zero;
      return Stack(
        children: [
          if (dismissible)
            Positioned.fill(
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          widget.call(
            context,
            Offset(padding.left, padding.top),
          ),
        ],
      );
    });
    if (overlays.containsKey(key)) {
      removeOverlay(key);
    }
    final config =
        OverlayConfig(overlayEntry: overlayEntry, scrollable: scrollWith);
    overlays[key] = config;
    (overlay ?? Overlay.of(context, rootOverlay: true)).insert(overlayEntry);
    if (scrollWith != null) {
      for (final controller in scrollWith) {
        controller.addListener(overlayEntry.markNeedsBuild);
      }
    }
  }

  void removeOverlay(String key) {
    final overlay = overlays.remove(key);
    if (overlay?.overlayEntry.mounted ?? false) {
      if (overlay?.scrollable != null) {
        for (final scroll in overlay!.scrollable!) {
          scroll.removeListener(overlay.overlayEntry.markNeedsBuild);
        }
      }
      overlay?.overlayEntry.remove();
    }
  }

  void destroyOverlays() {
    final list = overlays.entries.toList();
    for (final overlay in list) {
      overlay.value.overlayEntry.remove();
      overlays.remove(overlay.key);
    }
  }
}
