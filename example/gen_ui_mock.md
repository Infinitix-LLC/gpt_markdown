# Gen UI Mock Document

Mock assistant reply exercising every gen-UI widget built into `gpt_markdown`.
Render it with a registry:

```dart
final registry = GenUiRegistry.defaults();

GptMarkdown(markdown, genUiBuilder: registry.build);
```

> **Payload syntax:** the directive is delimited by private-use code points —
> `U+E200` `genui` `U+E202` `<json>` `U+E201`. They are invisible in a text
> editor, so build directives with `wrapGenUi(jsonString)` rather than typing
> them. Because the delimiters are not markdown punctuation, a payload may
> contain `%`, `*`, or braces freely.

---

## Basics

Plain text node:

genui{"text": {"text": "Quadratic functions describe parabolic motion."}}

A network image:

genui{"image": {"url": "https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg", "height": 160}}

A button. Presses go to `GenUiRegistry.defaults(onAction: ...)`; without a
callback it renders disabled:

genui{"button": {"text": "Continue to practice", "action": "open_practice"}}

---

## Data Visualization

### Line chart

Curved series with bottom labels:

genui{"line_chart": {"title": "Study Progress", "labels": ["Mon", "Tue", "Wed", "Thu", "Fri"], "points": [2, 4, 3, 7, 6], "color": "#766CE3", "curved": true, "height": 240}}

Straight segments with explicit `x` / `y` objects:

genui{"line_chart": {"title": "Session Length (min)", "points": [{"x": 0, "y": 12}, {"x": 1, "y": 25}, {"x": 2, "y": 18}, {"x": 3, "y": 31}], "curved": false, "color": "#4090DD"}}

### Area chart

Same payload shape, filled below the curve:

genui{"area_chart": {"title": "Practice Accuracy", "labels": ["Quiz 1", "Quiz 2", "Quiz 3", "Quiz 4"], "points": [62, 71, 78, 84], "color": "#00CED1"}}

### Bar chart

Per-bar colors override the series `color`:

genui{"bar_chart": {"title": "Questions by Topic", "values": [{"label": "Algebra", "value": 12, "color": "#C848AB"}, {"label": "Geometry", "value": 8, "color": "#766CE3"}, {"label": "Calculus", "value": 15}, {"label": "Stats", "value": 6}], "color": "#4090DD", "height": 240}}

### Pie chart

Donut with a legend underneath:

genui{"pie_chart": {"title": "Time Spent", "values": [{"label": "Lessons", "value": 45, "color": "#C848AB"}, {"label": "Practice", "value": 35, "color": "#766CE3"}, {"label": "Review", "value": 20, "color": "#00CED1"}], "height": 260}}

### Comparison chart

Grouped current-vs-target bars:

genui{"comparison_chart": {"title": "Current vs Target Mastery", "currentLabel": "Current", "targetLabel": "Next Goal", "currentColor": "#766CE3", "targetColor": "#00CED1", "values": [{"label": "Graph", "current": 82, "target": 90}, {"label": "Vertex", "current": 74, "target": 88}, {"label": "Roots", "current": 61, "target": 80}], "height": 280}}

### Progress list

Values are read as percentages:

genui{"progress_list": {"title": "Skill Mastery", "values": [{"label": "Reading a parabola", "value": 82, "color": "#00CED1"}, {"label": "Solving roots", "value": 68, "color": "#766CE3"}, {"label": "Completing the square", "value": 41, "color": "#C848AB"}]}}

### Metric grid

Delta strings are free text, `%` included:

genui{"metric_grid": {"title": "Weekly Learning Signals", "values": [{"label": "Accuracy", "value": "86%", "delta": "+8 pts", "color": "#00CED1"}, {"label": "Practice Streak", "value": "5 days", "delta": "+2 days"}, {"label": "Problems Solved", "value": "134", "delta": "+22"}], "height": 180}}

---

## Student Learning

### Unit converter

Interactive: drag the slider to change the source value. `min` + `max` are what
make the slider appear.

genui{"unit_converter": {"title": "Speed Unit Conversion", "subtitle": "Convert a common physics speed into SI units", "value": 72, "fromUnit": "km/h", "toUnit": "m/s", "min": 0, "max": 180, "divisions": 18, "precision": 2, "note": "Physics formulas usually expect speed in meters per second."}}

Temperature uses offset formulas, not a single factor:

genui{"unit_converter": {"title": "Temperature", "value": 98.6, "fromUnit": "F", "toUnit": "C", "min": -40, "max": 212, "precision": 1}}

Static conversion with no slider (`min` / `max` omitted):

genui{"unit_converter": {"title": "Distance", "value": 5, "fromUnit": "mi", "toUnit": "km", "precision": 3}}

Mismatched categories render nothing — this line stays blank:

genui{"unit_converter": {"value": 5, "fromUnit": "kg", "toUnit": "m"}}

### Timeline flow

