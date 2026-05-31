import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.sector,
    required this.whatHappened,
    required this.context,
    required this.implication,
    this.url,
    this.source,
    this.publishedAt,
  });

  final String title;
  final String sector;
  final String whatHappened;
  final String context;
  final String implication;
  final String? url;
  final String? source;
  final String? publishedAt;

  factory NewsArticle.fromMap(Map<String, dynamic> map) {
    return NewsArticle(
      title: map['title'] as String? ?? '',
      sector: map['sector'] as String? ?? '기타',
      whatHappened: map['what_happened'] as String? ?? '',
      context: map['context'] as String? ?? '',
      implication: map['implication'] as String? ?? '',
      url: map['url'] as String?,
      source: map['source'] as String?,
      publishedAt: map['published_at'] as String?,
    );
  }
}

class DailyNewsDocument {
  const DailyNewsDocument({required this.date, required this.articles});

  final String date;
  final List<NewsArticle> articles;

  factory DailyNewsDocument.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return DailyNewsDocument.fromMap(snapshot.id, data);
  }

  factory DailyNewsDocument.fromMap(
    String fallbackDate,
    Map<String, dynamic> data,
  ) {
    final rawArticles = data['articles'] as List<dynamic>? ?? const [];
    return DailyNewsDocument(
      date: data['date'] as String? ?? fallbackDate,
      articles: rawArticles
          .whereType<Map<String, dynamic>>()
          .map(NewsArticle.fromMap)
          .toList(growable: false),
    );
  }
}
