/// 한글(CJK) 텍스트가 글자 단위가 아니라 어절(띄어쓰기) 단위로만 줄바꿈되도록
/// 변환한다.
///
/// Flutter 텍스트 엔진은 한글을 어느 글자 경계에서나 끊으므로 한 어절이
/// 줄 끝에서 잘린다. 각 어절 내부 글자(코드 포인트) 사이에 WORD JOINER
/// (U+2060, 보이지 않는 비-줄바꿈 문자)를 끼워 어절 내부 줄바꿈을 금지하고,
/// 어절 사이의 실제 공백만 줄바꿈 지점으로 남긴다.
///
/// 줄바꿈(`\n`)·탭 등은 보존하기 위해 일반 스페이스만 어절 경계로 취급한다.
String wrapByEojeol(String text) {
  if (text.isEmpty) return text;
  final wj = String.fromCharCode(0x2060); // WORD JOINER
  return text
      .split(' ')
      .map((token) =>
          token.runes.map(String.fromCharCode).join(wj))
      .join(' ');
}
