import 'package:flutter/foundation.dart';

/// Which gen-UI widgets the model may draw — the `x_plusfinity.widgets` field.
///
/// Only enabled widgets are described to the model, so a narrow [only] list is
/// also a cheaper prompt.
@immutable
class WidgetSelection {
  const WidgetSelection._(this._wire);

  /// The gateway's own default set — the nine always-on widgets.
  static const WidgetSelection defaults = WidgetSelection._(true);

  /// All eighteen, including the opt-in ones.
  static const WidgetSelection all = WidgetSelection._('all');

  /// No widgets — plain text answers.
  static const WidgetSelection none = WidgetSelection._(false);

  /// Exactly these types. Names come from `GenUiWidgetTypes`; an unknown one
  /// makes the gateway return `400`.
  factory WidgetSelection.only(List<String> types) =>
      WidgetSelection._(List<String>.unmodifiable(types));

  final Object _wire;

  /// The value for `x_plusfinity.widgets`.
  Object toWire() => _wire;

  @override
  bool operator ==(Object other) {
    if (other is! WidgetSelection) return false;

    final mine = _wire;
    final theirs = other._wire;
    if (mine is List && theirs is List) return listEquals(mine, theirs);
    return mine == theirs;
  }

  @override
  int get hashCode {
    final wire = _wire;
    return wire is List ? Object.hashAll(wire) : wire.hashCode;
  }
}
