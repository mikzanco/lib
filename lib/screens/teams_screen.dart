import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/team.dart';
import '../models/match_model.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/team_badge.dart';
import '../widgets/team_edit_modal.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  String _activeFilter = "all";

  void _openTeamModal(Team? team) {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TeamEditModal(
          team: team,
          teams: provider.teams,
          matches: provider.matches,
          onClose: () => Navigator.pop(context),
          onSave: (updated) {
            if (team == null) {
              // Crea nuova squadra (calcola il max ID)
              final maxId = provider.teams.isEmpty
                  ? 0
                  : provider.teams.map((t) => t.id).reduce((a, b) => a > b ? a : b);
              updated = Team(
                id: maxId + 1,
                name: updated.name,
                group: updated.group,
                color: updated.color,
                players: updated.players,
              );
              provider.addTeam(updated);
            } else {
              // Modifica esistente
              provider.updateTeam(updated);
            }
            Navigator.pop(context);
          },
          onDelete: team == null
              ? null
              : (id) {
                  provider.deleteTeam(id);
                  Navigator.pop(context);
                },
        );
      },
    );
  }

  Widget _buildFilterPill(String value, String label, int count) {
    final isSel = _activeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.accent : Colors.transparent,
          border: Border.all(
            color: isSel ? AppColors.accent : AppColors.borderDark,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          "$label ($count)",
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

    // Se non è admin, mostra la schermata di blocco
    if (!provider.adminMode) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "🔒",
                  style: TextStyle(fontSize: 48),
                ),
                SizedBox(height: 16),
                Text(
                  "Area Riservata Admin",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Accedi come admin per gestire le squadre del torneo. Tocca l'icona del lucchetto in alto a destra ed inserisci il PIN.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final groupCounts = {
      "A": provider.teams.where((t) => t.group == "A").length,
      "B": provider.teams.where((t) => t.group == "B").length,
      "C": provider.teams.where((t) => t.group == "C").length,
      "D": provider.teams.where((t) => t.group == "D").length,
    };

    final filteredTeams = _activeFilter == "all"
        ? provider.teams
        : provider.teams.where((t) => t.group == _activeFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtri gironi con conteggio
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterPill("all", "TUTTI", provider.teams.length),
                const SizedBox(width: 8),
                _buildFilterPill("A", "GIRONE A", groupCounts["A"]!),
                const SizedBox(width: 8),
                _buildFilterPill("B", "GIRONE B", groupCounts["B"]!),
                const SizedBox(width: 8),
                _buildFilterPill("C", "GIRONE C", groupCounts["C"]!),
                const SizedBox(width: 8),
                _buildFilterPill("D", "GIRONE D", groupCounts["D"]!),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lista delle squadre
          if (filteredTeams.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  "Nessuna squadra presente in questa selezione",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTeams.length,
              separatorBuilder: (c, i) => const SizedBox(height: 8),
              itemBuilder: (c, i) {
                final team = filteredTeams[i];
                
                final hasPlayed = provider.matches.any((m) =>
                    (m.home == team.id || m.away == team.id) &&
                    (m.status == MatchStatus.done || m.status == MatchStatus.live));

                return GestureDetector(
                  onTap: () => _openTeamModal(team),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        TeamBadge(team: team, size: BadgeSize.sm),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Girone ${team.group} · ${team.players.length} giocatori",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasPlayed) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: const Text(
                              "Ha giocato",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          
          const SizedBox(height: 12),

          // Aggiungi Squadra (Dashed Border Button)
          GestureDetector(
            onTap: () => _openTeamModal(null),
            child: CustomPaint(
              painter: DashedRectPainter(
                color: AppColors.borderDark,
                radius: 16,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppColors.accent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Aggiungi Squadra",
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
          ),
          
          const SizedBox(height: 24),

          // Riepilogo gironi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "SQUADRE PER GIRONE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.8,
                  children: ["A", "B", "C", "D"].map((g) {
                    final count = groupCounts[g]!;
                    final isOk = count == 5;
                    final isUnder = count < 5;

                    final countColor = isOk
                        ? AppColors.success
                        : isUnder
                            ? AppColors.error
                            : const Color(0xFFEA580C);

                    return Column(
                      children: [
                        Text(
                          "$count",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: countColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Girone $g",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOk
                              ? "✓ OK"
                              : isUnder
                                  ? "mancano ${5 - count}"
                                  : "extra",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: countColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Pulsante Cambia PIN (Solo per Admin loggati)
          GestureDetector(
            onTap: () {
              final pinController1 = TextEditingController();
              final pinController2 = TextEditingController();
              final formKey = GlobalKey<FormState>();
              
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  title: const Row(
                    children: [
                      Text("🔑 ", style: TextStyle(fontSize: 18)),
                      Text(
                        "Cambia PIN Admin",
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Inserisci un nuovo codice numerico di esattamente 6 cifre per blindare l'accesso.",
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: pinController1,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8.0,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: "Nuovo PIN",
                            hintStyle: const TextStyle(
                              color: AppColors.textDim,
                              letterSpacing: 0,
                            ),
                            counterText: "",
                            filled: true,
                            fillColor: AppColors.inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.length != 6 || int.tryParse(val) == null) {
                              return "Inserisci 6 cifre numeriche";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: pinController2,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8.0,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: "Conferma PIN",
                            hintStyle: const TextStyle(
                              color: AppColors.textDim,
                              letterSpacing: 0,
                            ),
                            counterText: "",
                            filled: true,
                            fillColor: AppColors.inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) {
                            if (val != pinController1.text) {
                              return "I codici non coincidono";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
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
                        if (formKey.currentState!.validate()) {
                          provider.changePin(pinController1.text.trim());
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Nuovo PIN configurato e salvato con successo!"),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Salva",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("🔑", style: TextStyle(fontSize: 15)),
                  SizedBox(width: 8),
                  Text(
                    "CAMBIA PIN ADMIN",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Pulsante di Reset Torneo (Solo per Admin loggati)
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  title: const Text(
                    "🧹 Resetta Torneo?",
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  content: const Text(
                    "Sei sicuro di voler azzerare tutti i risultati, le partite e le classifiche? Questa azione ripristinerà i dati iniziali del torneo e non può essere annullata.",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
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
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () {
                        provider.resetTournament();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Torneo ripristinato ai dati iniziali con successo!"),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      child: const Text(
                        "Sì, Resetta",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("🧹", style: TextStyle(fontSize: 15)),
                  SizedBox(width: 8),
                  Text(
                    "RESETTA TUTTO IL TORNEO",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.error,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter per disegnare il bordo tratteggiato senza dipendenze esterne
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double radius;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6.0,
    this.dashGap = 4.0,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final Path dashedPath = Path();
    double distance = 0.0;
    for (var metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashGap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashGap != dashGap ||
      oldDelegate.radius != radius;
}
