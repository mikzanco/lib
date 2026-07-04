import '../models/team.dart';
import '../models/player.dart';

String resolvePlayerName(List<Team> teams, int teamId, int? playerNumber, String? fallbackName) {
  if (playerNumber == null) return fallbackName ?? "Sconosciuto";
  final team = teams.firstWhere(
    (t) => t.id == teamId,
    orElse: () => Team(id: teamId, name: "", group: "", color: 0, players: []),
  );
  final player = team.players.firstWhere(
    (p) => p.n == playerNumber,
    orElse: () => Player(n: playerNumber, name: fallbackName ?? "Sconosciuto"),
  );
  return player.name;
}
