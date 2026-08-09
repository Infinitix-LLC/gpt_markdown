/// How hard a reasoning model thinks before answering.
///
/// Reasoning models reject `temperature` and `top_p` — use this instead.
enum ReasoningEffort {
  none('none'),
  low('low'),
  medium('medium'),
  high('high');

  const ReasoningEffort(this.wireName);

  final String wireName;
}
