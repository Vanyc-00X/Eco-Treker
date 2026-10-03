import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/eco_card.dart';
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

final _challengesDataProvider =
    FutureProvider.autoDispose<_ChallengesData>((ref) async {
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

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_challengesDataProvider);

    return dataAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(_challengesDataProvider),
      ),
      data: (data) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_challengesDataProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const SectionHeader(
                title: 'Active Challenges',
                subtitle: 'Push limits and win rare badges with friends',
                serif: true,
              ),
              const SizedBox(height: 18),
              ...data.challenges.map((challenge) {
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
                      final profile =
                          await ref.read(currentProfileProvider.future);
                      if (profile == null) return;
                      await ChallengesRepository().joinChallenge(
                        challengeId: challenge.id,
                        userId: profile.id,
                      );
                      ref.invalidate(_challengesDataProvider);
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                'Earned Badges',
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
                    'No badges yet — complete a challenge!',
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
                          : 'Earned ${DateFormat('d MMM').format(badge.earnedAt!)}';
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
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.participation,
    required this.onJoin,
  });

  final Challenge challenge;
  final ChallengeParticipation? participation;
  final VoidCallback onJoin;

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
                '${(pct * 100).round()}% Complete',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Spacer(),
              Text(
                challenge.targetKg != null
                    ? '${progress.toStringAsFixed(1)}/${challenge.targetKg!.toStringAsFixed(0)} kg'
                    : joined
                        ? 'Joined'
                        : 'Not joined',
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
              const Icon(Icons.groups_2_outlined,
                  size: 18, color: AppColors.primary),
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
                '${NumberFormat('#,###').format(challenge.rewardPoints)} pts',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (!joined) ...[
            const SizedBox(height: 12),
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
                child: const Text('Take challenge'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}