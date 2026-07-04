import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import 'team_badge.dart';

class TeamEditModal extends StatefulWidget {
  final Team? team; // null se stiamo creando una nuova squadra
  final List<Team> teams;
  final List<MatchModel> matches;
  final VoidCallback onClose;
  final Function(Team) onSave;
  final Function(int)? onDelete; // null per le nuove squadre

  const TeamEditModal({
    super.key,
    required this.team,
    required this.teams,
    required this.matches,
    required this.onClose,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<TeamEditModal> createState() => _TeamEditModalState();
}

class _TeamEditModalState extends State<TeamEditModal> {
  late String _name;
  late String _group;
  late int _color;
  late List<Player> _players;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pNumController = TextEditingController();
  final TextEditingController _pNameController = TextEditingController();
  
  bool _confirmDelete = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final t = widget.team;
    _name = t?.name ?? "";
    _group = t?.group ?? "A";
    _color = t?.color ?? 0;
    _players = t?.players != null ? List<Player>.from(t!.players) : [];

    _nameController.text = _name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pNumController.dispose();
    _pNameController.dispose();
    super.dispose();
  }

  bool _hasPlayed() {
    if (widget.team == null) return false;
    return widget.matches.any((m) =>
        (m.home == widget.team!.id || m.away == widget.team!.id) &&
        (m.status == MatchStatus.done || m.status == MatchStatus.live));
  }

  void _validateName(String val) {
    final v = val.trim();
    if (v.isEmpty) {
      setState(() => _nameError = "Nome obbligatorio");
      return;
    }
    if (v.length > 30) {
      setState(() => _nameError = "Max 30 caratteri");
      return;
    }
    
    // Check duplicato
    final isDuplicate = widget.teams.any((t) =>
        t.name.trim().toLowerCase() == v.toLowerCase() &&
        (widget.team == null || t.id != widget.team!.id));
        
    if (isDuplicate) {
      setState(() => _nameError = "Nome già usato");
    } else {
      setState(() => _nameError = null);
    }
  }

  void _addPlayer() {
    final nameVal = _pNameController.text.trim();
    final numVal = int.tryParse(_pNumController.text.trim());

    if (nameVal.isEmpty || numVal == null || numVal < 1 || numVal > 99) return;

    // Check duplicato numero maglia
    if (_players.any((p) => p.n == numVal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Un giocatore con questo numero è già presente in rosa!"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _players.add(Player(n: numVal, name: nameVal));
      _players.sort((a, b) => a.n.compareTo(b.n));
      _pNameController.clear();
      _pNumController.clear();
    });
  }

  void _removePlayer(int index) {
    setState(() {
      _players.removeAt(index);
    });
  }

  void _save() {
    _validateName(_nameController.text);
    if (_nameError != null) return;

    final updatedTeam = Team(
      id: widget.team?.id ?? 0, // id verrà settato dal chiamante se nuova
      name: _nameController.text.trim(),
      group: _group,
      color: _color,
      players: _players,
    );

    widget.onSave(updatedTeam);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.team == null;
    final hasPlayedMatches = _hasPlayed();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: AppDecorations.bottomSheet,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle barra
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header con tasto chiudi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isNew ? "Nuova Squadra" : "Modifica Squadra",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contenuto scrollabile
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Anteprima Live Badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBg.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          TeamBadge(
                            team: Team(
                              id: 0,
                              name: _nameController.text.isNotEmpty ? _nameController.text : "Preview",
                              group: _group,
                              color: _color,
                              players: const [],
                            ),
                            size: BadgeSize.md,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isNotEmpty ? _nameController.text : "Nome Squadra",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Girone $_group · Colore $_color",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nome Squadra
                    const Text(
                      "NOME SQUADRA",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      maxLength: 30,
                      style: const TextStyle(fontSize: 14, color: AppColors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "Es: Falchi Celesti",
                        hintStyle: const TextStyle(color: AppColors.textDim),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        errorText: _nameError,
                        errorStyle: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        ),
                      ),
                      onChanged: _validateName,
                    ),
                    const SizedBox(height: 20),

                    // Girone
                    const Text(
                      "GIRONE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (hasPlayedMatches) ...[
                      const Text(
                        "⚠ La squadra ha già disputato gare nel girone attuale",
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: ["A", "B", "C", "D"].map((g) {
                        final isSel = _group == g;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _group = g),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.accent : AppColors.surfaceBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? AppColors.accent : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  g,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isSel ? AppColors.black : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Color picker
                    const Text(
                      "COLORE BADGE SQUADRA",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.0,
                      children: List.generate(TeamColors.gradients.length, (i) {
                        final colors = TeamColors.gradients[i];
                        final isSel = _color == i;
                        return GestureDetector(
                          onTap: () => setState(() => _color = i),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: colors,
                              ),
                              shape: BoxShape.circle,
                              border: isSel
                                  ? Border.all(color: AppColors.accent, width: 3)
                                  : null,
                            ),
                            child: isSel
                                ? const Center(
                                    child: Icon(Icons.check, color: AppColors.white, size: 16),
                                  )
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Rosa giocatori
                    Text(
                      "ROSA (${_players.length} GIOCATORI)",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Lista giocatori esistenti
                    if (_players.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _players.length,
                          separatorBuilder: (c, i) => const Divider(color: AppColors.border, height: 1),
                          itemBuilder: (c, i) {
                            final p = _players[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  // Numero maglia cliccabile per modifica
                                  GestureDetector(
                                    onTap: () {
                                      final editController = TextEditingController(text: p.n.toString());
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AppColors.cardBg,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: const BorderSide(color: AppColors.border),
                                          ),
                                          title: Text(
                                            "Cambia numero di ${p.name}",
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                            ),
                                          ),
                                          content: TextField(
                                            controller: editController,
                                            keyboardType: TextInputType.number,
                                            autofocus: true,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                              color: AppColors.accent,
                                              letterSpacing: 4,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: "#",
                                              hintStyle: const TextStyle(color: AppColors.textTertiary),
                                              filled: true,
                                              fillColor: AppColors.inputBg,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: AppColors.accent, width: 2),
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text(
                                                "Annulla",
                                                style: TextStyle(
                                                  color: AppColors.textTertiary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.accent,
                                                foregroundColor: AppColors.black,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              ),
                                              onPressed: () {
                                                final newNum = int.tryParse(editController.text.trim());
                                                if (newNum == null || newNum < 1 || newNum > 99) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text("Inserisci un numero valido (1-99)"),
                                                      backgroundColor: AppColors.error,
                                                    ),
                                                  );
                                                  return;
                                                }
                                                // Controlla duplicati (escludendo il giocatore corrente)
                                                if (_players.any((pl) => pl.n == newNum && pl.name != p.name)) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text("Numero già assegnato ad un altro giocatore!"),
                                                      backgroundColor: AppColors.error,
                                                    ),
                                                  );
                                                  return;
                                                }
                                                setState(() {
                                                  _players[i] = Player(n: newNum, name: p.name);
                                                  _players.sort((a, b) => a.n.compareTo(b.n));
                                                });
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text(
                                                "Salva",
                                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: TeamColors.gradients[_color],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "#${p.n}",
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        final nameController = TextEditingController(text: p.name);
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: AppColors.cardBg,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                              side: const BorderSide(color: AppColors.border),
                                            ),
                                            title: Text(
                                              "Cambia nome di #${p.n}",
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                              ),
                                            ),
                                            content: TextField(
                                              controller: nameController,
                                              autofocus: true,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.white,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: "Nome giocatore",
                                                hintStyle: const TextStyle(color: AppColors.textTertiary),
                                                filled: true,
                                                fillColor: AppColors.inputBg,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: const BorderSide(color: AppColors.accent, width: 2),
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text(
                                                  "Annulla",
                                                  style: TextStyle(
                                                    color: AppColors.textTertiary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.accent,
                                                  foregroundColor: AppColors.black,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                ),
                                                onPressed: () {
                                                  final newName = nameController.text.trim();
                                                  if (newName.isEmpty) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text("Il nome non può essere vuoto!"),
                                                        backgroundColor: AppColors.error,
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  setState(() {
                                                    _players[i] = Player(n: p.n, name: newName);
                                                  });
                                                  Navigator.pop(ctx);
                                                },
                                                child: const Text(
                                                  "Salva",
                                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textSecondary,
                                            decoration: TextDecoration.underline,
                                            decorationStyle: TextDecorationStyle.dotted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removePlayer(i),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.close, size: 14, color: AppColors.error),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Aggiungi Giocatore Form
                    Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: TextField(
                            controller: _pNumController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent),
                            decoration: InputDecoration(
                              hintText: "#",
                              hintStyle: const TextStyle(color: AppColors.textTertiary),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _pNameController,
                            style: const TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: "Nome giocatore...",
                              hintStyle: const TextStyle(color: AppColors.textTertiary),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _addPlayer,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.add, color: AppColors.black, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Salva bottone
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            isNew ? "✓ Crea Squadra" : "✓ Salva Modifiche",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Elimina bottone (solo per esistenti)
                    if (!isNew && widget.onDelete != null) ...[
                      if (!_confirmDelete)
                        TextButton(
                          onPressed: () => setState(() => _confirmDelete = true),
                          child: const Text(
                            "🗑 Elimina Squadra",
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Sei sicuro di voler procedere?",
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (hasPlayedMatches) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  "⚠ Questa squadra ha già disputato incontri. Rimuovendola altererai la classifica del girone.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _confirmDelete = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceBg,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Annulla",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => widget.onDelete!(widget.team!.id),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Elimina",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
