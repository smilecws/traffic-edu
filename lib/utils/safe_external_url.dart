/// 실격 기준 JSON 등에서 온 출처 링크만 외부 브라우저로 엽니다.
bool isAllowedDisqualificationSourceUri(Uri uri) {
  if (uri.scheme != 'https') return false;
  final host = uri.host.toLowerCase();
  const allowedHosts = <String>{
    'safedriving.or.kr',
    'www.safedriving.or.kr',
  };
  return allowedHosts.contains(host);
}
