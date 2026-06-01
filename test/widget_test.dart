import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/link.dart';

import 'package:dailynews/features/news/models/news_article.dart';
import 'package:dailynews/features/news/widgets/article_card.dart';

void main() {
  testWidgets('ArticleCard renders compact article headline', (tester) async {
    const article = NewsArticle(
      title: '반도체 업종 실적 개선 기대가 커지고 있다',
      sector: '반도체',
      source: '한국경제',
      publishedAt: '2026.06.01. 오후 1:05',
      whatHappened: '주요 기업의 실적 전망이 상향됐다.',
      context: 'AI 서버 투자 확대가 수요를 견인했다.',
      implication: '관련 공급망 기업의 변동성이 확대될 수 있다.',
      isHeadline: true,
      clusterCount: 3,
      issueKeyword: '삼성전자 HBM',
      relatedSources: ['매일경제', '연합뉴스'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArticleCard(article: article, selected: false, onTap: () {}),
        ),
      ),
    );

    expect(find.text('반도체'), findsOneWidget);
    expect(find.text('주요'), findsNothing);
    expect(find.text('(3곳 보도)'), findsOneWidget);
    expect(find.text('삼성전자 HBM'), findsOneWidget);
    expect(find.text('한국경제 외 2곳'), findsOneWidget);
    expect(find.text('06.01 13:05'), findsOneWidget);
    expect(find.textContaining('오후'), findsNothing);
    expect(find.byIcon(Icons.article_outlined), findsNothing);
    expect(find.text('반도체 업종 실적 개선 기대가 커지고 있다'), findsOneWidget);
    expect(find.text('주요 기업의 실적 전망이 상향됐다.'), findsNothing);
  });

  testWidgets('ArticleDetailPanel shows original article link', (tester) async {
    const article = NewsArticle(
      title: '금융시장 변동성이 확대됐다',
      sector: '금융',
      whatHappened: '시장 금리가 상승했다.',
      context: '정책 불확실성이 투자 심리에 영향을 줬다.',
      implication: '금융주와 성장주의 차별화가 커질 수 있다.',
      publishedAt: '입력 : 2026.06.01. 오전 9:03',
      url: 'https://example.com/news/1',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ArticleDetailPanel(article: article)),
      ),
    );

    expect(find.text('원문 보기'), findsOneWidget);
    expect(find.text('핵심 요약'), findsOneWidget);
    expect(find.text('핵심 팩트 및 수치'), findsNothing);
    expect(find.text('시장 배경 분석'), findsNothing);
    expect(find.textContaining('시장 금리가 상승했다.'), findsOneWidget);
    expect(find.textContaining('정책 불확실성이 투자 심리에 영향을 줬다.'), findsOneWidget);
    expect(find.text('향후 주가 전망'), findsOneWidget);
    expect(find.textContaining('2026.06.01 09:03'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    expect(find.byType(Link), findsOneWidget);
  });

  test('sectorColor maps major sectors to distinct colors', () {
    expect(sectorColor('반도체'), isNot(sectorColor('금융')));
    expect(sectorColor('금융'), isNot(sectorColor('방산 수출')));
  });
}
