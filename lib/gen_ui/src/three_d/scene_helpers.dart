part of 'gen_ui_3d_graphs.dart';

void _addAxes(Scene3D scene, {required double length}) {
  final axes = [
    (
      id: 'x-axis',
      start: vm.Vector3(-length, 0, 0),
      end: vm.Vector3(length, 0, 0),
      color: const Color(0xFFFF6666),
    ),
    (
      id: 'y-axis',
      start: vm.Vector3(0, -length, 0),
      end: vm.Vector3(0, length, 0),
      color: const Color(0xFF66DD88),
    ),
    (
      id: 'z-axis',
      start: vm.Vector3(0, 0, -length),
      end: vm.Vector3(0, 0, length),
      color: const Color(0xFF66AAFF),
    ),
  ];

  for (final axis in axes) {
    scene.add(
      SceneNode(
        id: axis.id,
        mesh: buildLine(start: axis.start, end: axis.end),
        style: RenderStyle(
          strokeColor: axis.color,
          strokeWidth: 1.5,
          wireframe: WireframeMode.none,
          shading: ShadingMode.unlit,
          depthOverlay: true,
        ),
      ),
    );
  }
}
