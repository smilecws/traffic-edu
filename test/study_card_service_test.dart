import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/services/study_card_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(StudyCardService.clearCache);

  group('StudyCardService', () {
    test('16개 토픽 메타가 id 1..16 으로 연속한다', () {
      final ids = StudyCardService.topics.map((m) => m.id).toList();
      expect(ids, [for (var i = 1; i <= 16; i++) i]);
      for (final m in StudyCardService.topics) {
        expect(m.slug, startsWith(m.id.toString().padLeft(2, '0')));
      }
    });

    test('16개 토픽 전부 로드 성공, 필수 필드 존재', () async {
      for (final meta in StudyCardService.topics) {
        final topic = await StudyCardService.loadTopic(meta.id);
        expect(topic, isNotNull, reason: '${meta.slug} 로드 실패');
        expect(topic!.id, meta.id);
        expect(topic.title, isNotEmpty,
            reason: '${meta.slug} title 비어있음');
        // 리스트 화면이 JSON 을 안 읽고 meta.title 로 바로 그리므로
        // 두 값이 어긋나면 사용자에게 잘못된 제목이 보인다.
        expect(topic.title, meta.title,
            reason: '${meta.slug} JSON title 과 meta.title 불일치');
        expect(topic.subTopics, isNotEmpty,
            reason: '${meta.slug} sub_topics 비어있음');

        for (final st in topic.subTopics) {
          expect(st.marker, isNotEmpty,
              reason: '${meta.slug} marker 비어있음');
          expect(st.title, isNotEmpty,
              reason: '${meta.slug} sub_topic title 비어있음');
          expect(st.cards, isNotEmpty,
              reason: '${meta.slug} ${st.marker} cards 비어있음');

          for (final c in st.cards) {
            expect(c.title, isNotEmpty,
                reason: '${meta.slug} card ${c.number} title 비어있음');
            expect(c.body, isNotEmpty,
                reason: '${meta.slug} card ${c.number} body 비어있음');
            expect(c.keyPoints, isNotEmpty,
                reason: '${meta.slug} card ${c.number} key_points 비어있음');
            expect(c.comparisonTable.headers, isNotEmpty,
                reason: '${meta.slug} card ${c.number} table.headers 비어있음');
            expect(c.comparisonTable.rows, isNotEmpty,
                reason: '${meta.slug} card ${c.number} table.rows 비어있음');
            expect(c.tags, isNotEmpty,
                reason: '${meta.slug} card ${c.number} tags 비어있음');
          }
        }
      }
    });

    test('존재하지 않는 토픽 id 는 null 반환', () async {
      expect(await StudyCardService.loadTopic(999), isNull);
      expect(await StudyCardService.loadTopic(0), isNull);
    });

    test('캐시 동작: 두 번째 호출은 동일 인스턴스 반환', () async {
      final a = await StudyCardService.loadTopic(1);
      final b = await StudyCardService.loadTopic(1);
      expect(identical(a, b), isTrue);
    });
  });
}
