import 'dart:convert';
import 'dart:typed_data';

/// `data:image/...;base64,...` 문자열을 디코드합니다. 퀴즈 이미지 표시에 사용합니다.
Uint8List? decodeImageDataUri(String dataUri) {
  final idx = dataUri.indexOf('base64,');
  if (idx < 0) return null;
  try {
    return Uint8List.fromList(base64Decode(dataUri.substring(idx + 7)));
  } catch (_) {
    return null;
  }
}

String? normalizeQuestionImageUri(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  if (s.startsWith('data:image/')) return s;
  if (s.startsWith('assets/')) return s;
  // `assets/questions.json`은 `questions_images/...`처럼 상대 경로를 담습니다.
  return 'assets/$s';
}

String normalizeCaptionText(String input) {
  final t = input.trim();
  if (t.isEmpty) return '';
  // `■`가 여러 번 등장하면 항목마다 다음 줄로 내려 가독성을 높입니다.
  // 예: "■ A ■ B" -> "■ A\n■ B"
  final replaced = t.replaceAllMapped(RegExp(r'\s*■\s*'), (m) => '\n■ ');
  return replaced.startsWith('\n') ? replaced.substring(1) : replaced;
}

String? normalizeQuestionVideoUri(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  if (s.startsWith('https://')) return s;
  // 평문 HTTP는 업그레이드(동일 호스트가 HTTPS를 지원한다는 전제). 미지원 시 재생 단계에서 실패합니다.
  if (s.startsWith('http://')) return 'https://${s.substring(7)}';
  if (s.startsWith('assets/')) return s;
  return 'assets/$s';
}

class Question {
  final int id;
  final String question;
  final List<String> options;

  /// 0-based 보기 인덱스(정답이 여러 개면 모두 포함)
  final List<int> correctIndices;
  final String explanation;

  /// 이미지 URI 목록
  /// - `data:image/...;base64,...` (웹/앱 공용)
  /// - `assets/...` (에셋 이미지)
  final List<String> imageUris;

  /// 이미지 URI → 캡션(이미지 아래에 표시할 텍스트)
  /// - `assets/questions.json`의 `image_description_area.text`를 표시하는 용도
  final Map<String, String> imageCaptionsByUri;

  /// `assets/questions.json`의 `category` (예: 말문제, 표지 및 상황문제, 동영상 문제 등)
  final String? category;

  /// `video_area.file` (동영상 문제)
  final String? videoUri;

