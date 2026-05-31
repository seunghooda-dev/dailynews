import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/news_repository.dart';
import 'models/news_article.dart';
import 'widgets/article_card.dart';
import 'widgets/news_skeleton.dart';

class NewsDashboardPage extends ConsumerWidget {
  const NewsDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsState = ref.watch(newsProvider);
    final selectedIndex = ref.watch(selectedArticleIndexProvider);
    final firebaseEnabled = ref.watch(firebaseEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dailynews'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                'Korea Market',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: '새로고침',
            onPressed: () => ref.invalidate(newsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: newsState.when(
        loading: () => const NewsSkeleton(),
        error: (error, stackTrace) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(newsProvider),
        ),
        data: (dailyNews) {
          if (dailyNews.articles.isEmpty) {
            return const _EmptyView();
          }

          final safeIndex = selectedIndex < 0
              ? 0
              : selectedIndex >= dailyNews.articles.length
              ? dailyNews.articles.length - 1
              : selectedIndex;

          return _SelectableNewsLayout(
            date: dailyNews.date,
            articles: dailyNews.articles,
            selectedIndex: safeIndex,
            selectedArticle: dailyNews.articles[safeIndex],
            usingSampleData: !firebaseEnabled,
            onRefresh: () async => ref.invalidate(newsProvider),
            onSelect: (index) {
              ref.read(selectedArticleIndexProvider.notifier).state = index;
            },
          );
        },
      ),
    );
  }
}

class _SelectableNewsLayout extends StatelessWidget {
  const _SelectableNewsLayout({
    required this.date,
    required this.articles,
    required this.selectedIndex,
    required this.selectedArticle,
    required this.usingSampleData,
    required this.onRefresh,
    required this.onSelect,
  });

  final String date;
  final List<NewsArticle> articles;
  final int selectedIndex;
  final NewsArticle selectedArticle;
  final bool usingSampleData;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 940;
        final header = _DashboardHeader(
          date: date,
          count: articles.length,
          usingSampleData: usingSampleData,
        );

        if (isWide) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _ArticleGrid(
                              articles: articles,
                              selectedIndex: selectedIndex,
                              onSelect: onSelect,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 5,
                            child: ArticleDetailPanel(article: selectedArticle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              header,
              const SizedBox(height: 16),
              for (var index = 0; index < articles.length; index++) ...[
                SizedBox(
                  height: 228,
                  child: ArticleCard(
                    article: articles[index],
                    selected: selectedIndex == index,
                    onTap: () => onSelect(index),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ArticleDetailPanel(article: selectedArticle, scrollable: false),
            ],
          ),
        );
      },
    );
  }
}

class _ArticleGrid extends StatelessWidget {
  const _ArticleGrid({
    required this.articles,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<NewsArticle> articles;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 304,
        mainAxisExtent: 228,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        return ArticleCard(
          article: articles[index],
          selected: selectedIndex == index,
          onTap: () => onSelect(index),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.date,
    required this.count,
    required this.usingSampleData,
  });

  final String date;
  final int count;
  final bool usingSampleData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 20,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('시장 브리핑', style: theme.textTheme.headlineSmall),
                  ],
                ),
                _Metric(label: '뉴스', value: '$count'),
                _Metric(
                  label: '데이터',
                  value: usingSampleData ? 'Local' : 'Firestore',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 108,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 42, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('뉴스를 불러오지 못했습니다', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '선택할 뉴스가 아직 없습니다',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
      ),
    );
  }
}
