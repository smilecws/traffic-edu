// `assets/questions_kor.json` 을 읽어 문항별 소카테고리 태그를 산출하고
// `assets/question_subcategory.json` (문항번호 → 태그) 로 저장합니다.
//
// 실행:
//   dart run tool/classify_subcategory.dart
//
// stdout 에 버킷별 카운트를 출력하므로 규칙 튜닝 후 재실행해 분포를 확인하세요.
// 이 파일은 개발 도구 전용이며, 앱 런타임 경로에 포함되지 않습니다.
//
// 생성된 `assets/question_subcategory.json` 은 수동 편집하지 말고 반드시
// 이 스크립트를 통해 재생성하세요.

import 'dart:convert';
import 'dart:io';

import 'package:quiz_app/services/subcategory_classifier.dart';

void main(List<String> args) {
  final inputPath = args.isNotEmpty ? args.first : 'assets/questions_kor.json';
  final outputPath = args.length > 1
      ? args[1]
      : 'assets/question_subcategory.json';

  final file = File(inputPath);
  if (!file.existsSync()) {
    stderr.writeln('input not found: $inputPath');
    exit(1);
  }

  final decoded = jsonDecode(file.readAsStringSync());
  final result = <String, String>{};
  final counts = <String, int>{};
  var total = 0;
  var skipped = 0;

  void process({
    required int? qn,
    required String rawCategory,
    required String question,
    required String explanation,
    required List<String> choices,
  }) {
    if (qn == null) {
      skipped++;
      return;
    }
    final tag = classifySubcategory(
      rawCategory: rawCategory,
      questionText: question,
      explanationText: explanation,
      choices: choices,
    );
    result[qn.toString()] = tag;
    counts[tag] = (counts[tag] ?? 0) + 1;
    total++;
  }

  if (decoded is List) {
    // 새 평탄형 (questions_kor.json) — category 필드가 없으므로
    // image / video 유무로 상위 카테고리를 파생.
    for (final raw in decoded) {
      final p = raw as Map<String, dynamic>;
      final qn = (p['question_number'] as num?)?.toInt();
      final image = p['image'];
      final video = p['video'];
      final rawCategory = video is String && video.isNotEmpty
          ? '동영상 문제'
          : (image is List && image.isNotEmpty ? '표지 및 상황문제' : '말문제');
      final choicesRaw = p['choices'];
      final choices = choicesRaw is Map
          ? (choicesRaw.entries.toList()
                ..sort((a, b) =>
                    (int.tryParse(a.key.toString()) ?? 0)
                        .compareTo(int.tryParse(b.key.toString()) ?? 0)))
              .map((e) => (e.value ?? '').toString())
              .toList()
          : <String>[];
      process(
        qn: qn,
        rawCategory: rawCategory,
        question: (p['question'] ?? '').toString(),
        explanation: (p['explanation'] ?? '').toString(),
        choices: choices,
      );
    }
  } else if (decoded is Map<String, dynamic>) {
    final pages = (decoded['pages'] as List?) ?? const [];
    for (final rawPage in pages) {
      final page = rawPage as Map<String, dynamic>;
      final problems = (page['problems'] as List?) ?? const [];
      for (final rawProblem in problems) {
        final p = rawProblem as Map<String, dynamic>;
        final qn = (p['question_number'] as num?)?.toInt();
        final rawCategory = (p['category'] as String?) ?? '';
        final problemArea = (p['problem_area'] as Map?) ?? const {};
        final explanationArea = (p['explanation_area'] as Map?) ?? const {};
        final choicesRaw = (problemArea['choice'] as List?) ?? const [];
        process(
          qn: qn,
          rawCategory: rawCategory,
          question: (problemArea['question'] ?? '').toString(),
          explanation: (explanationArea['explanation'] ?? '').toString(),
          choices: choicesRaw.map((e) => e.toString()).toList(),
        );
      }
    }
  } else {
    stderr.writeln('Unsupported JSON shape: ${decoded.runtimeType}');
    exit(1);
  }

  final sortedKeys = result.keys.toList()
    ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  final sorted = <String, String>{for (final k in sortedKeys) k: result[k]!};

  final out = File(outputPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(sorted),
    );

  stdout.writeln('Wrote ${out.path}: $total entries (skipped $skipped)');
  final orderedTags = <String>[
    ...SubcategoryIds.verbalSubcategoryIds,
    SubcategoryIds.signSituation,
    SubcategoryIds.video,
  ];
  final labelWidth = orderedTags
      .map((e) => e.length)
      .fold<int>(0, (m, v) => v > m ? v : m);
  for (final tag in orderedTags) {
    final c = counts[tag] ?? 0;
    stdout.writeln('  ${tag.padRight(labelWidth)} : $c');
  }
  stdout.writeln('  ${'TOTAL'.padRight(labelWidth)} : $total');
}
