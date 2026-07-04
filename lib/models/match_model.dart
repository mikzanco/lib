import 'scorer.dart';

enum MatchStatus { sched, live, done }

class MatchModel {
  final String id;       // "A1", "QF1", "SF1", "F", "F3"
  final String group;    // "A", "B", "C", "D", "KO"
  int? home;             // id squadra casa (nullable per bracket TBD)
  int? away;
  final String day;
  final String time;
  MatchStatus status;
  int homeGoals;
  int awayGoals;
  List<ScorerEvent> scorers;
  String? phase;         // "QF", "SF", "F" per partite KO
  int homeFouls;
  int awayFouls;
  int? homePenalties;
  int? awayPenalties;
  bool isExtraTime;
  int? timerStartTimestamp;
  int elapsedSeconds;
  bool timerIsRunning;

  MatchModel({
    required this.id,
    required this.group,
    this.home,
    this.away,
    required this.day,
    required this.time,
    this.status = MatchStatus.sched,
    this.homeGoals = 0,
    this.awayGoals = 0,
    this.scorers = const [],
    this.phase,
    this.homeFouls = 0,
    this.awayFouls = 0,
    this.homePenalties,
    this.awayPenalties,
    this.isExtraTime = false,
    this.timerStartTimestamp,
    this.elapsedSeconds = 0,
    this.timerIsRunning = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'group': group,
        'home': home,
        'away': away,
        'day': day,
        'time': time,
        'status': status.name,
        'homeGoals': homeGoals,
        'awayGoals': awayGoals,
        'scorers': scorers.map((s) => s.toJson()).toList(),
        'phase': phase,
        'homeFouls': homeFouls,
        'awayFouls': awayFouls,
        'homePenalties': homePenalties,
        'awayPenalties': awayPenalties,
        'isExtraTime': isExtraTime,
        'timerStartTimestamp': timerStartTimestamp,
        'elapsedSeconds': elapsedSeconds,
        'timerIsRunning': timerIsRunning,
      };

  factory MatchModel.fromJson(Map<String, dynamic> j) => MatchModel(
        id: j['id'] as String,
        group: j['group'] as String,
        home: j['home'] as int?,
        away: j['away'] as int?,
        day: j['day'] as String,
        time: j['time'] as String,
        status: MatchStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => MatchStatus.sched,
        ),
        homeGoals: j['homeGoals'] as int? ?? 0,
        awayGoals: j['awayGoals'] as int? ?? 0,
        scorers: (j['scorers'] as List? ?? [])
            .map((s) => ScorerEvent.fromJson(s as Map<String, dynamic>))
            .toList(),
        phase: j['phase'] as String?,
        homeFouls: j['homeFouls'] as int? ?? 0,
        awayFouls: j['awayFouls'] as int? ?? 0,
        homePenalties: j['homePenalties'] as int?,
        awayPenalties: j['awayPenalties'] as int?,
        isExtraTime: j['isExtraTime'] as bool? ?? false,
        timerStartTimestamp: j['timerStartTimestamp'] as int?,
        elapsedSeconds: j['elapsedSeconds'] as int? ?? 0,
        timerIsRunning: j['timerIsRunning'] as bool? ?? false,
      );
}
