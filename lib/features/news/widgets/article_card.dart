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
      elevation: selected ? 2 : 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
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
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      Icons.check_circle,
                      size: 20,
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                article.whatHappened,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.newspaper,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      article.source ?? '뉴스',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (article.publishedAt != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        article.publishedAt!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
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
          const SizedBox(height: 14),
          Text(
            article.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            [
              if (article.source != null) article.source,
              if (article.publishedAt != null) article.publishedAt,
            ].whereType<String>().join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
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

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: scrollable
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: content,
            )
          : Padding(padding: const EdgeInsets.all(24), child: content),
    );
  }
}

Color sectorColor(String sector) {
  const colors = [
    Color(0xFF176B5D),
    Color(0xFFB25E09),
    Color(0xFF345995),
    Color(0xFF8E3B46),
    Color(0xFF4C6B36),
    Color(0xFF6D597A),
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
        side: BorderSide(color: color.withValues(alpha: 0.24)),
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
      padding: const EdgeInsets.only(top: 18),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
