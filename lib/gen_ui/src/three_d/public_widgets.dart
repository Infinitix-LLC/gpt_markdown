part of 'gen_ui_3d_graphs.dart';

/// App-wide wiring for the 3D gen-UI widgets.
///
/// `Val3DView` creates its own renderer when given none, but doing that during
/// the first widget frame races the platform's Impeller / WebGL2 context. The
/// gen-UI graphs are built deep inside a markdown document, far from anything
/// the host app constructs, so the renderer is set once here instead of being
/// threaded through every call site.
///
/// Call [ensureInitialized] before `runApp`:
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await GenUi3D.ensureInitialized();
///   runApp(const App());
/// }
/// ```
///
/// Skipping it still renders — each view just falls back to its own renderer.
/// Each platform additionally needs the Flutter GPU flag from val_3d's
/// `SETUP.md`; without it the view shows "3D renderer unavailable".
abstract final class GenUi3D {
  /// Renderer handed to every [Val3DView] built by these widgets, unless the
  /// widget was given one explicitly.
  static Renderer? defaultRenderer;

  /// Creates and initializes the platform default renderer, storing it in
  /// [defaultRenderer]. Safe to call more than once — later calls reuse the
  /// renderer created by the first.
  ///
  /// Returns null if initialization failed, in which case the widgets fall
  /// back to per-view renderers and val_3d reports the failure in the view.
  static Future<Renderer?> ensureInitialized() async {
    final existing = defaultRenderer;
    if (existing != null) {
      return existing;
    }

    final renderer = createDefaultRenderer();
    try {
      await renderer.initialize();
    } on Object {
      return null;
    }
    return defaultRenderer = renderer;
  }
}

/// `surface_3d`: explicit Cartesian surface, `z = f(x, y)`.
class GenSurface3DGraph extends StatelessWidget {
  const GenSurface3DGraph({super.key, required this.attributes, this.renderer});

  final Map<String, dynamic> attributes;

  /// Overrides [GenUi3D.defaultRenderer] for this graph.
  final Renderer? renderer;

  @override
  Widget build(BuildContext context) {
    return _Gen3DGraphCard(
      attributes: attributes,
      kind: _Gen3DGraphKind.surface,
      renderer: renderer,
    );
  }
}

/// `polar_surface_3d`: polar surface, `z = f(radius, theta)`.
class GenPolarSurface3DGraph extends StatelessWidget {
  const GenPolarSurface3DGraph({
    super.key,
    required this.attributes,
    this.renderer,
  });

  final Map<String, dynamic> attributes;

  /// Overrides [GenUi3D.defaultRenderer] for this graph.
  final Renderer? renderer;

  @override
  Widget build(BuildContext context) {
    return _Gen3DGraphCard(
      attributes: attributes,
      kind: _Gen3DGraphKind.polar,
      renderer: renderer,
    );
  }
}

/// `spherical_surface_3d`: spherical surface, `radius = f(theta, phi)`.
class GenSphericalSurface3DGraph extends StatelessWidget {
  const GenSphericalSurface3DGraph({
    super.key,
    required this.attributes,
    this.renderer,
  });

  final Map<String, dynamic> attributes;

  /// Overrides [GenUi3D.defaultRenderer] for this graph.
  final Renderer? renderer;

  @override
  Widget build(BuildContext context) {
    return _Gen3DGraphCard(
      attributes: attributes,
      kind: _Gen3DGraphKind.spherical,
      renderer: renderer,
    );
  }
}

/// `cylindrical_surface_3d`: cylindrical surface, `radius = f(theta, z)`.
class GenCylindricalSurface3DGraph extends StatelessWidget {
  const GenCylindricalSurface3DGraph({
    super.key,
    required this.attributes,
    this.renderer,
  });

  final Map<String, dynamic> attributes;

  /// Overrides [GenUi3D.defaultRenderer] for this graph.
  final Renderer? renderer;

  @override
  Widget build(BuildContext context) {
    return _Gen3DGraphCard(
      attributes: attributes,
      kind: _Gen3DGraphKind.cylindrical,
      renderer: renderer,
    );
  }
}

enum _Gen3DGraphKind { surface, polar, spherical, cylindrical }
