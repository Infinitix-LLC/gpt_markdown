/// Interpolation helpers shared by the style classes.
library;

/// Interpolates between two optional doubles.
///
/// Returns null only when both ends are null, so a style that sets a value on
/// one side of the interpolation keeps it rather than snapping to nothing.
double? lerpDouble(double? a, double? b, double t) {
  if (a == null && b == null) {
    return null;
  }
  final start = a ?? b;
  final end = b ?? a;
  if (start == null || end == null) {
    return null;
  }
  return start + (end - start) * t;
}
