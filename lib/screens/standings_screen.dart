import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_table.dart';
import '../widgets/full_table.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pills filters
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

          // Standings tables
          if (_activeFilter == "all") ...[
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.68, // Perfetto per contenere 5 righe comodamente
              children: [
                MiniTable(group: "A", teams: provider.teams, matches: provider.matches),
                MiniTable(group: "B", teams: provider.teams, matches: provider.matches),
                MiniTable(group: "C", teams: provider.teams, matches: provider.matches),
                MiniTable(group: "D", teams: provider.teams, matches: provider.matches),
              ],
            ),
          ] else ...[
            FullTable(group: _activeFilter, teams: provider.teams, matches: provider.matches),
          ],
          
          const SizedBox(height: 24),

          // Legend
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Green indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Qualificata agli Ottavi (1°–4° posto)",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 20),
                
                // Red indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Eliminata (5° posto)",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
