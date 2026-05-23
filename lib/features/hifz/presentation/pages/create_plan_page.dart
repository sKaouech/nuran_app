import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../domain/hifz_plan.dart';
import '../providers/hifz_plan_provider.dart';

class CreatePlanPage extends ConsumerStatefulWidget {
  const CreatePlanPage({super.key});

  @override
  ConsumerState<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends ConsumerState<CreatePlanPage> {
  late HifzGoal _goal;
  late int _startSurah;
  late int? _target;
  late int _versesPerDay;
  late final bool _isEditMode;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(hifzPlanProvider);
    _isEditMode = existing != null;
    _goal = existing?.goal ?? HifzGoal.surah;
    _startSurah = existing?.startSurah ?? 78;
    _target = existing?.targetSurahOrJuz ??
        (existing?.goal == HifzGoal.juz ? 30 : 114);
    _versesPerDay = existing?.versesPerDay ?? 5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncRepo = ref.watch(quranRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier mon plan' : 'Créer mon plan'),
      ),
      body: asyncRepo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (repo) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Objectif',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<HifzGoal>(
              segments: const [
                ButtonSegment(
                  value: HifzGoal.surah,
                  label: Text('Sourate'),
                  icon: Icon(Icons.menu_book_outlined),
                ),
                ButtonSegment(
                  value: HifzGoal.juz,
                  label: Text('Juz'),
                  icon: Icon(Icons.bookmark_outline),
                ),
                ButtonSegment(
                  value: HifzGoal.fullQuran,
                  label: Text('Coran complet'),
                  icon: Icon(Icons.auto_stories_outlined),
                ),
              ],
              selected: {_goal},
              onSelectionChanged: (s) => setState(() {
                _goal = s.first;
                _target = _goal == HifzGoal.juz ? 30 : 114;
              }),
            ),

            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Sourate de départ',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<int>(
              initialValue: _startSurah,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                for (final s in repo.surahs)
                  DropdownMenuItem(
                    value: s.number,
                    child: Text('${s.number}. ${s.nameEnglish}'),
                  ),
              ],
              onChanged: (v) => setState(() => _startSurah = v ?? 1),
            ),

            if (_goal != HifzGoal.fullQuran) ...[
              const SizedBox(height: AppSpacing.xxl),
              Text(
                _goal == HifzGoal.surah
                    ? 'Jusqu\'à la sourate'
                    : 'Juz cible',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<int>(
                initialValue: _target,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _goal == HifzGoal.surah
                    ? [
                        for (final s in repo.surahs)
                          if (s.number >= _startSurah)
                            DropdownMenuItem(
                              value: s.number,
                              child: Text('${s.number}. ${s.nameEnglish}'),
                            ),
                      ]
                    : [
                        for (var j = 1; j <= 30; j++)
                          DropdownMenuItem(
                            value: j,
                            child: Text('Juz $j'),
                          ),
                      ],
                onChanged: (v) => setState(() => _target = v),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Cadence',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [1, 3, 5, 10, 20].map((n) {
                return ChoiceChip(
                  label: Text('$n versets/jour'),
                  selected: _versesPerDay == n,
                  onSelected: (_) => setState(() => _versesPerDay = n),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.xxxl),
            FilledButton.icon(
              onPressed: () {
                ref.read(hifzPlanProvider.notifier).setPlan(
                      HifzPlan(
                        goal: _goal,
                        startSurah: _startSurah,
                        targetSurahOrJuz:
                            _goal == HifzGoal.fullQuran ? null : _target,
                        versesPerDay: _versesPerDay,
                        startedAt: DateTime.now().millisecondsSinceEpoch,
                      ),
                    );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: Text(_isEditMode ? 'Enregistrer' : 'Créer le plan'),
            ),
          ],
        ),
      ),
    );
  }
}
