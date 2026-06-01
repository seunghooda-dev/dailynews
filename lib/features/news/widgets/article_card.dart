import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

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
    final hotColor = const Color(0xFFE25555);
    final borderColor = article.isHotIssue
        ? hotColor.withValues(alpha: 0.48)
        : theme.colorScheme.primary.withValues(alpha: 0.34);

    return Card(
      margin: EdgeInsets.zero,
      elevation: article.isHotIssue
          ? 4.5
          : selected
          ? 4
          : 1.1,
      shadowColor: theme.colorScheme.primary.withValues(
        alpha: article.isHotIssue
            ? 0.18
            : selected
            ? 0.24
            : 0.08,
      ),
      clipBehavior: Clip.antiAlias,
      color: selected ? const Color(0xFFF0F7FF) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: article.isHotIssue || selected
            ? BorderSide(color: borderColor)
            : BorderSide.none,
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _SectorChip(label: article.sector, color: color),
                            ],
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.88,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (article.isHotIssue) ...[
                      const SizedBox(height: 6),
                      _ReportCountBadge(count: article.clusterCount),
                    ],
                    if (article.isHotIssue && article.issueKeyword != null) ...[
                      const SizedBox(height: 5),
                      _IssueKeywordBadge(label: article.issueKeyword!),
                    ],
                    const SizedBox(height: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            article.sourceSummary,
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

    final articleContent = SelectionArea(
      child: _ArticleDetailContent(article: article, color: color),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        articleContent,
        if (_parseUsableUrl(article.url) case final uri?) ...[
          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 18),
          _OriginalLinkButton(uri: uri),
        ],
      ],
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

class _ArticleDetailContent extends StatelessWidget {
  const _ArticleDetailContent({required this.article, required this.color});

  final NewsArticle article;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SectorChip(label: article.sector, color: color),
            if (article.isHotIssue)
              _ReportCountBadge(count: article.clusterCount),
          ],
        ),
        if (article.isHotIssue && article.issueKeyword != null) ...[
          const SizedBox(height: 14),
          _IssueKeywordBadge(label: article.issueKeyword!, compact: false),
        ],
        const SizedBox(height: 16),
        Text(
          article.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 27,
            height: 1.32,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          [
            article.sourceSummary,
            if (article.publishedAt != null) article.publishedAt,
          ].whereType<String>().join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        if (article.relatedSources.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '관련 보도: ${_formatRelatedSources(article.relatedSources)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
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
    );
  }
}

Uri? _parseUsableUrl(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(value.trim());
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  return uri;
}

class _OriginalLinkButton extends StatelessWidget {
  const _OriginalLinkButton({required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Link(
        uri: uri,
        target: LinkTarget.blank,
        builder: (context, followLink) => FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          onPressed: followLink,
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('원문 보기'),
        ),
      ),
    );
  }
}

Color sectorColor(String sector) {
  final normalized = sector.toLowerCase();
  if (_containsAny(normalized, const ['반도체', 'hbm', 'd램', '메모리'])) {
    return const Color(0xFF0077C8);
  }
  if (_containsAny(normalized, const ['금융', '은행', '증권', '보험', '채권'])) {
    return const Color(0xFF16845B);
  }
  if (_containsAny(normalized, const ['방산', '우주', '항공', '수출'])) {
    return const Color(0xFFB26A00);
  }
  if (_containsAny(normalized, const ['금리', '환율', '매크로', 'fed', '연준'])) {
    return const Color(0xFF6F5BD6);
  }
  if (_containsAny(normalized, const ['가상자산', '비트코인', '코인'])) {
    return const Color(0xFFE06C00);
  }
  if (_containsAny(normalized, const ['자동차', '전기차', '배터리'])) {
    return const Color(0xFF007A7A);
  }
  if (_containsAny(normalized, const ['바이오', '제약', '헬스'])) {
    return const Color(0xFFC24178);
  }
  if (_containsAny(normalized, const ['전력', '원전', 'ess', '인프라'])) {
    return const Color(0xFF07866B);
  }
  if (_containsAny(normalized, const ['ai', '인공지능', '데이터센터'])) {
    return const Color(0xFF4267D6);
  }
  return const Color(0xFF3F6F94);
}

bool _containsAny(String value, List<String> needles) {
  return needles.any((needle) => value.contains(needle.toLowerCase()));
}

class _SectorChip extends StatelessWidget {
  const _SectorChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _IssueKeywordBadge extends StatelessWidget {
  const _IssueKeywordBadge({required this.label, this.compact = true});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 168 : 360),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2F5),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 4 : 5,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFF596675),
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ReportCountBadge extends StatelessWidget {
  const _ReportCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        '($count곳 보도)',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFE25555),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

String _formatRelatedSources(List<String> sources) {
  const previewCount = 4;
  final preview = sources.take(previewCount).join(', ');
  final rest = sources.length - previewCount;
  if (rest <= 0) {
    return preview;
  }
  return '$preview 외 $rest곳';
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
