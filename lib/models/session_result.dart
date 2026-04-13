import 'question.dart';

/// 퀴즈 세션 내 단일 문항 답안 결과를 담는 타입 안전 클래스.
/// 기존 [Map<String, dynamic>] 방식을 대체합니다.
class SessionResult {
  final int questionId;
  final Question question;

  /// 선택한 보기 인덱스(0-based). 미답이면 빈 리스트.
  /// 단일 선택이면 [index], 복수 선택이면 여러 항목.
  final List<int> selectedIndices;
  final bool isCorrect;

  const SessionResult({
    required this.questionId,
    required this.question,
    required this.selectedIndices,
    required this.isCorrect,
  });
}
