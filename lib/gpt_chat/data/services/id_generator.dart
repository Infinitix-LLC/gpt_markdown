/// Monotonic ids, unique within a process run. No external uuid dependency.
class IdGenerator {
  int _counter = 0;

  String next([String prefix = 'id']) {
    _counter++;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}
