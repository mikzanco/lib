import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import '../utils/standings_calculator.dart';

class MiniTable extends StatelessWidget {
  final String group;
  final List<Team> teams;
  final List<MatchModel> matches;

  const MiniTable({
    super.key,
    required this.group,
    required this.teams,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    final rows = calcStandings(teams, matches, group);
    
    final Map<String, Color> chipColors = {
      "A": AppColors.chipA,
      "B": AppColors.chipB,
      "C": AppColors.chipC,
      "D": AppColors.chipD,
    };

    final groupColor = chipColors[group] ?? AppColors.accent;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Girone $group",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  group,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: groupColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Rows
          ...List.generate(rows.length, (i) {
            final t = rows[i];
            final isQualified = i < 4;
            final leftBorderColor = isQualified ? AppColors.success : AppColors.error;

            final posColor = i == 0
                ? AppColors.accent
                : i == 1
                    ? AppColors.textSecondary
                    : AppColors.textTertiary;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: i == rows.length - 1
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
                    width: 16,
                    child: Text(
                      "${i + 1}",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: posColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Nome
                  Expanded(
                    child: Text(
                      t.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  // Punti
                  Text(
                    "${t.pts}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