  const Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndices,
    required this.explanation,
    this.imageUris = const [],
    this.imageCaptionsByUri = const {},
    this.category,
    this.videoUri,
  });

  bool get isMultipleChoice => correctIndices.length > 1;
  bool get hasImages => imageUris.isNotEmpty;
  Set<int> get correctIndexSet => correctIndices.toSet();

  /// 레거시 `{ id, question, options, answer: int(0-based), explanation }`
  factory Question.fromJson(Map<String, dynamic> json) {
    final dynamic ans = json['answer'];
    final List<int> indices;
    if (ans is int) {
      indices = [ans];
    } else if (ans is List) {
      indices = ans.map((e) => (e as num).toInt() - 1).toList();
    } else {
      throw FormatException('Invalid answer field');
    }
    final images = json['images'];
    final List<String> uris = images is List
        ? images.map(normalizeQuestionImageUri).whereType<String>().toList()
        : const <String>[];
    return Question(
      id: json['id'] as int,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndices: indices,
      explanation: json['explanation'] as String,
      imageUris: uris,
      imageCaptionsByUri: const {},
      category: json['category'] as String?,
      videoUri: normalizeQuestionVideoUri(json['video']),
    );
  }

  /// `pages[].questions[]` PDF 내보내기 형식 (보기 번호 1-based, answer도 1-based)
  factory Question.fromPageExport(Map<String, dynamic> json, int id) {
    final choices = json['choices'] as List;
    final sorted = choices
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
    final options = sorted.map((c) => c['text'] as String).toList();
    final answerNumbers = List<int>.from(json['answer'] as List);
    final correctIndices = answerNumbers.map((n) => n - 1).toList();
    final images = json['images'] as List? ?? [];
    return Question(
      id: id,
      question: json['question'] as String,
      options: options,
      correctIndices: correctIndices,
      explanation: json['explanation'] as String,
      imageUris:
          images.map(normalizeQuestionImageUri).whereType<String>().toList(),
      imageCaptionsByUri: const {},
      category: json['category'] as String?,
      videoUri: normalizeQuestionVideoUri(json['video']),
    );
  }

  /// 새 평탄형 (questions_kor.json) — 최상위 List, 항목 스키마는 다음과 같다:
  /// `{ page_number, question_number, question, choices: {"1":..,"2":..,..},
  ///   answers: [int(1-based)], explanation, image: [paths]?,
  ///   image_explanation: [string]?, explanation_image: [paths]?, video: path? }`
  /// `category` 가 없으므로 `video`/`image` 유무에서 파생한다.
  factory Question.fromFlatExport(Map<String, dynamic> json, int id) {
    final question = (json['question'] ?? '').toString();

    final choicesRaw = (json['choices'] as Map?) ?? const {};
    final entries = choicesRaw.entries
        .map((e) => MapEntry(int.tryParse(e.key.toString()) ?? 0, e.value))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final options = entries.map((e) => (e.value ?? '').toString()).toList();

    final answersRaw = json['answers'];
    final correctIndices = answersRaw is List
        ? answersRaw.map((e) => (e as num).toInt() - 1).toList(growable: false)
        : const <int>[];

    final explanation = (json['explanation'] ?? '').toString();

    final imageRaw = json['image'];
    final mainImages = imageRaw is List
        ? imageRaw.map(normalizeQuestionImageUri).whereType<String>().toList()
        : const <String>[];
    final explanationImageRaw = json['explanation_image'];
    final explanationImages = explanationImageRaw is List
        ? explanationImageRaw
            .map(normalizeQuestionImageUri)
            .whereType<String>()
            .toList()
        : const <String>[];
    final imageUris = <String>[...mainImages, ...explanationImages];

    final captionsRaw = json['image_explanation'];
    final captionLines = captionsRaw is List
        ? captionsRaw
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : const <String>[];
    final captionText =
        captionLines.isEmpty ? '' : captionLines.map((l) => '■ $l').join('\n');
    final captionAnchor = mainImages.isNotEmpty
        ? mainImages.first
        : (explanationImages.isNotEmpty ? explanationImages.first : null);

    final videoUri = normalizeQuestionVideoUri(json['video']);

    final String category;
    if (videoUri != null) {
      category = '동영상 문제';
    } else if (mainImages.isNotEmpty) {
      category = '표지 및 상황문제';
    } else {
      category = '말문제';
    }

    return Question(
      id: id,
      question: question,
      options: options,
      correctIndices: correctIndices,
      explanation: explanation,
      imageUris: imageUris,
      imageCaptionsByUri: {
        if (captionText.isNotEmpty && captionAnchor != null)
          captionAnchor: captionText,
      },
      category: category,
      videoUri: videoUri,
    );
  }

  /// `assets/questions.json` 형식 (pages[].problems[])
  factory Question.fromPdfProblemsExport(Map<String, dynamic> json, int id) {
    final problemArea = (json['problem_area'] as Map?) ?? const {};
    final explanationArea = (json['explanation_area'] as Map?) ?? const {};
    final question = (problemArea['question'] ?? '').toString();
    final optionsRaw = (problemArea['choice'] as List?) ?? const <dynamic>[];
    final options = optionsRaw.map((e) => e.toString()).toList();

    final dynamic ans = explanationArea['answer'];
    final List<int> correctIndices;
    if (ans is int) {
      correctIndices = [ans - 1];
    } else if (ans is num) {
      correctIndices = [ans.toInt() - 1];
    } else if (ans is List) {
      correctIndices =
          ans.map((e) => (e as num).toInt() - 1).toList(growable: false);
    } else {
      correctIndices = const <int>[];
    }

    final explanation = (explanationArea['explanation'] ?? '').toString();

    final imageArea = (json['image_area'] as Map?) ?? const {};
    final imageDescArea = (json['image_description_area'] as Map?) ?? const {};
    final imageDescText =
        normalizeCaptionText((imageDescArea['text'] ?? '').toString());
    final mainImageUri = normalizeQuestionImageUri(imageArea['image']);
    final imageDescUri = normalizeQuestionImageUri(imageDescArea['image']);
    final images = <String>[
      if (mainImageUri case final s?) s,
      if (imageDescUri case final s?) s,
      if (normalizeQuestionImageUri(explanationArea['image']) case final s?) s,
    ];

    final videoArea = (json['video_area'] as Map?) ?? const {};
    final videoUri = normalizeQuestionVideoUri(videoArea['file']);

    return Question(
      id: id,
      question: question,
      options: options,
      correctIndices: correctIndices,
      explanation: explanation,
      imageUris: images,
      imageCaptionsByUri: {
        if (imageDescText.isNotEmpty && mainImageUri != null)
          // 요구사항: `image_area.image`가 있으면 그 이미지 아래에 설명 텍스트 배치
          mainImageUri: imageDescText,
        if (imageDescText.isNotEmpty &&
            mainImageUri == null &&
            imageDescUri != null)
          // 예외: 본문 이미지가 없을 때만 설명 이미지 아래에 표시
          imageDescUri: imageDescText,
      },
      category: json['category'] as String?,
      videoUri: videoUri,
    );
  }
}
