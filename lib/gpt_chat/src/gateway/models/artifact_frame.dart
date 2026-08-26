/// Aspect ratio requested for a generated animation.
enum ArtifactFrame {
  square('square', 1),
  reels('reels', 9 / 16),
  landscape('landscape', 16 / 9);

  const ArtifactFrame(this.wireName, this.aspectRatio);

  final String wireName;
  final double aspectRatio;

  static ArtifactFrame fromWire(String? value) =>
      ArtifactFrame.values.firstWhere(
        (f) => f.wireName == value,
        orElse: () => ArtifactFrame.square,
      );
}
