import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/team.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/team_badge.dart';
import '../utils/player_resolver.dart';
import '../widgets/match_edit_modal.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TournamentProvider>(context);

    // Filtra partite concluse
    final doneMatches = provider.matches
        .where((m) =>
            m.status == MatchStatus.done &&
            (_activeFilter == "all" || m.group == _activeFilter))
        .toList();

    // Raggruppamento manuale per giorno mantenendo l'ordine
    final Map<String, List<MatchModel>> groupedMatches = {};
    for (var m in doneMatches) {
      groupedMatches[m.day] = (groupedMatches[m.day] ?? [])..add(m);
    }

    final Map<String, Color> chipColors = {
      "A": AppColors.chipA,
      "B": AppColors.chipB,
      "C": AppColors.chipC,
      "D": AppColors.chipD,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtri gironi
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Se vuoto
          if (doneMatches.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  "Nessun risultato disponibile per i filtri selezionati",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Lista partite raggruppate per giorno
            ...groupedMatches.entries.map((entry) {
              final day = entry.key;
              final matchesList = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, top: 8.0, bottom: 12.0),
                    child: Text(
                      day.toUpperCase(),
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
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (c, i) {
                      final m = matchesList[i];
                      final ht = provider.teams.firstWhere((t) => t.id == m.home, orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []));
                      final at = provider.teams.firstWhere((t) => t.id == m.away, orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []));

                      final homeScorers = m.scorers.where((s) => (s.team == m.home && !s.own) || (s.team == m.away && s.own)).toList();
                      final awayScorers = m.scorers.where((s) => (s.team == m.away && !s.own) || (s.team == m.home && s.own)).toList();

                      final homeWon = m.homeGoals > m.awayGoals;
                      final awayWon = m.awayGoals > m.homeGoals;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                // Badge Casa
                                TeamBadge(team: ht, size: BadgeSize.sm),
                                const SizedBox(width: 12),
                                
                                // Nomi e punteggi
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Casa Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ht.name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: homeWon ? FontWeight.w900 : FontWeight.w700,
                                                color: homeWon ? AppColors.white : AppColors.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            "${m.homeGoals}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: homeWon ? AppColors.white : AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Trasferta Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              at.name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: awayWon ? FontWeight.w900 : FontWeight.w700,
                                                color: awayWon ? AppColors.white : AppColors.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            "${m.awayGoals}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: awayWon ? AppColors.white : AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Badge Trasferta
                                TeamBadge(team: at, size: BadgeSize.sm),
                                
                                // Chip Girone
                                const SizedBox(width: 8),
                                Text(
                                  m.group,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: chipColors[m.group] ?? AppColors.accent,
                                  ),
                                ),
                                if (provider.adminMode) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => MatchEditModal(match: m),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit, size: 10, color: AppColors.accent),
                                          SizedBox(width: 4),
                                          Text(
                                            "EDIT",
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // Marcatori
                            if (m.scorers.isNotEmpty) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.only(top: 8),
                                decoration: const BoxDecoration(
                                  border: Border(top: BorderSide(color: AppColors.border)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Marcatori Casa
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: homeScorers.map((s) {
                                          final pName = resolvePlayerName(provider.teams, s.team, s.n, s.player);
                                          return Text(
                                            s.own 
                                                ? (s.player != null ? "$pName (A.G.) ${s.min}'" : "Autogol (A.G.) ${s.min}'")
                                                : "$pName ${s.min}'",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: s.own ? AppColors.error : AppColors.textTertiary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Marcatori Trasferta
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: awayScorers.map((s) {
                                          final pName = resolvePlayerName(provider.teams, s.team, s.n, s.player);
                                          return Text(
                                            s.own 
                                                ? (s.player != null ? "$pName (A.G.) ${s.min}'" : "Autogol (A.G.) ${s.min}'")
                                                : "$pName ${s.min}'",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: s.own ? AppColors.error : AppColors.textTertiary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
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
