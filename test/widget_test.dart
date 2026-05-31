import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dailynews/features/news/models/news_article.dart';
import 'package:dailynews/features/news/widgets/article_card.dart';

void main() {
  testWidgets('ArticleCard renders collapsed article summary', (tester) async {
    const article = NewsArticle(
      title: '반도체 업종 실적 개선 기대가 커지고 있다',
      sector: '반도체',
      whatHappened: '주요 기업의 실적 전망이 상향됐다.',
      context: 'AI 서버 투자 확대가 수요를 견인했다.',
      implication: '관련 공급망 기업의 변동성이 확대될 수 있다.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArticleCard(article: article, selected: false, onTap: () {}),
        ),
      ),
    );

    expect(find.text('반도체'), findsOneWidget);
    expect(find.text('반도체 업종 실적 개선 기대가 커지고 있다'), findsOneWidget);
  });

  testWidgets('ArticleDetailPanel shows original article link', (tester) async {
    const article = NewsArticle(
      title: '금융시장 변동성이 확대됐다',
      sector: '금융',
      whatHappened: '시장 금리가 상승했다.',
      context: '정책 불확실성이 투자 심리에 영향을 줬다.',
      implication: '금융주와 성장주의 차별화가 커질 수 있다.',
      url: 'https://example.com/news/1',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ArticleDetailPanel(article: article)),
      ),
    );

    expect(find.text('원문 보기'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });
}
