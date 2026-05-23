import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bookmarks_provider.dart';

class BookmarkButton extends ConsumerWidget {
  const BookmarkButton({super.key, required this.globalIndex});

  final int globalIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isBookmarked =
        ref.watch(bookmarksProvider).containsKey(globalIndex);
    return IconButton(
      onPressed: () =>
          ref.read(bookmarksProvider.notifier).toggle(globalIndex),
      tooltip: isBookmarked ? 'Retirer le signet' : 'Ajouter un signet',
      icon: Icon(
        isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
        color: isBookmarked
            ? theme.colorScheme.secondary
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
