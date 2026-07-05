import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/team.dart';
import '../models/scorer.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';

class MatchEditModal extends StatefulWidget {
  final MatchModel match;

  const MatchEditModal({
    super.key,
    required this.match,
  });

  @override
  State<MatchEditModal> createState() => _MatchEditModalState();
}

class _MatchEditModalState extends State<MatchEditModal> {
  late MatchStatus _status;
  late int _homeGoals;
  late int _awayGoals;
  late int _homeFouls;
  late int _awayFouls;
  int? _homePenalties;
  int? _awayPenalties;
  late bool _isExtraTime;
  late List<ScorerEvent> _scorers;

  // For adding a new scorer
  String _newScorerSide = 'home';
  bool _newIsOwnGoal = false;
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  String? _resolvedPlayerName;
  bool _playerError = false;

  @override
  void initState() {
    super.initState();
    _status = widget.match.status;
    _homeGoals = widget.match.homeGoals;
    _awayGoals = widget.match.awayGoals;
    _homeFouls = widget.match.homeFouls;
    _awayFouls = widget.match.awayFouls;
    _homePenalties = widget.match.homePenalties;
    _awayPenalties = widget.match.awayPenalties;
    _isExtraTime = widget.match.isExtraTime;
    _scorers = List<ScorerEvent>.from(widget.match.scorers);

    _numberController.addListener(_validatePlayerNumber);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _validatePlayerNumber() {
    final teamId = _newScorerSide == 'home' ? widget.match.home : widget.match.away;
    if (teamId == null) return;
    
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final team = provider.teams.firstWhere(
      (t) => t.id == teamId,
      orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []),
    );
    
    final numStr = _numberController.text.trim();
    if (numStr.isEmpty) {
      setState(() {
        _resolvedPlayerName = null;
        _playerError = false;
      });
      return;
    }

    final n = int.tryParse(numStr);
    if (n == null) {
      setState(() {
        _resolvedPlayerName = null;
        _playerError = true;
      });
      return;
    }

    final playerIdx = team.players.indexWhere((p) => p.n == n);
    if (playerIdx != -1) {
      setState(() {
        _resolvedPlayerName = team.players[playerIdx].name;
        _playerError = false;
      });
    } else {
      setState(() {
        _resolvedPlayerName = null;
        _playerError = true;
      });
    }
  }

  void _addScorer() {
    final teamId = _newScorerSide == 'home' ? widget.match.home : widget.match.away;
    if (teamId == null) return;

    final min = int.tryParse(_minuteController.text.trim()) ?? 10;
    final numStr = _numberController.text.trim();
    final n = int.tryParse(numStr);

    ScorerEvent scorer;
    if (_newIsOwnGoal) {
      if (n != null && _resolvedPlayerName != null) {
        scorer = ScorerEvent(
          team: teamId,
          player: _resolvedPlayerName,
          n: n,
          min: min,
          own: true,
        );
      } else {
        scorer = ScorerEvent(team: teamId, own: true, min: min);
      }
    } else {
      if (n == null || _resolvedPlayerName == null) {
        setState(() => _playerError = true);
        return;
      }
      scorer = ScorerEvent(
        team: teamId,
        player: _resolvedPlayerName,
        n: n,
        min: min,
        own: false,
      );
    }

    setState(() {
      _scorers.add(scorer);
      // Auto-update goals count based on added scorer
      if (scorer.own) {
        if (_newScorerSide == 'home') {
          _awayGoals++;
        } else {
          _homeGoals++;
        }
      } else {
        if (_newScorerSide == 'home') {
          _homeGoals++;
        } else {
          _awayGoals++;
        }
      }

      // Reset fields
      _numberController.clear();
      _minuteController.clear();
      _resolvedPlayerName = null;
      _playerError = false;
    });
  }

  void _removeScorer(int index) {
    final scorer = _scorers[index];
    setState(() {
      _scorers.removeAt(index);
      // Determine side of the scorer
      final isHomeScorer = (scorer.team == widget.match.home && !scorer.own) || 
                           (scorer.team == widget.match.away && scorer.own);
      if (isHomeScorer) {
        _homeGoals = (_homeGoals - 1).clamp(0, 99);
      } else {
        _awayGoals = (_awayGoals - 1).clamp(0, 99);
      }
    });
  }

