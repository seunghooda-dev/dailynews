import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/news_article.dart';
import 'sample_news.dart';

enum MarketScope {
  korea('Korea Market', '시장 브리핑', 'news_snapshot.json'),
  world('World Market', '월드 브리핑', 'world_news_snapshot.json');

  const MarketScope(this.label, this.headerTitle, this.snapshotFile);

  final String label;
  final String headerTitle;
  final String snapshotFile;
}

final firebaseEnabledProvider = Provider<bool>((ref) {
  return true;
});

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  if (!ref.watch(firebaseEnabledProvider)) {
    return null;
  }
  return FirebaseFirestore.instance;
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository(ref.watch(firestoreProvider));
});

final targetDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final selectedArticleIndexProvider = StateProvider<int>((ref) {
  return 0;
});

final selectedSectorFilterProvider = StateProvider<String>((ref) {
  return '전체';
});

final marketScopeProvider = StateProvider<MarketScope>((ref) {
  return MarketScope.korea;
});

final newsProvider = FutureProvider.autoDispose<DailyNewsDocument>((ref) {
  final targetDate = ref.watch(targetDateProvider);
  final marketScope = ref.watch(marketScopeProvider);
  final dateId = DateFormat('yyyy-MM-dd').format(targetDate);
  return ref.watch(newsRepositoryProvider).fetchByDate(dateId, marketScope);
});

class NewsRepository {
  NewsRepository(this._firestore);

  final FirebaseFirestore? _firestore;

  Future<DailyNewsDocument> fetchByDate(
    String dateId,
    MarketScope marketScope,
  ) async {
    if (_firestore != null && marketScope == MarketScope.korea) {
      try {
        final snapshot = await _firestore
            .collection('korea_economy_news')
            .doc(dateId)
            .get()
            .timeout(const Duration(seconds: 6));
        final document = DailyNewsDocument.fromSnapshot(snapshot);
        if (document.articles.isNotEmpty) {
          return document;
        }
      } catch (_) {
        // Fall through to the local snapshot so the dashboard remains usable.
      }
    }

    final snapshot = await _fetchLocalSnapshot(dateId, marketScope);
    if (snapshot != null && snapshot.articles.isNotEmpty) {
      return snapshot;
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (marketScope == MarketScope.world) {
      return DailyNewsDocument(date: dateId, articles: const []);
    }
    return sampleDailyNews;
  }

  Future<DailyNewsDocument?> _fetchLocalSnapshot(
    String dateId,
    MarketScope marketScope,
  ) async {
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.base.resolve(
        '${marketScope.snapshotFile}?v=$cacheBuster',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200 || response.body.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return DailyNewsDocument.fromMap(dateId, decoded);
    } catch (_) {
      return null;
    }
  }
}
