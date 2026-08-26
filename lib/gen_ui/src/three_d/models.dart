part of 'gen_ui_3d_graphs.dart';

class _GraphConstant {
  const _GraphConstant({
    required this.name,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step,
  });

  final String name;
  final String label;
  final double value;
  final double min;
  final double max;
  final double? step;

  int? get divisions {
    final stepValue = step;
    if (stepValue == null || stepValue <= 0) {
      return null;
    }

    final count = ((max - min) / stepValue).round();
    if (count <= 0) {
      return null;
    }

    return count.clamp(1, 1000).toInt();
  }

  double clampValue(double nextValue) {
    return nextValue.clamp(min, max).toDouble();
  }
}

class _GraphFormula {
  const _GraphFormula({required this.latex, required this.expression});

  final String latex;
  final String expression;
}

class _CameraView {
  const _CameraView({
    required this.target,
    required this.distance,
    required this.phi,
    required this.theta,
    required this.gamma,
    required this.fovY,
  });

  final vm.Vector3 target;
  final double distance;
  final double phi;
  final double theta;
  final double gamma;
  final double fovY;

  factory _CameraView.from(Camera3D camera) {
    return _CameraView(
      target: camera.target.clone(),
      distance: camera.distance,
      phi: camera.phi,
      theta: camera.theta,
      gamma: camera.gamma,
      fovY: camera.fovY,
    );
  }

  void applyTo(Camera3D camera) {
    camera.target = target.clone();
    camera.distance = distance;
    camera.phi = phi;
    camera.theta = theta;
    camera.gamma = gamma;
    camera.fovY = fovY;
  }
}
