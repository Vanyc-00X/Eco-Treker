import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/challenges_repository.dart';
import '../models/challenge.dart';

class _ChallengesData {
  const _ChallengesData({
    required this.challenges,
    required this.participations,
    required this.achievements,
  });

  final List<Challenge> challenges;
  final List<ChallengeParticipation> participations;
  final List<Achievement> achievements;
}

final _challengesDataProvider = FutureProvider.autoDispose<_ChallengesData>((
  ref,
) async {
  final profile = await ref.watch(currentProfileProvider.future);
  final repo = ChallengesRepository();
  final challenges = await repo.fetchChallenges();
  if (profile == null) {
    return _ChallengesData(
      challenges: challenges,
      participations: const [],
      achievements: const [],
    );
  }
  final parts = await repo.fetchParticipations(profile.id);
  final badges = await repo.fetchUserAchievements(profile.id);
  return _ChallengesData(
    challenges: challenges,
    participations: parts,
    achievements: badges,
  );
});

/// Фильтр по `challenge_type`; `all` — без фильтрации.
class ChallengeFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String value) => state = value;
}

final _typeFilterProvider = NotifierProvider<ChallengeFilterNotifier, String>(
  ChallengeFilterNotifier.new,
);

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_challengesDataProvider);
    final filter = ref.watch(_typeFilterProvider);

    return AppPage(
      child: dataAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_challengesDataProvider),
        ),
        data: (data) {
          final visible = filter == 'all'
              ? data.challenges
              : data.challenges
                    .where((c) => c.challengeType == filter)
                    .toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(_challengesDataProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const SectionHeader(
                  title: AppRu.activeChallenges,
                  subtitle: AppRu.challengesSubtitle,
                  serif: true,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final option in _filterOptions)
                        _TypeChip(
                          label: option.label,
                          selected: filter == option.value,
                          onTap: () => ref
                              .read(_typeFilterProvider.notifier)
                              .setFilter(option.value),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: EmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: AppRu.noChallenges,
                      subtitle: AppRu.noChallengesHint,
                    ),
                  ),
                ...visible.map((challenge) {
                  ChallengeParticipation? part;
                  for (final p in data.participations) {
                    if (p.challengeId == challenge.id) {
                      part = p;
                      break;
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChallengeCard(
                      challenge: challenge,
                      participation: part,
                      onJoin: () async {
                        final profile = await ref.read(
                          currentProfileProvider.future,
                        );
                        if (profile == null) return;
                        await ChallengesRepository().joinChallenge(
                          challengeId: challenge.id,
                          userId: profile.id,
                        );
                        ref.invalidate(_challengesDataProvider);
                      },
                      onAbandon: () async {
                        await ChallengesRepository()
                            .abandonChallenge(challenge.id);
                        ref.invalidate(_challengesDataProvider);
                      },
                      onShare: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text:
                                'Челлендж «${challenge.title}» в Campus Eco-Tracker! '
                                '+${challenge.rewardPoints} баллов',
                          ),
                        );
                      },
                      onProof: () async {
                        final profile = await ref.read(
                          currentProfileProvider.future,
                        );
                        if (profile == null) return;
                        final file = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                          imageQuality: 75,
                        );
                        if (file == null) return;
                        final bytes = await file.readAsBytes();
                        await ChallengesRepository().uploadProof(
                          challengeId: challenge.id,
                          userId: profile.id,
                          bytes: bytes,
                          ext: 'jpg',
                        );
                        ref.invalidate(_challengesDataProvider);
                      },
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  AppRu.earnedBadges,
                  style: GoogleFonts.libreBaskerville(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                if (data.achievements.isEmpty)
                  const EcoCard(
                    child: Text(
                      AppRu.noBadges,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.achievements.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final badge = data.achievements[index];
                        final when = badge.earnedAt == null
                            ? ''
                            : '${AppRu.earnedOn} ${DateFormat('d MMM', 'ru').format(badge.earnedAt!)}';
                        return EcoCard(
                          child: SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.mint,
                                  child: Icon(
                                    Icons.military_tech_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  badge.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  when,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

const _filterOptions = <({String value, String label})>[
  (value: 'all', label: AppRu.filterAll),
  (value: 'daily', label: AppRu.typeDaily),
  (value: 'weekly', label: AppRu.typeWeekly),
  (value: 'team', label: AppRu.filterTeam),
  (value: 'individual', label: AppRu.typeIndividual),
  (value: 'seasonal', label: 'Сезон'),
  (value: 'special', label: 'Special'),
];

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.participation,
    required this.onJoin,
    required this.onAbandon,
    required this.onShare,
    required this.onProof,
  });

  final Challenge challenge;
  final ChallengeParticipation? participation;
  final VoidCallback onJoin;
  final VoidCallback onAbandon;
  final VoidCallback onShare;
  final VoidCallback onProof;

  @override
  Widget build(BuildContext context) {
    final target = challenge.targetKg ?? 1;
    final progress = participation?.progressKg ?? 0;
    final pct = (progress / target).clamp(0, 1).toDouble();
    final joined = participation != null;

    return EcoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                challenge.timeLeftLabel,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              challenge.typeLabel,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${(pct * 100).round()}% ${AppRu.percentComplete}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Spacer(),
              Text(
                challenge.targetKg != null
                    ? '${progress.toStringAsFixed(1)}/${challenge.targetKg!.toStringAsFixed(0)} кг'
                    : joined
                    ? AppRu.joined
                    : AppRu.notJoined,
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.progressTrack,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.groups_2_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  challenge.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              Text(
                '${NumberFormat('#,###', 'ru').format(challenge.rewardPoints)} ${AppRu.pointsShort}',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!joined)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onJoin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(AppRu.takeChallenge),
              ),
            )
          else
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onAbandon,
                  child: const Text(AppRu.abandonChallenge),
                ),
                OutlinedButton(
                  onPressed: onProof,
                  child: const Text(AppRu.uploadProof),
                ),
              ],
            ),
          TextButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text(AppRu.share),
          ),
        ],
      ),
    );
  }
}
