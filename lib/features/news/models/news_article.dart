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
    this.isHeadline = false,
    this.clusterCount = 1,
    this.issueKeyword,
    this.relatedSources = const [],
  });

  final String title;
  final String sector;
  final String whatHappened;
  final String context;
  final String implication;
  final String? url;
  final String? source;
  final String? publishedAt;
  final bool isHeadline;
  final int clusterCount;
  final String? issueKeyword;
  final List<String> relatedSources;

  bool get isHotIssue => clusterCount >= 3;
  int get relatedSourceCount => relatedSources.length;

  String get sourceSummary {
    final primarySource = source?.trim();
    if (primarySource == null || primarySource.isEmpty) {
      return relatedSources.isEmpty ? '뉴스' : '${relatedSources.length}곳 보도';
    }
    if (relatedSources.isEmpty) {
      return primarySource;
    }
    return '$primarySource 외 ${relatedSources.length}곳';
  }

  factory NewsArticle.fromMap(Map<String, dynamic> map) {
    final rawIssueKeyword = map['issue_keyword'] as String?;
    final rawRelatedSources =
        map['related_sources'] as List<dynamic>? ?? const [];
    return NewsArticle(
      title: map['title'] as String? ?? '',
      sector: map['sector'] as String? ?? '기타',
      whatHappened: map['what_happened'] as String? ?? '',
      context: map['context'] as String? ?? '',
      implication: map['implication'] as String? ?? '',
      url: map['url'] as String?,
      source: map['source'] as String?,
      publishedAt: map['published_at'] as String?,
      isHeadline: map['is_headline'] as bool? ?? false,
      clusterCount: (map['cluster_count'] as num?)?.toInt() ?? 1,
      issueKeyword: rawIssueKeyword == null || rawIssueKeyword.trim().isEmpty
          ? null
          : rawIssueKeyword.trim(),
      relatedSources: rawRelatedSources
          .whereType<String>()
          .map((source) => source.trim())
          .where((source) => source.isNotEmpty)
          .toList(growable: false),
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
    final parsedArticles = rawArticles
        .whereType<Map<String, dynamic>>()
        .map(NewsArticle.fromMap)
        .toList(growable: false);
    return DailyNewsDocument(
      date: data['date'] as String? ?? fallbackDate,
      articles: _sortByObjectiveImportance(parsedArticles),
    );
  }
}

List<NewsArticle> _sortByObjectiveImportance(List<NewsArticle> articles) {
  final indexed = <_IndexedArticle>[
    for (var index = 0; index < articles.length; index++)
      _IndexedArticle(index, articles[index]),
  ];

  indexed.sort((left, right) {
    final priorityCompare = _importancePriority(
      left.article,
    ).compareTo(_importancePriority(right.article));
    if (priorityCompare != 0) {
      return priorityCompare;
    }

    final clusterCompare = right.article.clusterCount.compareTo(
      left.article.clusterCount,
    );
    if (clusterCompare != 0) {
      return clusterCompare;
    }

    return left.index.compareTo(right.index);
  });

  return indexed.map((entry) => entry.article).toList(growable: false);
}

int _importancePriority(NewsArticle article) {
  if (article.clusterCount >= 3) {
    return 0;
  }
  if (article.isHeadline) {
    return 1;
  }
  return 2;
}

class _IndexedArticle {
  const _IndexedArticle(this.index, this.article);

  final int index;
  final NewsArticle article;
}
