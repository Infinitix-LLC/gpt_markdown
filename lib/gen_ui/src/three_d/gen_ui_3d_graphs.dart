/// Interactive 3D surface graphs for gen-UI payloads.
///
/// Four coordinate systems share one card: explicit Cartesian (`surface_3d`),
/// polar (`polar_surface_3d`), spherical (`spherical_surface_3d`), and
/// cylindrical (`cylindrical_surface_3d`). Equations are compiled by
/// `plusfinity_calculator` and meshed by `val_3d`.
///
/// The card supports drag-to-orbit, zoom buttons, a rotation lock, live
/// constant sliders that re-mesh the surface without resetting the camera, and
/// LaTeX formula readouts that recompute as the sliders move.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:plusfinity_calculator/plusfinity_calculator.dart';
import 'package:val_3d/val_3d.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../gen_ui_math.dart';
import '../gen_ui_shells.dart';

part 'formula_helpers.dart';
part 'graph_card.dart';
part 'models.dart';
part 'public_widgets.dart';
part 'scene_helpers.dart';
part 'value_parsers.dart';
