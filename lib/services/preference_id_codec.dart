/// SharedPreferences에 저장된 정수 ID 문자열 목록을 안전히 복원합니다.
Set<int> decodeIdStringList(List<String> raw) {
  final out = <int>{};
  for (final s in raw) {
    final v = int.tryParse(s.trim());
    if (v != null) out.add(v);
  }
  return out;
}