  void _saveChanges() {
    final updatedMatch = MatchModel(
      id: widget.match.id,
      group: widget.match.group,
      home: widget.match.home,
      away: widget.match.away,
      day: widget.match.day,
      time: widget.match.time,
      status: _status,
      homeGoals: _homeGoals,
      awayGoals: _awayGoals,
      scorers: _scorers,
      phase: widget.match.phase,
      homeFouls: _homeFouls,
      awayFouls: _awayFouls,
      homePenalties: _homePenalties,
      awayPenalties: _awayPenalties,
      isExtraTime: _isExtraTime,
      timerStartTimestamp: widget.match.timerStartTimestamp,
      elapsedSeconds: widget.match.elapsedSeconds,
      timerIsRunning: widget.match.timerIsRunning,
    );

    Provider.of<TournamentProvider>(context, listen: false).updateMatch(updatedMatch);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Partita modificata e salvata con successo!"),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildCounterRow({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 0,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => onChanged((value - 1).clamp(min, 99)),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              "$value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.white),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => onChanged(value + 1),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.add, size: 16, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TournamentProvider>(context);
    final ht = provider.teams.firstWhere((t) => t.id == widget.match.home, orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []));
    final at = provider.teams.firstWhere((t) => t.id == widget.match.away, orElse: () => Team(id: 0, name: "", group: "", color: 0, players: []));

    final isKo = widget.match.group == 'KO';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
                color: AppColors.cardBg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Modifica Partita ${widget.match.id}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${ht.name} vs ${at.name}",
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textTertiary),
                  )
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Match Status
                    const Text(
                      "STATO PARTITA",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MatchStatus>(
                          isExpanded: true,
                          value: _status,
                          dropdownColor: AppColors.cardBg,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.accent),
                          items: MatchStatus.values.map((status) {
                            String label = "Programmata";
                            if (status == MatchStatus.live) label = "In Corso (Live)";
                            if (status == MatchStatus.done) label = "Terminata (Risultato)";
                            return DropdownMenuItem<MatchStatus>(
                              value: status,
                              child: Text(
                                label,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _status = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Goals
                    const Text(
                      "RETI / GOL",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    _buildCounterRow(
                      title: "Gol ${ht.name}",
                      value: _homeGoals,
                      onChanged: (v) => setState(() => _homeGoals = v),
                    ),
                    const SizedBox(height: 8),
                    _buildCounterRow(
                      title: "Gol ${at.name}",
                      value: _awayGoals,
                      onChanged: (v) => setState(() => _awayGoals = v),
                    ),
                    const SizedBox(height: 20),

                    // Fouls
                    const Text(
                      "FALLI COMMESSI",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    _buildCounterRow(
                      title: "Falli ${ht.name}",
                      value: _homeFouls,
                      onChanged: (v) => setState(() => _homeFouls = v),
                    ),
                    const SizedBox(height: 8),
                    _buildCounterRow(
                      title: "Falli ${at.name}",
                      value: _awayFouls,
                      onChanged: (v) => setState(() => _awayFouls = v),
                    ),
                    const SizedBox(height: 20),

                    // KO-only fields: Penalties, Extra time
                    if (isKo) ...[
                      const Text(
                        "FASE A ELIMINAZIONE DIRETTA",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      // Extra Time Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Tempi Supplementari (Golden Goal)",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          Switch(
                            value: _isExtraTime,
                            activeThumbColor: AppColors.accent,
                            onChanged: (v) => setState(() => _isExtraTime = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Penalties
                      _buildCounterRow(
                        title: "Rigori ${ht.name}",
                        value: _homePenalties ?? 0,
                        onChanged: (v) => setState(() => _homePenalties = v),
                      ),
                      const SizedBox(height: 8),
                      _buildCounterRow(
                        title: "Rigori ${at.name}",
                        value: _awayPenalties ?? 0,
                        onChanged: (v) => setState(() => _awayPenalties = v),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Scorers List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "MARCATORI",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1.5),
                        ),
                        Text(
                          "Totale marcatori: ${_scorers.length}",
                          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_scorers.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            "Nessun marcatore inserito",
                            style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _scorers.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 6),
                        itemBuilder: (c, i) {
                          final s = _scorers[i];
                          final teamName = s.team == widget.match.home ? ht.name : at.name;
                          final playerLabel = s.own
                              ? (s.player != null ? "#${s.n} ${s.player} (Autogol)" : "Autogol")
                              : "#${s.n} ${s.player}";
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Text(s.own ? "⚠" : "⚽", style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        playerLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: s.own ? AppColors.error : AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "$teamName · ${s.min}' minuto",
                                        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeScorer(i),
                                  icon: const Icon(Icons.delete, color: AppColors.error, size: 18),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 16),
                    // Add Scorer Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "AGGIUNGI MARCATORE",
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.accent, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 10),
                          // Select Team & Goal type
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.borderDark),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _newScorerSide,
                                      dropdownColor: AppColors.cardBg,
                                      items: [
                                        DropdownMenuItem(value: 'home', child: Text(ht.name, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                        DropdownMenuItem(value: 'away', child: Text(at.name, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _newScorerSide = val;
                                            _validatePlayerNumber();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _newIsOwnGoal = !_newIsOwnGoal),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _newIsOwnGoal ? AppColors.error : AppColors.surfaceBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _newIsOwnGoal ? AppColors.error : AppColors.border),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Autogol",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _newIsOwnGoal ? AppColors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Jersey Number & Minute inputs
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 38,
                                  child: TextField(
                                    controller: _numberController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
                                    decoration: InputDecoration(
                                      hintText: "Maglia",
                                      hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 11),
                                      filled: true,
                                      fillColor: AppColors.inputBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 38,
                                  child: TextField(
                                    controller: _minuteController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
                                    decoration: InputDecoration(
                                      hintText: "Minuto",
                                      hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 11),
                                      filled: true,
                                      fillColor: AppColors.inputBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: GestureDetector(
                                  onTap: (_newIsOwnGoal || _resolvedPlayerName != null) ? _addScorer : null,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: (_newIsOwnGoal || _resolvedPlayerName != null) ? 1.0 : 0.4,
                                    child: Container(
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Aggiungi",
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.black),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Player validation info
                          if (_resolvedPlayerName != null || _playerError) ...[
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                _resolvedPlayerName != null ? "✓ $_resolvedPlayerName" : "⚠ Numero non trovato in rosa",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _resolvedPlayerName != null ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
                color: AppColors.cardBg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Annulla",
                        style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _saveChanges,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Salva Modifiche",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