genui{"timeline_flow": {"title": "Photosynthesis Flow", "subtitle": "How plants turn light energy into stored chemical energy", "items": [{"time": "Step 1", "title": "Light Absorption", "description": "Chlorophyll captures energy from sunlight.", "takeaway": "Light energy starts the process.", "color": "#766CE3"}, {"time": "Step 2", "title": "Water Splitting", "description": "Water molecules break into hydrogen, electrons, and oxygen.", "takeaway": "The oxygen you breathe is a by-product.", "color": "#4090DD"}, {"time": "Step 3", "title": "Carbon Fixation", "description": "Carbon dioxide is used to build sugar molecules.", "takeaway": "Carbon from the air becomes part of glucose.", "color": "#00CED1"}]}}

Scrollable variant (fixed `height`) with alias keys `steps` / `label` / `body`:

genui{"timeline_flow": {"title": "Solving a Quadratic", "height": 220, "steps": [{"label": "Standard form", "body": "Write it as ax^2 + bx + c = 0."}, {"label": "Discriminant", "body": "Compute b^2 - 4ac to learn how many real roots exist."}, {"label": "Quadratic formula", "body": "Apply x = (-b +/- sqrt(disc)) / 2a."}, {"label": "Check", "body": "Substitute both roots back into the original equation."}]}}

---

## Math Plot

### `plot_latex`

Static preview inline; tap to open a pannable, zoomable dialog.

genui{"plot_latex": {"title": "Parabola", "equation": "x^2"}}

Trigonometric equation:

genui{"plot_latex": {"equation": "\\sin(x)"}}

---

## Media

### `video`

Network video with play/pause and a scrub bar. Shows a spinner while loading
and a notice tile if the URL fails.

genui{"video": {"title": "Sample clip", "url": "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"}}

---

## 3D Graphs

Drag to orbit, double-tap to reset the camera, use the buttons to zoom or lock
rotation. Constant sliders re-mesh the surface without moving the camera.

### `surface_3d`

Explicit Cartesian surface, `z = f(x, y)`, with a live constant:

genui{"surface_3d": {"title": "3D Saddle Surface", "equation": "z = a * (x^2 - y^2)", "constants": [{"name": "a", "label": "Scale a", "value": 0.24, "min": 0.05, "max": 0.6, "step": 0.01}], "xMin": -1.8, "xMax": 1.8, "yMin": -1.8, "yMax": 1.8, "uSteps": 34, "vSteps": 34, "wireframe": "overlay", "height": 320}}

### `polar_surface_3d`

`z = f(radius, theta)`. Compact multiplication like `0.32sin(5theta)` is
normalised to explicit `*` before compiling:

genui{"polar_surface_3d": {"title": "Polar Ripple Surface", "equation": "z = 0.32sin(5theta)(1 - r / 1.5)", "radiusMax": 1.45, "radiusSteps": 28, "thetaSteps": 72, "colors": ["#6633FF", "#33DDFF", "#FFFFFF"]}}

### `spherical_surface_3d`

The expression returns radius, `r = f(theta, phi)`:

genui{"spherical_surface_3d": {"title": "Spherical Bulge Graph", "radius": "r = 0.82 + 0.16sin(3theta)sin(2phi)", "thetaSteps": 64, "phiSteps": 32, "distance": 5.5}}

### `cylindrical_surface_3d`

Two constants plus a LaTeX formula readout that recomputes as the sliders move.
`zMin` / `zMax` are string expressions over those constants:

genui{"cylindrical_surface_3d": {"title": "Adjustable Cylinder", "r": "r = radius", "formula": {"latex": "V = \\pi r^2 h", "expression": "pi * radius^2 * height"}, "constants": [{"name": "radius", "label": "Radius", "value": 0.8, "min": 0.35, "max": 1.4, "step": 0.05}, {"name": "height", "label": "Height", "value": 2.4, "min": 1.0, "max": 4.0, "step": 0.1}], "zMin": "-height / 2", "zMax": "height / 2", "thetaSteps": 64, "zSteps": 34, "wireframe": "overlay"}}

---

## Multiple widgets in one payload

Every top-level key is its own widget; they stack in a column:

genui{"text": {"text": "Summary of this week"}, "metric_grid": {"values": [{"label": "Lessons", "value": "12"}, {"label": "Streak", "value": "5 days"}]}, "progress_list": {"values": [{"label": "Overall mastery", "value": 74}]}}

---

## Host-app extension points

`val_scene` (alias `val`) is the one type `GenUiRegistry.defaults()` does not
register: it streams from a Firebase-backed artifact pipeline, which this
package deliberately does not depend on. The next line is intentionally blank
until a host registers a builder for it.

genui{"val_scene": {"id": "abc123", "frame": "reels"}}

Register it like this:

```dart
GenUiRegistry.defaults()
  ..register('val_scene', (context, model) => MyValScene(model.attributes));
```

---

## Degenerate payloads

Empty data renders nothing rather than throwing:

genui{"bar_chart": {"title": "No data", "values": []}}

genui{"line_chart": {"points": "not-a-list"}}

An unparsable payload shows an error chip in debug builds and nothing in
release:

genui{"bar_chart": {"values": [1, 2}}

---

## Mixed with regular markdown

Gen UI is an **inline** component, so it composes with the rest of the
document. Math still renders: \(f(x) = ax^2 + bx + c\), and so do tables:

| Topic | Mastery |
| --- | --- |
| Algebra | 82 |
| Geometry | 74 |

- Lists work
- Alongside widgets:

genui{"progress_list": {"values": [{"label": "Inside a list item", "value": 55}]}}

Done.
