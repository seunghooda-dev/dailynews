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
        title: const Text('어제자 경제 뉴스'),
        centerTitle: false,
        actions: [
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
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _ArticleGrid(
                          articles: articles,
                          selectedIndex: selectedIndex,
                          onSelect: onSelect,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ArticleDetailPanel(article: selectedArticle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              header,
              const SizedBox(height: 14),
              for (var index = 0; index < articles.length; index++) ...[
                SizedBox(
                  height: 232,
                  child: ArticleCard(
                    article: articles[index],
                    selected: selectedIndex == index,
                    onTap: () => onSelect(index),
                  ),
                ),
                const SizedBox(height: 10),
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
        maxCrossAxisExtent: 330,
        mainAxisExtent: 232,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '선택해서 읽는 구조화 뉴스 $count건',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (usingSampleData)
          Chip(
            avatar: const Icon(Icons.storage, size: 16),
            label: const Text('로컬 샘플'),
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
      ],
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
            Text(
              '뉴스를 불러오지 못했습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
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
