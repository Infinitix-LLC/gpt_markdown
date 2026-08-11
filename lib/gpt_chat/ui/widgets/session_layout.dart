import 'package:flutter/material.dart';

/// Shared metrics for the default chat layout.
///
/// The app bar and composer float over the transcript, so the transcript pads
/// itself by these amounts instead of being squeezed between them. That is what
/// lets content scroll *under* the bars rather than being clipped by them.
abstract final class SessionLayout {
  /// Reading width for messages. Prose past this gets hard to scan.
  static const double contentMaxWidth = 680;

  /// Composer width, slightly wider than the text it sits under.
  static const double composerMaxWidth = 700;

  /// Height of the floating app bar.
  static const double appBarHeight = 72;

  /// Space kept clear at the bottom of the transcript for the composer.
  static const double composerReserve = 130;

  /// Centres [child] and caps it at [contentMaxWidth].
  static Widget constrain(Widget child, {double? maxWidth}) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? contentMaxWidth),
        child: child,
      ),
    );
  }
}
