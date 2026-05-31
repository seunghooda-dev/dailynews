import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/news_article.dart';
import 'sample_news.dart';

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
  return DateTime.now().subtract(const Duration(days: 1));
});

final selectedArticleIndexProvider = StateProvider<int>((ref) {
  return 0;
});

final newsProvider = FutureProvider.autoDispose<DailyNewsDocument>((ref) {
  final targetDate = ref.watch(targetDateProvider);
  final dateId = DateFormat('yyyy-MM-dd').format(targetDate);
  return ref.watch(newsRepositoryProvider).fetchByDate(dateId);
});

class NewsRepository {
  NewsRepository(this._firestore);

  final FirebaseFirestore? _firestore;

  Future<DailyNewsDocument> fetchByDate(String dateId) async {
    if (_firestore == null) {
      final snapshot = await _fetchLocalSnapshot(dateId);
      if (snapshot != null) {
        return snapshot;
      }
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return sampleDailyNews;
    }
    final snapshot = await _firestore
        .collection('korea_economy_news')
        .doc(dateId)
        .get();
    return DailyNewsDocument.fromSnapshot(snapshot);
  }

  Future<DailyNewsDocument?> _fetchLocalSnapshot(String dateId) async {
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.base.resolve('news_snapshot.json?v=$cacheBuster');
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
