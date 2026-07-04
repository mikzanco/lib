import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/team.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/team_badge.dart';
import '../widgets/live_dot.dart';
import '../widgets/goal_panel.dart';

class BracketScreen extends StatefulWidget {
  const BracketScreen({super.key});

  @override
  State<BracketScreen> createState() => _BracketScreenState();
}

class _BracketScreenState extends State<BracketScreen> {
  // Configurazione dei bottoni per inserimento rapido gol nel tabellone KO

  void _openGoalModal(MatchModel match, String side) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GoalPanel(
          match: match,
          side: side,
          timer: match.homeGoals + match.awayGoals + 5, // tempo fittizio incrementale
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TournamentProvider>(context);

    // Controlla se tutti i match dei gironi (A1-D8) sono terminati (status == done)
    final groupMatches = provider.matches.where((m) => m.group != "KO");
    final groupDone = groupMatches.isNotEmpty && groupMatches.every((m) => m.status == MatchStatus.done);

    final bracketMatchIds = [
      for (int i = 1; i <= 8; i++) "OT$i",
      for (int i = 1; i <= 4; i++) "QF$i",
      "SF1",
      "SF2",
      "F3",
      "F"
    ];
    final bracketMatches = provider.matches.where((m) => bracketMatchIds.contains(m.id)).toList();

    final phases = [
      {"label": "Ottavi di Finale", "ids": [for (int i = 1; i <= 8; i++) "OT$i"]},
      {"label": "Quarti di Finale", "ids": [for (int i = 1; i <= 4; i++) "QF$i"]},
      {"label": "Semifinali", "ids": ["SF1", "SF2"]},
      {"label": "Finale 3°/4° posto", "ids": ["F3"]},
      {"label": "🏆 Finale", "ids": ["F"]},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Fase gironi ancora in corso
          if (!groupDone) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Text(
                    "⏳",
                    style: TextStyle(fontSize: 48),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Il tabellone si genera al termine della fase a gironi",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Tutte le partite dei gironi devono essere completate",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // ⚠️ PULSANTE TEST: Simula risultati (solo admin)
            if (provider.adminMode) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  await provider.seedFakeResults();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Risultati fittizi inseriti! Ricarica la pagina."),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("🧪", style: TextStyle(fontSize: 15)),
                      SizedBox(width: 8),
                      Text(
                        "SIMULA RISULTATI GIRONI (TEST)",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.warning,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],

          // 2. Gironi finiti, tabellone non ancora generato
          if (groupDone && bracketMatches.isEmpty) ...[
            if (provider.adminMode) ...[
              GestureDetector(
                onTap: () => provider.generateBracket(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "🏆 ",
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        "Genera Tabellone",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Text(
                      "🔒",
                      style: TextStyle(fontSize: 36),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "In attesa che l'Admin generi il tabellone",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // 3. Tabellone generato ed in corso
          if (bracketMatches.isNotEmpty) ...[
            ...phases.map((phase) {
              final label = phase["label"] as String;
              final ids = phase["ids"] as List<String>;
              final matchesList = provider.matches.where((m) => ids.contains(m.id)).toList();

              if (matchesList.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, top: 12.0, bottom: 8.0),
                    child: Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: matchesList.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 8),
                    itemBuilder: (c, i) {
                      final m = matchesList[i];
                      final ht = m.home != null
                          ? provider.teams.firstWhere((t) => t.id == m.home, orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []))
                          : null;
                      final at = m.away != null
                          ? provider.teams.firstWhere((t) => t.id == m.away, orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []))
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

                      final isHomeWinner = winner != null && winner == m.home;
                      final isAwayWinner = winner != null && winner == m.away;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          border: Border.all(
                            color: isLive ? AppColors.live.withValues(alpha: 0.5) : AppColors.border,
                            width: isLive ? 2.0 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Match header (ID & Extra Time indicator)
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
                                if (m.isExtraTime)
                                  const Text(
                                    "D.T.S. (Golden Goal)",
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Squadra Casa Row
                            Opacity(
                              opacity: isDone && !isHomeWinner ? 0.6 : 1.0,
                              child: Row(
                                children: [
                                  TeamBadge(team: ht, size: BadgeSize.sm),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      ht?.name ?? "TBD",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isHomeWinner ? FontWeight.w900 : FontWeight.w700,
                                        color: isHomeWinner ? AppColors.accent : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isDone || isLive) ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "${m.homeGoals}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: isHomeWinner ? AppColors.accent : AppColors.textSecondary,
                                          ),
                                        ),
                                        if (m.homePenalties != null || m.awayPenalties != null) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            "(${m.homePenalties ?? 0})",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isHomeWinner ? AppColors.accent : AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                  if (isHomeWinner) ...[
                                    const SizedBox(width: 6),
                                    const Text("✓", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Squadra Trasferta Row
                            Opacity(
                              opacity: isDone && !isAwayWinner ? 0.6 : 1.0,
                              child: Row(
                                children: [
                                  TeamBadge(team: at, size: BadgeSize.sm),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      at?.name ?? "TBD",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isAwayWinner ? FontWeight.w900 : FontWeight.w700,
                                        color: isAwayWinner ? AppColors.accent : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isDone || isLive) ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "${m.awayGoals}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: isAwayWinner ? AppColors.accent : AppColors.textSecondary,
                                          ),
                                        ),
                                        if (m.homePenalties != null || m.awayPenalties != null) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            "(${m.awayPenalties ?? 0})",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isAwayWinner ? AppColors.accent : AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                  if (isAwayWinner) ...[
                                    const SizedBox(width: 6),
                                    const Text("✓", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                            ),

                            // Controlli partita in corso / da avviare
                            if (isLive) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.only(top: 8),
                                decoration: const BoxDecoration(
                                  border: Border(top: BorderSide(color: AppColors.border)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const LiveDot(),
                                    if (provider.adminMode) ...[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _openGoalModal(m, 'home'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceBg,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text("⚽ C", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () => _openGoalModal(m, 'away'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceBg,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text("⚽ T", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              if (m.homeGoals == m.awayGoals) {
                                                if (m.id.startsWith("OT")) {
                                                  provider.endMatch(m.id);
                                                } else {
                                                  final homePen = m.homePenalties ?? 0;
                                                  final awayPen = m.awayPenalties ?? 0;
                                                  if (homePen == awayPen) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text("Inserire i rigori per decidere il vincitore!"),
                                                        backgroundColor: AppColors.error,
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  provider.endMatch(m.id);
                                                }
                                              } else {
                                                provider.endMatch(m.id);
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.error.withValues(alpha: 0.15),
                                                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text("🏁 Fine", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.error)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            // Bottone per avviare partita schedulata (solo per admin)
                            if (m.status == MatchStatus.sched && provider.adminMode && ht != null && at != null) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => provider.startMatch(m.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.borderDark),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "▶ Avvia Partita",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}
