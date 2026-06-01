import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      elevation: selected ? 2.5 : 1.2,
      shadowColor: theme.colorScheme.primary.withValues(
        alpha: selected ? 0.18 : 0.10,
      ),
      clipBehavior: Clip.antiAlias,
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.48)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? 5 : 0,
              color: theme.colorScheme.primary,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
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
          if (_isUsableUrl(article.url)) ...[
            const SizedBox(height: 14),
            _OriginalLinkButton(url: article.url!),
          ],
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
        color: const Color(0xFFFEFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: scrollable
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: content,
              )
            : Padding(padding: const EdgeInsets.all(26), child: content),
      ),
    );
  }
}

bool _isUsableUrl(String? value) {
  if (value == null || value.trim().isEmpty) {
    return false;
  }
  final uri = Uri.tryParse(value.trim());
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

class _OriginalLinkButton extends StatelessWidget {
  const _OriginalLinkButton({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        onPressed: () => _openUrl(context),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: const Text('원문 보기'),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.parse(url.trim());
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('원문 링크를 열 수 없습니다')));
    }
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
        backgroundColor: color.withValues(alpha: 0.11),
        side: BorderSide.none,
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
