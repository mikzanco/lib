import '../models/match_model.dart';
import '../models/team.dart';
import 'player_resolver.dart';

class ScorerRow {
  final String name;
  final int n; // Numero maglia
  final String teamName;
  final int teamColor;
  final int teamId;
  int goals;

  ScorerRow({
    required this.name,
    required this.n,
    required this.teamName,
    required this.teamColor,
    required this.teamId,
    this.goals = 0,
  });
}

List<ScorerRow> calcScorers(List<MatchModel> matches, List<Team> teams) {
  final Map<String, ScorerRow> map = {};

  for (var m in matches) {
    if (m.status == MatchStatus.done || m.status == MatchStatus.live) {
      for (var s in m.scorers) {
        if (s.own) continue; // Ignoriamo gli autogol
        
        final playerNum = s.n ?? 0;
        final playerName = resolvePlayerName(teams, s.team, s.n, s.player);
        final key = "${s.team}-$playerNum";

        if (!map.containsKey(key)) {
          final team = teams.firstWhere(
            (t) => t.id == s.team,
            orElse: () => Team(id: s.team, name: "?", group: "?", color: 0, players: []),
          );
          map[key] = ScorerRow(
            name: playerName,
            n: playerNum,
            teamName: team.name,
            teamColor: team.color,
            teamId: s.team,
          );
        }
        map[key]!.goals++;
      }
    }
  }

  final list = map.values.toList();
  // Ordinamento per gol decrescenti
  list.sort((a, b) => b.goals.compareTo(a.goals));
  return list;
}
