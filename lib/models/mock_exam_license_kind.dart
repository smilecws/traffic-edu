/// 모의고사 시작 시 선택하는 면허 종류 (학과시험 합격 기준 구분)
enum MockExamLicenseKind {
  type1Large,
  type1Special,
  type1Normal,
  type2Normal,
}

extension MockExamLicenseKindScoring on MockExamLicenseKind {
  /// 만점 100점 환산 시 합격에 필요한 최저 점수
  int get passScoreMinOutOf100 => switch (this) {
        MockExamLicenseKind.type2Normal => 60,
        _ => 70,
      };
}
