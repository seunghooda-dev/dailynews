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
}
