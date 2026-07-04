import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/team.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_table.dart';
import '../widgets/full_table.dart';
import '../widgets/team_badge.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  String _activeFilter = "all";

  Widget _buildFilterPill(String value, String label) {
    final isSel = _activeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.accent : Colors.transparent,
          border: Border.all(
            color: isSel ? AppColors.accent : AppColors.borderDark,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isSel ? AppColors.black : AppColors.textTertiary,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildKnockoutCard(MatchModel m, TournamentProvider provider) {
    final ht = m.home != null
        ? provider.teams.firstWhere((t) => t.id == m.home,
            orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []))
        : null;
    final at = m.away != null
        ? provider.teams.firstWhere((t) => t.id == m.away,
            orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []))
        : null;

    final isDone = m.status == MatchStatus.done;
    final isLive = m.status == MatchStatus.live;

    int? winner;
    if (isDone) {
      if (m.homeGoals == m.awayGoals) {
        if (m.id.startsWith("OT")) {
          winner = m.home;
        } else {
          final homePen = m.homePenalties ?? 0;
          final awayPen = m.awayPenalties ?? 0;
          winner = homePen > awayPen ? m.home : m.away;
        }
      } else {
        winner = m.homeGoals > m.awayGoals ? m.home : m.away;
      }
    }

    final isHomeWin = winner != null && winner == m.home;
    final isAwayWin = winner != null && winner == m.away;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(
          color: isLive
              ? AppColors.live.withValues(alpha: 0.5)
              : isDone
                  ? AppColors.border
                  : AppColors.borderLight,
          width: isLive ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header con ID e orario
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.id,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTertiary,
                ),
              ),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.live.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "LIVE",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: AppColors.live,
                    ),
                  ),
                )
              else
                Text(
                  "${m.day} · ${m.time}",
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Squadra Casa
          Row(
            children: [
              TeamBadge(team: ht, size: BadgeSize.sm),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ht?.name ?? "TBD",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isHomeWin ? FontWeight.w900 : FontWeight.w700,
                    color: isHomeWin ? AppColors.accent : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDone || isLive)
                Text(
                  "${m.homeGoals}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isHomeWin ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              if ((m.homePenalties != null || m.awayPenalties != null) && isDone) ...[
                const SizedBox(width: 4),
                Text(
                  "(${m.homePenalties ?? 0})",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHomeWin ? AppColors.accent : AppColors.textTertiary,
                  ),
                ),
              ],
              if (isHomeWin) ...[
                const SizedBox(width: 4),
                const Text("✓", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Squadra Trasferta
          Row(
            children: [
              TeamBadge(team: at, size: BadgeSize.sm),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  at?.name ?? "TBD",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isAwayWin ? FontWeight.w900 : FontWeight.w700,
                    color: isAwayWin ? AppColors.accent : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDone || isLive)
                Text(
                  "${m.awayGoals}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isAwayWin ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              if ((m.homePenalties != null || m.awayPenalties != null) && isDone) ...[
                const SizedBox(width: 4),
                Text(
                  "(${m.awayPenalties ?? 0})",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isAwayWin ? AppColors.accent : AppColors.textTertiary,
                  ),
                ),
              ],
              if (isAwayWin) ...[
                const SizedBox(width: 4),
                const Text("✓", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ],
          ),

          // Extra time
          if (m.isExtraTime && isDone) ...[
            const SizedBox(height: 6),
            const Text(
              "D.T.S. (Golden Goal)",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TournamentProvider>(context);

    // Controlla se ci sono partite KO
    final hasKoMatches = provider.matches.any((m) => m.group == "KO");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pills filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterPill("all", "TUTTI"),
                const SizedBox(width: 8),
                _buildFilterPill("A", "GIRONE A"),
                const SizedBox(width: 8),
                _buildFilterPill("B", "GIRONE B"),
                const SizedBox(width: 8),
                _buildFilterPill("C", "GIRONE C"),
                const SizedBox(width: 8),
                _buildFilterPill("D", "GIRONE D"),
                if (hasKoMatches) ...[
                  const SizedBox(width: 8),
                  _buildFilterPill("KO", "⚔ SCONTRI DIRETTI"),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Standings tables (gironi)
          if (_activeFilter == "all") ...[
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.68,
              children: [
                MiniTable(group: "A", teams: provider.teams, matches: provider.matches),
                MiniTable(group: "B", teams: provider.teams, matches: provider.matches),
                MiniTable(group: "C", teams: provider.teams, matches: provider.matches),
                MiniTable(group: "D", teams: provider.teams, matches: provider.matches),
              ],
            ),
          ] else if (_activeFilter == "KO") ...[
            // Sezione Scontri Diretti
            _buildKnockoutSection(provider),
          ] else ...[
            FullTable(group: _activeFilter, teams: provider.teams, matches: provider.matches),
          ],
          
          const SizedBox(height: 24),

          // Legend (solo per gironi)
          if (_activeFilter != "KO") ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceBg.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Qualificata agli Ottavi (1°–4° posto)",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Eliminata (5° posto)",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKnockoutSection(TournamentProvider provider) {
    final phases = [
      {"label": "⚔ OTTAVI DI FINALE", "ids": [for (int i = 1; i <= 8; i++) "OT$i"]},
      {"label": "🏅 QUARTI DI FINALE", "ids": [for (int i = 1; i <= 4; i++) "QF$i"]},
      {"label": "🔥 SEMIFINALI", "ids": ["SF1", "SF2"]},
      {"label": "🥉 FINALE 3°/4° POSTO", "ids": ["F3"]},
      {"label": "🏆 FINALE", "ids": ["F"]},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...phases.map((phase) {
          final ids = phase["ids"] as List<String>;
          final matchesList = provider.matches
              .where((m) => ids.contains(m.id))
              .toList();

          if (matchesList.isEmpty) return const SizedBox.shrink();

          final doneCount = matchesList.where((m) => m.status == MatchStatus.done).length;
          final totalCount = matchesList.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header fase
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBg.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      phase["label"] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: doneCount == totalCount
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.surfaceBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$doneCount/$totalCount",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: doneCount == totalCount
                              ? AppColors.success
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Cards partite
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matchesList.length,
                separatorBuilder: (c, i) => const SizedBox(height: 8),
                itemBuilder: (c, i) => _buildKnockoutCard(matchesList[i], provider),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }
}
