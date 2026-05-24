import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../audio_player/data/reciter_catalog.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../data/audio_download_service.dart';
import '../../domain/download_task.dart';
import '../providers/downloads_provider.dart';

class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  int? _totalBytes;

  @override
  void initState() {
    super.initState();
    _refreshSize();
  }

  Future<void> _refreshSize() async {
    final bytes =
        await ref.read(downloadsProvider.notifier).totalSizeBytes();
    if (mounted) {
      setState(() => _totalBytes = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncRepo = ref.watch(quranRepositoryProvider);
    final downloads = ref.watch(downloadsProvider);
    final currentReciterId = ref.watch(audioPlayerProvider).reciterId;
    final currentReciter = ReciterCatalog.byId(currentReciterId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléchargements'),
        actions: [
          if (downloads.isNotEmpty)
            IconButton(
              tooltip: 'Tout supprimer',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmDeleteAll(context),
            ),
        ],
      ),
      body: asyncRepo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (repo) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Bandeau d'info espace utilisé
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Icon(
                        Icons.storage_outlined,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Espace utilisé',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              _totalBytes == null
                                  ? 'Calcul…'
                                  : AudioDownloadService.formatBytes(
                                      _totalBytes!,
                                    ),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Récitateur courant
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Récitateur : ${currentReciter.nameEnglish}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                child: Text(
                  'Téléchargez les sourates pour les écouter hors ligne. '
                  'Changez de récitateur dans Settings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Liste des sourates
              ...repo.surahs.map((surah) {
                final task = downloads['$currentReciterId/${surah.number}'];
                return _SurahDownloadTile(
                  surahNumber: surah.number,
                  surahName: surah.nameEnglish,
                  surahNameArabic: surah.nameArabic,
                  versesCount: surah.versesCount,
                  task: task,
                  onDownload: () async {
                    await ref
                        .read(downloadsProvider.notifier)
                        .downloadSurah(
                          reciterId: currentReciterId,
                          surah: surah.number,
                          totalVerses: surah.versesCount,
                        );
                    _refreshSize();
                  },
                  onCancel: () {
                    ref.read(downloadsProvider.notifier).cancel(
                          reciterId: currentReciterId,
                          surah: surah.number,
                        );
                  },
                  onDelete: () async {
                    await ref.read(downloadsProvider.notifier).deleteSurah(
                          reciterId: currentReciterId,
                          surah: surah.number,
                        );
                    _refreshSize();
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer tous les téléchargements ?'),
        content: const Text(
          'Tous les fichiers audio téléchargés seront supprimés. '
          'Vous pourrez les retélécharger plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(downloadsProvider.notifier).deleteAll();
      _refreshSize();
    }
  }
}

class _SurahDownloadTile extends StatelessWidget {
  const _SurahDownloadTile({
    required this.surahNumber,
    required this.surahName,
    required this.surahNameArabic,
    required this.versesCount,
    required this.task,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  final int surahNumber;
  final String surahName;
  final String surahNameArabic;
  final int versesCount;
  final DownloadTask? task;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = task?.status ?? DownloadStatus.notDownloaded;
    final isDownloading = status == DownloadStatus.downloading;
    final isDownloaded = status == DownloadStatus.downloaded;
    final isFailed = status == DownloadStatus.failed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$surahNumber',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahName,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      isDownloading
                          ? '${task?.completedVerses ?? 0} / $versesCount versets'
                          : isFailed
                              ? 'Échec — Appuyez pour réessayer'
                              : '$versesCount versets',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isFailed
                            ? AppColors.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isDownloading) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull / 2),
                        child: LinearProgressIndicator(
                          value: (task!.progressPercent / 100).clamp(0.0, 1.0),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isDownloaded)
                IconButton(
                  tooltip: 'Supprimer',
                  icon: Icon(Icons.delete_outline,
                      color: theme.colorScheme.onSurfaceVariant),
                  onPressed: onDelete,
                )
              else if (isDownloading)
                IconButton(
                  tooltip: 'Annuler',
                  icon: const Icon(Icons.stop_circle_outlined),
                  onPressed: onCancel,
                )
              else
                IconButton(
                  tooltip: 'Télécharger',
                  icon: Icon(
                    isFailed ? Icons.refresh : Icons.download_outlined,
                    color: isFailed
                        ? AppColors.error
                        : theme.colorScheme.primary,
                  ),
                  onPressed: onDownload,
                ),
              if (isDownloaded)
                Icon(
                  Icons.check_circle,
                  color: AppColors.srs5,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
