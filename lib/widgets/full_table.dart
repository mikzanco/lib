import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import '../utils/standings_calculator.dart';
import 'form_dot.dart';

class FullTable extends StatelessWidget {
  final String group;
  final List<Team> teams;
  final List<MatchModel> matches;

  const FullTable({
    super.key,
    required this.group,
    required this.teams,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    final rows = calcStandings(teams, matches, group);

    Widget buildHeaderCell(String text, double width, {TextAlign align = TextAlign.center}) {
      return SizedBox(
        width: width,
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            buildHeaderCell("#", 24, align: TextAlign.left),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text(
                  "SQUADRA",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            buildHeaderCell("G", 28),
            buildHeaderCell("V", 28),
            buildHeaderCell("P", 28),
            buildHeaderCell("S", 28),
            buildHeaderCell("DR", 28),
            buildHeaderCell("PTS", 32),
          ],
        ),
      );
    }

    Widget buildRow(StandingRow t, int index) {
      final isQualified = index < 4;
      final leftBorderColor = isQualified ? AppColors.success : AppColors.error;

      final posColor = index == 0
          ? AppColors.accent
          : index == 1
              ? AppColors.textSecondary
              : index == 2
                  ? const Color(0xFFEA580C) // orange-600
                  : AppColors.textTertiary;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: index == rows.length - 1
                  ? Colors.transparent
                  : AppColors.border.withValues(alpha: 0.5),
            ),
            left: BorderSide(color: leftBorderColor, width: 2),
          ),
        ),
        child: Row(
          children: [
            // Posizione
            SizedBox(
              width: 24,
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: posColor,
                ),
              ),
            ),
            
            // Squadra + Form dots
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Form dots (ultime 4 gare)
                    Row(
                      children: t.form
                          .map((res) => FormDot(result: res))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Stats
            SizedBox(
              width: 28,
              child: Text(
                "${t.g}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            SizedBox(
              width: 28,
              child: Text(
                "${t.w}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            SizedBox(
              width: 28,
              child: Text(
                "${t.d}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            SizedBox(
              width: 28,
              child: Text(
                "${t.l}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            SizedBox(
              width: 28,
              child: Text(
                "${t.goalDiff > 0 ? "+" : ""}${t.goalDiff}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            
            // Punti
            SizedBox(
              width: 32,
              child: Text(
                "${t.pts}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildHeader(),
          ...List.generate(rows.length, (i) => buildRow(rows[i], i)),
        ],
      ),
    );
  }
}
