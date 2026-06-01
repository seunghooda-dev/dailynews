import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/news_repository.dart';
import 'models/news_article.dart';
import 'widgets/article_card.dart';
import 'widgets/news_skeleton.dart';

const _allSectorFilter = '전체';

class NewsDashboardPage extends ConsumerWidget {
  const NewsDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsState = ref.watch(newsProvider);
    final selectedIndex = ref.watch(selectedArticleIndexProvider);
    final selectedSector = ref.watch(selectedSectorFilterProvider);
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

          final sectorFilters = _buildSectorFilters(dailyNews.articles);
          final availableSectors = sectorFilters
              .map((filter) => filter.sector)
              .toSet();
          final effectiveSector = availableSectors.contains(selectedSector)
              ? selectedSector
              : _allSectorFilter;
          final visibleArticles = effectiveSector == _allSectorFilter
              ? dailyNews.articles
              : dailyNews.articles
                    .where((article) => article.sector == effectiveSector)
                    .toList(growable: false);

          if (visibleArticles.isEmpty) {
            return _FilteredEmptyView(
              sectorFilters: sectorFilters,
              selectedSector: effectiveSector,
              onFilterChanged: (sector) {
                ref.read(selectedSectorFilterProvider.notifier).state = sector;
                ref.read(selectedArticleIndexProvider.notifier).state = 0;
              },
            );
          }

          final safeIndex = selectedIndex < 0
              ? 0
              : selectedIndex >= visibleArticles.length
              ? visibleArticles.length - 1
              : selectedIndex;

          return _SelectableNewsLayout(
            date: dailyNews.date,
            articles: visibleArticles,
            sectorFilters: sectorFilters,
            selectedSector: effectiveSector,
            selectedIndex: safeIndex,
            selectedArticle: visibleArticles[safeIndex],
            usingSampleData: !firebaseEnabled,
            onRefresh: () async => ref.invalidate(newsProvider),
            onFilterChanged: (sector) {
              ref.read(selectedSectorFilterProvider.notifier).state = sector;
              ref.read(selectedArticleIndexProvider.notifier).state = 0;
            },
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
    required this.sectorFilters,
    required this.selectedSector,
    required this.selectedIndex,
    required this.selectedArticle,
    required this.usingSampleData,
    required this.onRefresh,
    required this.onFilterChanged,
    required this.onSelect,
  });

  final String date;
  final List<NewsArticle> articles;
  final List<_SectorFilter> sectorFilters;
  final String selectedSector;
  final int selectedIndex;
  final NewsArticle selectedArticle;
  final bool usingSampleData;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onFilterChanged;
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
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 14),
                    _SectorFilterBar(
                      filters: sectorFilters,
                      selectedSector: selectedSector,
                      onChanged: onFilterChanged,
                    ),
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
                          Container(
                            width: 1,
                            height: double.infinity,
                            color: Theme.of(context).colorScheme.outlineVariant
                                .withValues(alpha: 0.72),
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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              header,
              const SizedBox(height: 14),
              _SectorFilterBar(
                filters: sectorFilters,
                selectedSector: selectedSector,
                onChanged: onFilterChanged,
              ),
              const SizedBox(height: 18),
              for (var index = 0; index < articles.length; index++) ...[
                SizedBox(
                  height: 176,
                  child: ArticleCard(
                    article: articles[index],
                    selected: selectedIndex == index,
                    onTap: () => onSelect(index),
                  ),
                ),
                const SizedBox(height: 16),
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
        mainAxisExtent: 176,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
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

class _SectorFilterBar extends StatelessWidget {
  const _SectorFilterBar({
    required this.filters,
    required this.selectedSector,
    required this.onChanged,
  });

  final List<_SectorFilter> filters;
  final String selectedSector;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter.sector == selectedSector;
          final color = filter.sector == _allSectorFilter
              ? theme.colorScheme.primary
              : sectorColor(filter.sector);
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Text('${filter.sector} ${filter.count}'),
            onSelected: (_) => onChanged(filter.sector),
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: selected ? theme.colorScheme.onPrimary : color,
              fontWeight: FontWeight.w900,
            ),
            backgroundColor: theme.colorScheme.surface,
            selectedColor: selected
                ? color.withValues(alpha: 0.92)
                : color.withValues(alpha: 0.11),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
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
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
        color: theme.colorScheme.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
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

class _SectorFilter {
  const _SectorFilter({required this.sector, required this.count});

  final String sector;
  final int count;
}

List<_SectorFilter> _buildSectorFilters(List<NewsArticle> articles) {
  final counts = <String, int>{};
  for (final article in articles) {
    final sector = article.sector.trim().isEmpty ? '기타' : article.sector;
    counts[sector] = (counts[sector] ?? 0) + 1;
  }

  final filters =
      counts.entries
          .map((entry) => _SectorFilter(sector: entry.key, count: entry.value))
          .toList()
        ..sort((a, b) {
          final countCompare = b.count.compareTo(a.count);
          if (countCompare != 0) {
            return countCompare;
          }
          return a.sector.compareTo(b.sector);
        });

  return [
    _SectorFilter(sector: _allSectorFilter, count: articles.length),
    ...filters,
  ];
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

class _FilteredEmptyView extends StatelessWidget {
  const _FilteredEmptyView({
    required this.sectorFilters,
    required this.selectedSector,
    required this.onFilterChanged,
  });

  final List<_SectorFilter> sectorFilters;
  final String selectedSector;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectorFilterBar(
          filters: sectorFilters,
          selectedSector: selectedSector,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 32),
        Text(
          '선택한 섹터의 뉴스가 없습니다',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
      ],
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
