import 'dart:math';

import 'package:flutter/material.dart';

import '../models/news_article.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({
    required this.article,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final NewsArticle article;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = sectorColor(article.sector);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.68)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 4,
              color: selected ? theme.colorScheme.primary : color,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _SectorChip(label: article.sector, color: color),
                        const Spacer(),
                        AnimatedOpacity(
                          opacity: selected ? 1 : 0,
                          duration: const Duration(milliseconds: 160),
                          child: Icon(
                            Icons.check,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      article.whatHappened,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            article.source ?? '뉴스',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        if (article.publishedAt != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              article.publishedAt!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleDetailPanel extends StatelessWidget {
  const ArticleDetailPanel({
    required this.article,
    this.scrollable = true,
    super.key,
  });

  final NewsArticle article;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = sectorColor(article.sector);

    final content = SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectorChip(label: article.sector, color: color),
          const SizedBox(height: 16),
          Text(article.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(
            [
              if (article.source != null) article.source,
              if (article.publishedAt != null) article.publishedAt,
            ].whereType<String>().join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 22),
          const Divider(height: 1),
          _ArticleSection(
            icon: Icons.lightbulb_outline,
            title: '핵심 팩트 및 수치',
            body: article.whatHappened,
          ),
          _ArticleSection(
            icon: Icons.search,
            title: '시장 배경 분석',
            body: article.context,
          ),
          _ArticleSection(
            icon: Icons.trending_up,
            title: '향후 주가 전망',
            body: article.implication,
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: scrollable
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: content,
              )
            : Padding(padding: const EdgeInsets.all(24), child: content),
      ),
    );
  }
}

Color sectorColor(String sector) {
  const colors = [
    Color(0xFF0077C8),
    Color(0xFFFFB703),
    Color(0xFF00A896),
    Color(0xFFFF7A6B),
    Color(0xFF7C5CFF),
    Color(0xFF00B4D8),
  ];
  final index = sector.runes.fold<int>(0, (sum, rune) => sum + rune);
  return colors[index % max(colors.length, 1)];
}

class _SectorChip extends StatelessWidget {
  const _SectorChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Chip(
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide(color: color.withValues(alpha: 0.34)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ArticleSection extends StatelessWidget {
  const _ArticleSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
