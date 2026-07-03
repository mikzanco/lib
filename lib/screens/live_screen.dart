import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/team.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/live_card.dart';
import '../widgets/team_badge.dart';

class LiveScreen extends StatefulWidget {
  final VoidCallback? onShowCalendar;

  const LiveScreen({super.key, this.onShowCalendar});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  String? _selectedMatchId;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TournamentProvider>(context);
    final liveMatch = provider.matches.firstWhere(
      (m) => m.status == MatchStatus.live,
      orElse: () => MatchModel(id: "", group: "", day: "", time: ""),
    );

    final allSchedMatches = provider.matches.where((m) => m.status == MatchStatus.sched).toList();
    
    // Ordina cronologicamente: Sabato prima di Domenica, poi per orario di gioco
    allSchedMatches.sort((a, b) {
      if (a.day != b.day) {
        if (a.day.contains("Sab")) return -1;
        if (b.day.contains("Sab")) return 1;
      }
      return a.time.compareTo(b.time);
    });

    final upcoming = allSchedMatches.take(5).toList();

    final hasLive = liveMatch.id.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Schermata Live Match Card
          if (hasLive) ...[
            LiveCard(match: liveMatch),
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
                    "🏁",
                    style: TextStyle(fontSize: 48),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Nessuna partita in corso",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Le prossime partite in programma qui sotto",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 2. Prossime Partite
          if (upcoming.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
              child: Text(
                "PROSSIME PARTITE",
                style: TextStyle(
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
              itemCount: upcoming.length,
              separatorBuilder: (c, i) => const SizedBox(height: 8),
              itemBuilder: (c, i) {
                final m = upcoming[i];
                final ht = provider.teams.firstWhere((t) => t.id == m.home, orElse: () => Team(id: 0, name: "?", group: "", color: 0, players: []));
                final at = provider.teams.firstWhere((t) => t.id == m.away, orElse: () => Team(id: 0, name: "?", group: "", color: 0, players: []));

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      TeamBadge(team: ht, size: BadgeSize.sm),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ht.name,
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
                                    at.name,
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
                            Text(
                              "${m.day} · Girone ${m.group}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
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
                      TeamBadge(team: at, size: BadgeSize.sm),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: widget.onShowCalendar,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("📋 ", style: TextStyle(fontSize: 16)),
                    Text(
                      "Vedi Calendario Completo",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 3. Admin Avvia Partita (se non c'è partita live ed è in adminMode)
          if (provider.adminMode && !hasLive && allSchedMatches.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.05),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "⚡ AVVIA PARTITA",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Dropdown partita
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedMatchId,
                        hint: const Text(
                          "Seleziona partita...",
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        dropdownColor: AppColors.cardBg,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.accent),
                        items: allSchedMatches.map((m) {
                          final ht = provider.teams.firstWhere((t) => t.id == m.home, orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []));
                          final at = provider.teams.firstWhere((t) => t.id == m.away, orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []));
                          return DropdownMenuItem<String>(
                            value: m.id,
                            child: Text(
                              "${ht.name} vs ${at.name} · ${m.day} ${m.time}",
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedMatchId = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Avvia ora Button
                  GestureDetector(
                    onTap: _selectedMatchId != null
                        ? () {
                            provider.startMatch(_selectedMatchId!);
                            setState(() {
                              _selectedMatchId = null;
                            });
                          }
                        : null,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _selectedMatchId != null ? 1.0 : 0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "▶ Avvia ora",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ),
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
}
