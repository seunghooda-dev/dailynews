import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return sampleDailyNews;
    }
    final snapshot = await _firestore
        .collection('korea_economy_news')
        .doc(dateId)
        .get();
    return DailyNewsDocument.fromSnapshot(snapshot);
  }
}
