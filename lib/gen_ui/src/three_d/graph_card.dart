part of 'gen_ui_3d_graphs.dart';

class _Gen3DGraphCard extends StatefulWidget {
  const _Gen3DGraphCard({
    required this.attributes,
    required this.kind,
    this.renderer,
  });

  final Map<String, dynamic> attributes;
  final _Gen3DGraphKind kind;
  final Renderer? renderer;

  @override
  State<_Gen3DGraphCard> createState() => _Gen3DGraphCardState();
}

class _Gen3DGraphCardState extends State<_Gen3DGraphCard> {
  late Scene3D _scene;
  late List<_GraphConstant> _constants;
  late List<_GraphFormula> _formulas;
  late Map<String, double> _constantValues;
  bool _rotationEnabled = true;

  @override
  void initState() {
    super.initState();
    _constants = _constantsFromValue(widget.attributes['constants']);
    _formulas = _formulasFromValue(widget.attributes['formula']);
    _constantValues = _initialConstantValues(_constants);
    _scene = _buildScene();
  }

  @override
  void didUpdateWidget(covariant _Gen3DGraphCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attributes != widget.attributes ||
        oldWidget.kind != widget.kind) {
      _constants = _constantsFromValue(widget.attributes['constants']);
      _formulas = _formulasFromValue(widget.attributes['formula']);
      _constantValues = _initialConstantValues(_constants);
      _scene = _buildScene();
    }
  }

  Scene3D _buildScene({_CameraView? cameraView}) {
    final attributes = widget.attributes;
    final scene = Scene3D(
      lights: LightSetup(
        ambientColor: const LightColor(0.18, 0.18, 0.22),
        directionalColor: const LightColor(0.95, 0.92, 0.86),
        directionalDirection: vm.Vector3(0.35, 0.55, -0.65),
      ),
    );

    Scene3DSpace.configureDefaultCamera(
      scene.camera,
      target: _vectorFromValue(attributes['target']) ?? vm.Vector3.zero(),
      distance: _doubleFromValue(attributes['distance']) ?? 6.2,
    );
    scene.camera.phi = _doubleFromValue(attributes['phi']) ?? 1.08;
    scene.camera.theta = _doubleFromValue(attributes['theta']) ?? -2.22;
    scene.camera.fovY = _doubleFromValue(attributes['fovY']) ?? math.pi / 4.6;
    cameraView?.applyTo(scene.camera);

    final graphMesh = _meshForKind(widget.kind, attributes);
    if (graphMesh == null || graphMesh.vertexCount == 0) {
      return scene;
    }

    final wireframe = _wireframeFromValue(attributes['wireframe']);
    final graphColors = _colorsFromValue(
      attributes['colors'],
      fallback: const [
        Color(0xFF2255FF),
        Color(0xFF22DDAA),
        Color(0xFFFFFF66),
      ],
    );

    scene.add(
      SceneNode(
        id: 'gen-ui-3d-graph',
        mesh: graphMesh,
        style: RenderStyle(
          material: LinearGradientMaterial(
            axis: _gradientAxisFromValue(attributes['axis']),
            colors: graphColors,
            opacity: (_doubleFromValue(attributes['opacity']) ?? 0.96)
                .clamp(0.0, 1.0),
          ),
          strokeColor: _colorFromValue(
            attributes['strokeColor'],
            fallback: const Color(0xAAFFFFFF),
          ),
          wireframe: wireframe,
          surfaceMesh: attributes['surfaceMesh'] != false,
          shading: ShadingMode.smooth,
          doubleSided: attributes['doubleSided'] != false,
        ),
      ),
    );

    if (attributes['showAxes'] != false) {
      _addAxes(
        scene,
        length: _doubleFromValue(attributes['axesLength']) ?? 2.2,
      );
    }

    return scene;
  }

  Mesh? _meshForKind(_Gen3DGraphKind kind, Map<String, dynamic> attributes) {
    return switch (kind) {
      _Gen3DGraphKind.surface => buildSurface(
          fn: _surfaceFnFromValue(
            _formulaValue(attributes),
            _constants,
            _constantValues,
          ),
          xMin: _doubleAttribute(attributes['xMin']) ?? -1.6,
          xMax: _doubleAttribute(attributes['xMax']) ?? 1.6,
          yMin: _doubleAttribute(attributes['yMin']) ?? -1.6,
          yMax: _doubleAttribute(attributes['yMax']) ?? 1.6,
          zMin: _doubleAttribute(attributes['zMin']),
          zMax: _doubleAttribute(attributes['zMax']),
          uSteps: _stepsFromValue(attributes['uSteps']) ?? 32,
          vSteps: _stepsFromValue(attributes['vSteps']) ?? 32,
        ),
      _Gen3DGraphKind.polar => buildPolarSurface(
          fn: _polarSurfaceFnFromValue(
            _formulaValue(attributes),
            _constants,
            _constantValues,
          ),
          radiusMin: _doubleAttribute(attributes['radiusMin']) ?? 0,
          radiusMax: _doubleAttribute(attributes['radiusMax']) ?? 1.5,
          thetaMin: _angleFromValue(attributes['thetaMin']) ?? 0,
          thetaMax: _angleFromValue(attributes['thetaMax']) ?? math.pi * 2,
          zMin: _doubleAttribute(attributes['zMin']),
          zMax: _doubleAttribute(attributes['zMax']),
          radiusSteps: _stepsFromValue(attributes['radiusSteps']) ?? 28,
          thetaSteps: _stepsFromValue(attributes['thetaSteps']) ?? 64,
        ),
      _Gen3DGraphKind.spherical => buildSphericalSurface(
          radiusFn: _sphericalSurfaceFnFromValue(
            _formulaValue(attributes),
            _constants,
            _constantValues,
          ),
          thetaMin: _angleFromValue(attributes['thetaMin']) ?? 0,
          thetaMax: _angleFromValue(attributes['thetaMax']) ?? math.pi * 2,
          phiMin: _angleFromValue(attributes['phiMin']) ?? 0,
          phiMax: _angleFromValue(attributes['phiMax']) ?? math.pi,
          radiusMin: _doubleAttribute(attributes['radiusMin']),
          radiusMax: _doubleAttribute(attributes['radiusMax']),
          thetaSteps: _stepsFromValue(attributes['thetaSteps']) ?? 56,
          phiSteps: _stepsFromValue(attributes['phiSteps']) ?? 28,
        ),
      _Gen3DGraphKind.cylindrical => buildCylindricalSurface(
          radiusFn: _cylindricalSurfaceFnFromValue(
            _formulaValue(attributes),
            _constants,
            _constantValues,
          ),
          thetaMin: _angleFromValue(attributes['thetaMin']) ?? 0,
          thetaMax: _angleFromValue(attributes['thetaMax']) ?? math.pi * 2,
          zMin: _doubleAttribute(attributes['zMin']) ?? -1.2,
          zMax: _doubleAttribute(attributes['zMax']) ?? 1.2,
          radiusMin: _doubleAttribute(attributes['radiusMin']),
          radiusMax: _doubleAttribute(attributes['radiusMax']),
          thetaSteps: _stepsFromValue(attributes['thetaSteps']) ?? 56,
          zSteps: _stepsFromValue(attributes['zSteps']) ?? 32,
        ),
    };
  }

  double? _doubleAttribute(dynamic value) {
    return _doubleFromValue(value) ??
        _constantExpressionValue(value, _constants, _constantValues);
  }

  void _orbit(double dx, double dy) {
    if (!_rotationEnabled) {
      return;
    }

    _scene.camera.orbit(deltaTheta: dx, deltaPhi: dy);
    _scene.markNeedsRender();
  }

  void _zoom(double factor) {
    _scene.camera.distance =
        (_scene.camera.distance * factor).clamp(1.2, 24.0).toDouble();
    _scene.markNeedsRender();
  }

  void _toggleRotation() {
    setState(() {
      _rotationEnabled = !_rotationEnabled;
    });
  }

  void _resetCamera() {
    setState(() {
      _scene = _buildScene();
    });
  }

  void _setConstantValue(_GraphConstant constant, double value) {
    final cameraView = _CameraView.from(_scene.camera);
    setState(() {
      _constantValues[constant.name] = constant.clampValue(value);
      _scene = _buildScene(cameraView: cameraView);
    });
  }

  Widget _buildConstantSlider(BuildContext context, _GraphConstant constant) {
    final theme = Theme.of(context);
    final value = constant.clampValue(
      _constantValues[constant.name] ?? constant.value,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  constant.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  _formatSliderValue(value),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GenUiSlider(
            min: constant.min,
            max: constant.max,
            value: value,
            divisions: constant.divisions,
            label: _formatSliderValue(value),
            onChanged: (nextValue) => _setConstantValue(constant, nextValue),
          ),
          Padding(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Text(
                  _formatSliderValue(constant.min),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatSliderValue(constant.max),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = true,
  }) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox(
          height: 36,
          width: 36,
          child: Icon(
            icon,
            color: isActive
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.42),
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildZoomButton(
            context: context,
            icon: Icons.zoom_in_rounded,
            tooltip: 'Zoom in',
            onTap: () => _zoom(0.86),
          ),
          Container(
            height: 20,
            width: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
          ),
          _buildZoomButton(
            context: context,
            icon: Icons.zoom_out_rounded,
            tooltip: 'Zoom out',
            onTap: () => _zoom(1.16),
          ),
          Container(
            height: 20,
            width: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
          ),
          _buildZoomButton(
            context: context,
            icon: Icons.threed_rotation,
            tooltip: _rotationEnabled ? 'Disable rotation' : 'Enable rotation',
            onTap: _toggleRotation,
            isActive: _rotationEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaValue(BuildContext context, _GraphFormula formula) {
    final theme = Theme.of(context);
    final value = _constantExpressionValue(
      formula.expression,
      _constants,
      _constantValues,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DefaultTextStyle.merge(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              child: GenUiMath.tex(formula.latex),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.35)),
            ),
            child: Text(
              value == null ? 'N/A' : _formatSliderValue(value),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.attributes['title']?.toString();
    final height = _doubleFromValue(widget.attributes['height']) ?? 300;
    final backgroundColor = _colorFromValue(
      widget.attributes['backgroundColor'],
      fallback: const Color(0xFF0D0D14),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title.isNotEmpty) ...[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: height,
                  width: double.infinity,
                  child: GestureDetector(
                    onPanUpdate: (details) => _orbit(
                      details.delta.dx * 0.01,
                      details.delta.dy * 0.01,
                    ),
                    onDoubleTap: _resetCamera,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Val3DView(
                            scene: _scene,
                            renderer:
                                widget.renderer ?? GenUi3D.defaultRenderer,
                            backgroundColor: backgroundColor,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _buildZoomControls(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_constants.isNotEmpty || _formulas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final formula in _formulas)
                      _buildFormulaValue(context, formula),
                    for (final constant in _constants)
                      _buildConstantSlider(context, constant),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
