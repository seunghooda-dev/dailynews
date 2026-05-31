import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NewsSkeleton extends StatelessWidget {
  const NewsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surface;

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Container(
            height: 104,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}
