import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/team.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';
import 'team_badge.dart';
import 'live_dot.dart';
import 'goal_panel.dart';

class LiveCard extends StatefulWidget {
  final MatchModel match;

  const LiveCard({
    super.key,
    required this.match,
  });

  @override
  State<LiveCard> createState() => _LiveCardState();
}

class _LiveCardState extends State<LiveCard> {
  late int _elapsedSeconds;
  Timer? _secondTimer;

  int get _maxDuration {
    if (widget.match.group != 'KO') {
      return 12; // tempo unico da 12' per i gironi
    }
    // Fase a eliminazione diretta
    if (widget.match.id.startsWith("OT") || widget.match.id.startsWith("QF") || widget.match.id.startsWith("SF")) {
      int base = 20; // un tempo da 20'
      return widget.match.isExtraTime ? base + 5 : base;
    }
    if (widget.match.id == "F3") {
      return 10; // finalina un tempo da 10'
    }
    if (widget.match.id == "F") {
      int base = 30; // due tempi da 15'
      return widget.match.isExtraTime ? base + 5 : base;
    }
    return 20; // default KO
  }

  int get _minute => ((_elapsedSeconds ~/ 60) + 1).clamp(1, _maxDuration);

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');
    return "$minutesStr:$secondsStr";
  }

  @override
  void initState() {
    super.initState();
    // Inizializza a 1 (o l'ultimo marcatore + 1 per realismo)
    int initialMin = 1;
    if (widget.match.scorers.isNotEmpty) {
      final maxMin = widget.match.scorers.map((s) => s.min).reduce((a, b) => a > b ? a : b);
      initialMin = maxMin + 1;
    }
    initialMin = initialMin.clamp(1, _maxDuration);
    _elapsedSeconds = (initialMin - 1) * 60;

    _startTimer();
  }

  void _startTimer() {
    _secondTimer?.cancel();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_elapsedSeconds < _maxDuration * 60) {
            _elapsedSeconds++;
          } else {
            _secondTimer?.cancel();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant LiveCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxSec = _maxDuration * 60;
    if (_elapsedSeconds > maxSec) {
      _elapsedSeconds = maxSec;
    }
    if (_elapsedSeconds < maxSec && (_secondTimer == null || !_secondTimer!.isActive)) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _secondTimer?.cancel();
    super.dispose();
  }

  void _openGoalModal(String side) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GoalPanel(
          match: widget.match,
          side: side,
          timer: _minute,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TournamentProvider>(context);
    final ht = provider.teams.firstWhere((t) => t.id == widget.match.home, orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []));
    final at = provider.teams.firstWhere((t) => t.id == widget.match.away, orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []));

    final homeScorers = widget.match.scorers.where((s) => (s.team == widget.match.home && !s.own) || (s.team == widget.match.away && s.own)).toList();
    final awayScorers = widget.match.scorers.where((s) => (s.team == widget.match.away && !s.own) || (s.team == widget.match.home && s.own)).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra a gradiente neon in alto (coordinata con il logo)
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: AppColors.logoGradient,
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
              color: AppColors.cardBg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Girone ${widget.match.group} · ${widget.match.day}",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textTertiary,
                    letterSpacing: 1.0,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LiveDot(),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_elapsedSeconds),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Match main body (scores & badges)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                // Team Casa
                Expanded(
                  child: Column(
                    children: [
                      TeamBadge(team: ht, size: BadgeSize.lg),
                      const SizedBox(height: 8),
                      Text(
                        ht.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Giant Score Display
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${widget.match.homeGoals}",
                          style: AppTextStyles.score,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "–",
                            style: AppTextStyles.scoreDivider,
                          ),
                        ),
                        Text(
                          "${widget.match.awayGoals}",
                          style: AppTextStyles.score,
                        ),
                      ],
                    ),
                    if (widget.match.isExtraTime)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "D.T.S. (Golden Goal)",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                    if (widget.match.homePenalties != null || widget.match.awayPenalties != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Rigori: ${widget.match.homePenalties ?? 0} – ${widget.match.awayPenalties ?? 0}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Visualizzazione Falli
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.match.homeFouls >= 5
                                ? AppColors.error.withValues(alpha: 0.15)
                                : AppColors.surfaceBg.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: widget.match.homeFouls >= 5
                                  ? AppColors.error
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "FALLI: ${widget.match.homeFouls}",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: widget.match.homeFouls >= 5
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.match.awayFouls >= 5
                                ? AppColors.error.withValues(alpha: 0.15)
                                : AppColors.surfaceBg.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: widget.match.awayFouls >= 5
                                  ? AppColors.error
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "FALLI: ${widget.match.awayFouls}",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: widget.match.awayFouls >= 5
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.match.group == 'KO') ...[
                      if (widget.match.homeFouls >= 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            widget.match.homeFouls == 5
                                ? "⚠️ Bonus esaurito ${ht.name.split(' ')[0]}: Prossimo fallo Tiro Libero"
                                : "🚨 TIRO LIBERO per ogni fallo commesso da ${ht.name.split(' ')[0]}!",
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (widget.match.awayFouls >= 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            widget.match.awayFouls == 5
                                ? "⚠️ Bonus esaurito ${at.name.split(' ')[0]}: Prossimo fallo Tiro Libero"
                                : "🚨 TIRO LIBERO per ogni fallo commesso da ${at.name.split(' ')[0]}!",
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ],
                ),
                
                // Team Trasferta
                Expanded(
                  child: Column(
                    children: [
                      TeamBadge(team: at, size: BadgeSize.lg),
                      const SizedBox(height: 8),
                      Text(
                        at.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scorers list section
          if (widget.match.scorers.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "MARCATORI",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Home Scorers
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: homeScorers.map((s) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  const Text("⚽", style: TextStyle(fontSize: 11)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      s.own 
                                          ? (s.player != null ? "#${s.n} ${s.player} (A.G.)" : "Autogol (A.G.)")
                                          : "#${s.n} ${s.player}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: s.own ? AppColors.error : AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    "${s.min}'",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      // Central separator line
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      
                      // Away Scorers
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: awayScorers.map((s) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  const Text("⚽", style: TextStyle(fontSize: 11)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      s.own 
                                          ? (s.player != null ? "#${s.n} ${s.player} (A.G.)" : "Autogol (A.G.)")
                                          : "#${s.n} ${s.player}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: s.own ? AppColors.error : AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    "${s.min}'",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          // Admin controls panel (if authorized)
          if (provider.adminMode) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.04),
                border: const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "🔓 CONTROLLI ADMIN",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openGoalModal('home'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBg,
                              border: Border.all(color: AppColors.borderDark),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "⚽ Goal ${ht.name.split(' ')[0]}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openGoalModal('away'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBg,
                              border: Border.all(color: AppColors.borderDark),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "⚽ Goal ${at.name.split(' ')[0]}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Gestione Falli Admin Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "GESTIONE FALLI",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Home team controls
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => provider.updateFouls(widget.match.id, 'home', -1),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.remove, size: 14, color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${widget.match.homeFouls}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => provider.updateFouls(widget.match.id, 'home', 1),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.add, size: 14, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          const Text("VS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                          const SizedBox(width: 16),
                          // Away team controls
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => provider.updateFouls(widget.match.id, 'away', -1),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.remove, size: 14, color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${widget.match.awayFouls}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => provider.updateFouls(widget.match.id, 'away', 1),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.add, size: 14, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.match.group == 'KO') ...[
                    const Divider(color: AppColors.border, height: 24),
                    if (!widget.match.id.startsWith("OT")) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TEMPI SUPPLEMENTARI (5' GOLDEN GOL)",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Switch(
                            value: widget.match.isExtraTime,
                            activeThumbColor: AppColors.accent,
                            onChanged: (val) {
                              provider.toggleExtraTime(widget.match.id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "RIGORI (TIE-BREAKER)",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final currentHome = widget.match.homePenalties ?? 0;
                                  final currentAway = widget.match.awayPenalties ?? 0;
                                  provider.updatePenalties(widget.match.id, (currentHome - 1).clamp(0, 99), currentAway);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.remove, size: 14, color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${widget.match.homePenalties ?? 0}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  final currentHome = widget.match.homePenalties ?? 0;
                                  final currentAway = widget.match.awayPenalties ?? 0;
                                  provider.updatePenalties(widget.match.id, currentHome + 1, currentAway);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.add, size: 14, color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text("-", style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  final currentHome = widget.match.homePenalties ?? 0;
                                  final currentAway = widget.match.awayPenalties ?? 0;
                                  provider.updatePenalties(widget.match.id, currentHome, (currentAway - 1).clamp(0, 99));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.remove, size: 14, color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${widget.match.awayPenalties ?? 0}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  final currentHome = widget.match.homePenalties ?? 0;
                                  final currentAway = widget.match.awayPenalties ?? 0;
                                  provider.updatePenalties(widget.match.id, currentHome, currentAway + 1);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.add, size: 14, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  // Warnings and validations for ending match
                  () {
                    if (widget.match.group == 'KO') {
                      if (widget.match.homeGoals == widget.match.awayGoals) {
                        if (widget.match.id.startsWith("OT")) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              "⚠️ Pareggio: passa la squadra in casa per miglior piazzamento.",
                              style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          );
                        } else {
                          final homePen = widget.match.homePenalties ?? 0;
                          final awayPen = widget.match.awayPenalties ?? 0;
                          if (homePen == awayPen) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                "❌ Impossibile terminare in pareggio dai Quarti in poi: inserire i rigori.",
                                style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                        }
                      }
                    }
                    return const SizedBox.shrink();
                  }(),
                  // End Match button
                  GestureDetector(
                    onTap: () {
                      if (widget.match.group == 'KO' && 
                          !widget.match.id.startsWith("OT") && 
                          widget.match.homeGoals == widget.match.awayGoals) {
                        final homePen = widget.match.homePenalties ?? 0;
                        final awayPen = widget.match.awayPenalties ?? 0;
                        if (homePen == awayPen) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Inserire i rigori per decidere il vincitore!"),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                      }
                      provider.endMatch(widget.match.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "🏁 Termina Partita",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.error,
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
