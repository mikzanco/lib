import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/team.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';
import 'team_badge.dart';

class ScheduledMatchesModal extends StatelessWidget {
  const ScheduledMatchesModal({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TournamentProvider>(context);

    // Filtra partite programmate
    final allSchedMatches = provider.matches.where((m) => m.status == MatchStatus.sched).toList();

    // Ordina cronologicamente: Sabato prima di Domenica, poi per orario di gioco
    allSchedMatches.sort((a, b) {
      if (a.day != b.day) {
        if (a.day.contains("Sab")) return -1;
        if (b.day.contains("Sab")) return 1;
      }
      return a.time.compareTo(b.time);
    });

    // Raggruppamento manuale per giorno mantenendo l'ordine
    final Map<String, List<MatchModel>> groupedMatches = {};
    for (var m in allSchedMatches) {
      groupedMatches[m.day] = (groupedMatches[m.day] ?? [])..add(m);
    }

    final Map<String, Color> chipColors = {
      "A": AppColors.chipA,
      "B": AppColors.chipB,
      "C": AppColors.chipC,
      "D": AppColors.chipD,
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.scaffoldBg,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "📅",
                          style: TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "PARTITE DA GIOCARE",
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 15,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),

              // Lista contenuti
              Expanded(
                child: allSchedMatches.isEmpty
                    ? const Center(
                        child: Text(
                          "Nessuna partita da giocare in programma.",
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: groupedMatches.entries.map((entry) {
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
                                separatorBuilder: (c, i) => const SizedBox(height: 8),
                                itemBuilder: (c, i) {
                                  final m = matchesList[i];
                                  final ht = provider.teams.firstWhere(
                                    (t) => t.id == m.home,
                                    orElse: () => Team(id: 0, name: "?", group: "", color: 0, players: []),
                                  );
                                  final at = provider.teams.firstWhere(
                                    (t) => t.id == m.away,
                                    orElse: () => Team(id: 0, name: "?", group: "", color: 0, players: []),
                                  );

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBg,
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        TeamBadge(team: m.home != null ? ht : null, size: BadgeSize.sm),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      m.home != null ? ht.name : "Da definire",
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                                                    child: Text(
                                                      "vs",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textMuted,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      m.away != null ? at.name : "Da definire",
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    m.group == "KO" ? "Eliminazione Diretta" : "Girone ${m.group}",
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.textTertiary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (m.group != "KO") ...[
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      m.id,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w900,
                                                        color: chipColors[m.group] ?? AppColors.accent,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          m.time,
                                          style: const TextStyle(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        TeamBadge(team: m.away != null ? at : null, size: BadgeSize.sm),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
