const List<String> quranCategoryKeys = [
  'beginner',
  '5_parts',
  '10_parts',
  '15_parts',
  '20_parts',
  '25_parts',
  'full_quran',
  'readings',
  'ijazas',
];

const Map<int, String> _numberToCategory = {
  5: '5_parts',
  10: '10_parts',
  15: '15_parts',
  20: '20_parts',
  25: '25_parts',
};

String normalizeCategory(String raw) {
  if (raw.isEmpty) return raw;
  var s = raw.trim().toLowerCase();
  s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
  s = s.replaceAll('ى', 'ي');
  s = s.replaceAll(RegExp(r'[ئؤء]'), '');
  s = s.replaceAll(RegExp(r'[ةۀ]'), 'ه');
  s = s.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
  if (s.isEmpty) return raw;

  if (s.startsWith('مبتد') || s.contains('beginner')) return 'beginner';

  final numbers = RegExp(r'\d+')
      .allMatches(s)
      .map((m) => int.tryParse(m.group(0) ?? ''))
      .whereType<int>()
      .toList();
  for (final n in numbers) {
    final mapped = _numberToCategory[n];
    if (mapped != null) return mapped;
  }

  if (s.startsWith('خمسهعشر') || s.startsWith('خمسعشر')) return '15_parts';
  if (s.contains('وعشر')) return '25_parts';
  if (s.startsWith('عشرون') || s.startsWith('عشرين')) return '20_parts';
  if (s.startsWith('خمس')) return '5_parts';
  if (s.startsWith('عشره') || s.startsWith('عشر')) return '10_parts';

  if (s.contains('قراات') || s.contains('قراه') || s == 'readings') {
    return 'readings';
  }
  if (s.contains('اجاز') || s.contains('ijaza')) return 'ijazas';

  if (s.contains('كامل') ||
      s.contains('ختم') ||
      s.contains('ختام') ||
      s.contains('تمام') ||
      s.contains('full')) {
    return 'full_quran';
  }
  if (s.contains('قران')) return 'full_quran';

  return raw;
}