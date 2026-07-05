import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';
import '../models/match_model.dart';
import '../models/scorer.dart';
import '../data/initial_data.dart';
import '../utils/standings_calculator.dart';

class TournamentProvider extends ChangeNotifier {
  List<Team> teams = [];
  List<MatchModel> matches = [];
  bool adminMode = false;
  bool loaded = false;
  bool goalFlash = false;
  String adminPin = ""; // Caricato da Firestore

  StreamSubscription? _teamsSubscription;
  StreamSubscription? _matchesSubscription;
  StreamSubscription? _configSubscription;
  bool _teamsLoaded = false;
  bool _matchesLoaded = false;
  bool _configLoaded = false;

  // Caricamento in tempo reale da Firestore
  Future<void> loadData() async {
    // Carica il PIN admin da Firestore (centralizzato)
    _configSubscription = FirebaseFirestore.instance
        .collection('config')
        .doc('admin')
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) {
        // Prima volta: crea il documento con un PIN predefinito
        // Questo PIN verrà scritto UNA SOLA VOLTA su Firestore
        await FirebaseFirestore.instance
            .collection('config')
            .doc('admin')
            .set({'pin': '425084'});
      } else {
        adminPin = snapshot.data()?['pin'] ?? '425084';
        _configLoaded = true;
        _checkLoaded();
      }
    }, onError: (e) {
      debugPrint("Errore caricamento config: $e");
      // Fallback: usa un PIN vuoto (nessun accesso)
      adminPin = '';
      _configLoaded = true;
      _checkLoaded();
    });

    // Ascolta le modifiche alle squadre in tempo reale
    _teamsSubscription = FirebaseFirestore.instance
        .collection('teams')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Se il database è vuoto su Firestore, carica i dati iniziali
        await _uploadInitialTeams();
      } else {
        teams = snapshot.docs.map((doc) => Team.fromJson(doc.data())).toList();
        teams.sort((a, b) => a.id.compareTo(b.id));
        _teamsLoaded = true;
        _checkLoaded();
      }
    }, onError: (e) {
      debugPrint("Errore caricamento squadre: $e");
    });

    // Ascolta le modifiche alle partite in tempo reale
    _matchesSubscription = FirebaseFirestore.instance
        .collection('matches')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Se il database è vuoto su Firestore, carica i dati iniziali
        await _uploadInitialMatches();
      } else {
        matches = snapshot.docs
            .map((doc) => MatchModel.fromJson(doc.data()))
            .toList();

        // Ordinamento corretto per le partite
        final idOrder = [
          for (int i = 1; i <= 10; i++) "A$i",
          for (int i = 1; i <= 10; i++) "B$i",
          for (int i = 1; i <= 10; i++) "C$i",
          for (int i = 1; i <= 10; i++) "D$i",
          for (int i = 1; i <= 8; i++) "OT$i",
          for (int i = 1; i <= 4; i++) "QF$i",
          "SF1",
          "SF2",
          "F3",
          "F"
        ];
        matches.sort((a, b) {
          final idxA = idOrder.indexOf(a.id);
          final idxB = idOrder.indexOf(b.id);
          if (idxA != -1 && idxB != -1) {
            return idxA.compareTo(idxB);
          }
          return a.id.compareTo(b.id);
        });
        _matchesLoaded = true;
        _checkLoaded();
      }
    }, onError: (e) {
      debugPrint("Errore caricamento partite: $e");
    });
  }

  void _checkLoaded() {
    if (_teamsLoaded && _matchesLoaded && _configLoaded) {
      loaded = true;
      notifyListeners();
    }
  }

  Future<void> _uploadInitialTeams() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final team in INITIAL_TEAMS) {
      final docRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(team.id.toString());
      batch.set(docRef, team.toJson());
    }
    await batch.commit();
  }

  Future<void> _uploadInitialMatches() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final match in INITIAL_MATCHES) {
      final docRef =
          FirebaseFirestore.instance.collection('matches').doc(match.id);
      batch.set(docRef, match.toJson());
    }
    await batch.commit();
  }

  // Resetta solo le partite del torneo (mantiene le squadre modificate)
  Future<void> resetTournament() async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Elimina tutti i match correnti
      for (final m in matches) {
        final docRef =
            FirebaseFirestore.instance.collection('matches').doc(m.id);
        batch.delete(docRef);
      }

      // 2. Ricrea solo i match dei gironi iniziali resettati
      final cleanMatches = INITIAL_MATCHES.map((m) {
        return MatchModel(
          id: m.id,
          group: m.group,
          home: m.home,
          away: m.away,
          day: m.day,
          time: m.time,
          status: MatchStatus.sched,
          homeGoals: 0,
          awayGoals: 0,
          scorers: [],
          phase: m.phase,
        );
      }).toList();

      // Rimuovi il tabellone KO
      cleanMatches.removeWhere((m) => m.group == "KO");

      for (final m in cleanMatches) {
        final docRef =
            FirebaseFirestore.instance.collection('matches').doc(m.id);
        batch.set(docRef, m.toJson());
      }

      await batch.commit();
      adminMode = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Errore reset torneo: $e");
    }
  }

  // Admin PIN management (centralizzato su Firestore)
  bool verifyPin(String pin) => adminPin.isNotEmpty && pin == adminPin;

  Future<void> changePin(String newPin) async {
    adminPin = newPin;
    try {
      await FirebaseFirestore.instance
          .collection('config')
          .doc('admin')
          .set({'pin': newPin});
    } catch (e) {
      debugPrint("Errore salvataggio PIN: $e");
    }
    notifyListeners();
  }

  void toggleAdmin() {
    adminMode = !adminMode;
    notifyListeners();
  }

  void setAdminMode(bool value) {
    adminMode = value;
    notifyListeners();
  }

  // Match Actions
  void startMatch(String matchId) {
    final idx = matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      final original = matches[idx];
      final updated = MatchModel(
        id: original.id,
        group: original.group,
        home: original.home,
        away: original.away,
        day: original.day,
        time: original.time,
        status: MatchStatus.live,
        homeGoals: 0,
        awayGoals: 0,
        scorers: [],
        phase: original.phase,
        timerStartTimestamp: DateTime.now().millisecondsSinceEpoch,
        elapsedSeconds: 0,
        timerIsRunning: true,
      );
      FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .set(updated.toJson());
    }
  }

  void resumeTimer(String matchId) {
    final idx = matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      final match = matches[idx];
      final updated = MatchModel(
        id: match.id,
        group: match.group,
        home: match.home,
        away: match.away,
        day: match.day,
        time: match.time,
        status: match.status,
        homeGoals: match.homeGoals,
        awayGoals: match.awayGoals,
        scorers: match.scorers,
        phase: match.phase,
        homeFouls: match.homeFouls,
        awayFouls: match.awayFouls,
        homePenalties: match.homePenalties,
        awayPenalties: match.awayPenalties,
        isExtraTime: match.isExtraTime,
        timerStartTimestamp: DateTime.now().millisecondsSinceEpoch,
        elapsedSeconds: match.elapsedSeconds,
        timerIsRunning: true,
      );
      FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .set(updated.toJson());
    }
  }

  void pauseTimer(String matchId, int currentElapsedSeconds) {
    final idx = matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      final match = matches[idx];
      final updated = MatchModel(
        id: match.id,
        group: match.group,
        home: match.home,
        away: match.away,
        day: match.day,
        time: match.time,
        status: match.status,
        homeGoals: match.homeGoals,
        awayGoals: match.awayGoals,
        scorers: match.scorers,
        phase: match.phase,
        homeFouls: match.homeFouls,
        awayFouls: match.awayFouls,
        homePenalties: match.homePenalties,
        awayPenalties: match.awayPenalties,
        isExtraTime: match.isExtraTime,
        timerStartTimestamp: null,
        elapsedSeconds: currentElapsedSeconds,
        timerIsRunning: false,
      );
      FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .set(updated.toJson());
    }
  }

  void adjustTimer(String matchId, int deltaSeconds, int currentElapsedSeconds) {
    final idx = matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      final match = matches[idx];
      final newElapsed = (currentElapsedSeconds + deltaSeconds).clamp(0, 99 * 60);
      final updated = MatchModel(
        id: match.id,
        group: match.group,
        home: match.home,
        away: match.away,
        day: match.day,
        time: match.time,
        status: match.status,
        homeGoals: match.homeGoals,
        awayGoals: match.awayGoals,
        scorers: match.scorers,
        phase: match.phase,
        homeFouls: match.homeFouls,
        awayFouls: match.awayFouls,
        homePenalties: match.homePenalties,
        awayPenalties: match.awayPenalties,
        isExtraTime: match.isExtraTime,
        timerStartTimestamp: match.timerIsRunning ? DateTime.now().millisecondsSinceEpoch : null,
        elapsedSeconds: newElapsed,
        timerIsRunning: match.timerIsRunning,
      );
      FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .set(updated.toJson());
    }
  }

  void addGoal(String matchId, String side, ScorerEvent scorer) {
    final idx = matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      final match = matches[idx];
      final newScorers = List<ScorerEvent>.from(match.scorers)..add(scorer);

      int homeG = match.homeGoals;
      int awayG = match.awayGoals;

      if (scorer.own) {
        if (side == 'home') {
          awayG++;
        } else {
          homeG++;
        }
      } else {
        if (side == 'home') {
          homeG++;
        } else {
          awayG++;
        }
      }

      final updated = MatchModel(
        id: match.id,
        group: match.group,
        home: match.home,
        away: match.away,
        day: match.day,
        time: match.time,
        status: match.status,
        homeGoals: homeG,
        awayGoals: awayG,
        scorers: newScorers,
        phase: match.phase,
        homeFouls: match.homeFouls,
        awayFouls: match.awayFouls,
        homePenalties: match.homePenalties,
        awayPenalties: match.awayPenalties,
        isExtraTime: match.isExtraTime,
        timerStartTimestamp: match.timerStartTimestamp,
        elapsedSeconds: match.elapsedSeconds,
        timerIsRunning: match.timerIsRunning,
      );

      triggerGoalFlash();
      FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .set(updated.toJson());
    }
  }

  void updateFouls(String matchId, String side, int delta) {
    final idx = matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      final match = matches[idx];
      int homeF = match.homeFouls;
      int awayF = match.awayFouls;

      if (side == 'home') {
        homeF = (homeF + delta).clamp(0, 99);
      } else {
        awayF = (awayF + delta).clamp(0, 99);
      }

      final updated = MatchModel(
        id: match.id,
        group: match.group,
        home: match.home,
        away: match.away,
        day: match.day,
        time: match.time,
        status: match.status,
        homeGoals: match.homeGoals,
        awayGoals: match.awayGoals,
        scorers: match.scorers,
        phase: match.phase,
        homeFouls: homeF,
        awayFouls: awayF,
        homePenalties: match.homePenalties,
        awayPenalties: match.awayPenalties,
        isExtraTime: match.isExtraTime,
        timerStartTimestamp: match.timerStartTimestamp,
        elapsedSeconds: match.elapsedSeconds,
        timerIsRunning: match.timerIsRunning,
      );

      FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .set(updated.toJson());
    }
  }

  void endMatch(String matchId) {
    final idx = matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      final match = matches[idx];
      final updated = MatchModel(
        id: match.id,
        group: match.group,
        home: match.home,
        away: match.away,
        day: match.day,
        time: match.time,
        status: MatchStatus.done,
        homeGoals: match.homeGoals,
        awayGoals: match.awayGoals,
        scorers: match.scorers,
        phase: match.phase,
        homeFouls: match.homeFouls,
        awayFouls: match.awayFouls,
        homePenalties: match.homePenalties,
        awayPenalties: match.awayPenalties,
        isExtraTime: match.isExtraTime,
        timerStartTimestamp: null,
        elapsedSeconds: match.elapsedSeconds,
        timerIsRunning: false,
      );

      if (match.group == 'KO') {
        _endBracketMatch(updated);
      } else {
        FirebaseFirestore.instance
            .collection('matches')
            .doc(matchId)
            .set(updated.toJson());
      }
    }
  }

  // ⚠️ TEMPORANEO: Inserisce risultati fittizi per testare il tabellone
  Future<void> seedFakeResults() async {
    final random = Random(42);
    final batch = FirebaseFirestore.instance.batch();
    final groupMatches = matches.where((m) => m.group != "KO").toList();

    for (final m in groupMatches) {
      final homeG = random.nextInt(5);
      final awayG = random.nextInt(5);
      final docRef = FirebaseFirestore.instance.collection('matches').doc(m.id);
      batch.update(docRef, {
        'status': 'done',
        'homeGoals': homeG,
        'awayGoals': awayG,
        'scorers': [],
        'homeFouls': 0,
        'awayFouls': 0,
      });
    }
    await batch.commit();
  }

  // Bracket Seeding
  void generateBracket() async {
    final qA = calcStandings(teams, matches, "A");
    final qB = calcStandings(teams, matches, "B");
    final qC = calcStandings(teams, matches, "C");
    final qD = calcStandings(teams, matches, "D");

    if (qA.length < 4 || qB.length < 4 || qC.length < 4 || qD.length < 4) return;

    // Seeding logic per gli Ottavi (OT1 - OT8)
    // OT1 (10:00): 1A vs 4B | OT2 (10:30): 2C vs 3D | OT3 (11:00): 1B vs 4A | OT4 (11:30): 2D vs 3C
    // OT5 (12:00): 1C vs 4D | OT6 (12:30): 2A vs 3B | OT7 (13:00): 2B vs 3A | OT8 (13:30): 1D vs 4C
    final newMatches = [
      MatchModel(id: "OT1", group: "KO", home: qA[0].id, away: qB[3].id, day: "Dom 5 Lug", time: "10:00", phase: "OT"),
      MatchModel(id: "OT2", group: "KO", home: qC[1].id, away: qD[2].id, day: "Dom 5 Lug", time: "10:30", phase: "OT"),
      MatchModel(id: "OT3", group: "KO", home: qB[0].id, away: qA[3].id, day: "Dom 5 Lug", time: "11:00", phase: "OT"),
      MatchModel(id: "OT4", group: "KO", home: qD[1].id, away: qC[2].id, day: "Dom 5 Lug", time: "11:30", phase: "OT"),
      MatchModel(id: "OT5", group: "KO", home: qC[0].id, away: qD[3].id, day: "Dom 5 Lug", time: "12:00", phase: "OT"),
      MatchModel(id: "OT6", group: "KO", home: qA[1].id, away: qB[2].id, day: "Dom 5 Lug", time: "12:30", phase: "OT"),
      MatchModel(id: "OT7", group: "KO", home: qB[1].id, away: qA[2].id, day: "Dom 5 Lug", time: "13:00", phase: "OT"),
      MatchModel(id: "OT8", group: "KO", home: qD[0].id, away: qC[3].id, day: "Dom 5 Lug", time: "13:30", phase: "OT"),

      // Quarti di Finale (QF1 - QF4)
      MatchModel(id: "QF1", group: "KO", home: null, away: null, day: "Dom 5 Lug", time: "14:00", phase: "QF"),
      MatchModel(id: "QF2", group: "KO", home: null, away: null, day: "Dom 5 Lug", time: "14:30", phase: "QF"),
      MatchModel(id: "QF3", group: "KO", home: null, away: null, day: "Dom 5 Lug", time: "15:00", phase: "QF"),
      MatchModel(id: "QF4", group: "KO", home: null, away: null, day: "Dom 5 Lug", time: "15:30", phase: "QF"),

      // Semifinali (SF1 - SF2)
      MatchModel(id: "SF1", group: "KO", home: null, away: null, day: "Dom 5 Lug", time: "16:00", phase: "SF"),
      MatchModel(id: "SF2", group: "KO", home: null, away: null, day: "Dom 5 Lug", time: "16:30", phase: "SF"),

      // Finali
      MatchModel(id: "F3", group: "KO", home: null, away: null, day: "Dom 5 Lug", time: "17:30", phase: "F"),
      MatchModel(id: "F", group: "KO", home: null, away: null, day: "Dom 5 Lug", time: "18:00", phase: "F"),
    ];

    final batch = FirebaseFirestore.instance.batch();

    // Rimuoviamo eventuali vecchie partite KO da Firestore
    final koMatchIds =
        matches.where((m) => m.group == "KO").map((m) => m.id).toList();
    for (final id in koMatchIds) {
      final docRef = FirebaseFirestore.instance.collection('matches').doc(id);
      batch.delete(docRef);
    }

    // Aggiungiamo le nuove
    for (final m in newMatches) {
      final docRef = FirebaseFirestore.instance.collection('matches').doc(m.id);
      batch.set(docRef, m.toJson());
    }

    await batch.commit();
  }

  void _endBracketMatch(MatchModel completedMatch) async {
    int winner;
    int loser;

    if (completedMatch.homeGoals == completedMatch.awayGoals) {
      if (completedMatch.id.startsWith("OT")) {
        // Negli ottavi passa il migliore classificato (Home)
        winner = completedMatch.home!;
        loser = completedMatch.away!;
      } else {
        // Per le altre fasi, in caso di pareggio, dobbiamo usare i rigori
        final homePen = completedMatch.homePenalties ?? 0;
        final awayPen = completedMatch.awayPenalties ?? 0;
        if (homePen == awayPen) {
          return;
        }
        winner = homePen > awayPen ? completedMatch.home! : completedMatch.away!;
        loser = homePen > awayPen ? completedMatch.away! : completedMatch.home!;
      }
    } else {
      winner = completedMatch.homeGoals > completedMatch.awayGoals ? completedMatch.home! : completedMatch.away!;
      loser = completedMatch.homeGoals > completedMatch.awayGoals ? completedMatch.away! : completedMatch.home!;
    }

    final batch = FirebaseFirestore.instance.batch();

    // Salva la partita completata
    final matchDoc = FirebaseFirestore.instance
        .collection('matches')
        .doc(completedMatch.id);
    batch.set(matchDoc, completedMatch.toJson());

    final Map<String, MatchModel> updates = {};

    // Ottavi -> Quarti
    if (completedMatch.id.startsWith("OT")) {
      final otNum = int.parse(completedMatch.id.replaceAll("OT", ""));
      final qfNum = ((otNum - 1) ~/ 2) + 1;
      final qfId = "QF$qfNum";
      final qf = matches.firstWhere((x) => x.id == qfId);
      final isHome = otNum % 2 == 1;

      updates[qfId] = MatchModel(
        id: qf.id,
        group: qf.group,
        home: isHome ? winner : qf.home,
        away: !isHome ? winner : qf.away,
        day: qf.day,
        time: qf.time,
        status: qf.status,
        homeGoals: qf.homeGoals,
        awayGoals: qf.awayGoals,
        scorers: qf.scorers,
        phase: qf.phase,
      );
    }

    // Quarti -> Semis
    if (completedMatch.id.startsWith("QF")) {
      final qfNum = int.parse(completedMatch.id.replaceAll("QF", ""));
      final sfNum = ((qfNum - 1) ~/ 2) + 1;
      final sfId = "SF$sfNum";
      final sf = matches.firstWhere((x) => x.id == sfId);
      final isHome = qfNum % 2 == 1;

      updates[sfId] = MatchModel(
        id: sf.id,
        group: sf.group,
        home: isHome ? winner : sf.home,
        away: !isHome ? winner : sf.away,
        day: sf.day,
        time: sf.time,
        status: sf.status,
        homeGoals: sf.homeGoals,
        awayGoals: sf.awayGoals,
        scorers: sf.scorers,
        phase: sf.phase,
      );
    }

    // Semis -> Finals
    if (completedMatch.id == "SF1" || completedMatch.id == "SF2") {
      final isSf1 = completedMatch.id == "SF1";
      final f = matches.firstWhere((x) => x.id == "F");
      final f3 = matches.firstWhere((x) => x.id == "F3");

      updates["F"] = MatchModel(
        id: f.id,
        group: f.group,
        home: isSf1 ? winner : f.home,
        away: !isSf1 ? winner : f.away,
        day: f.day,
        time: f.time,
        status: f.status,
        homeGoals: f.homeGoals,
        awayGoals: f.awayGoals,
        scorers: f.scorers,
        phase: f.phase,
      );

      updates["F3"] = MatchModel(
        id: f3.id,
        group: f3.group,
        home: isSf1 ? loser : f3.home,
        away: !isSf1 ? loser : f3.away,
        day: f3.day,
        time: f3.time,
        status: f3.status,
        homeGoals: f3.homeGoals,
        awayGoals: f3.awayGoals,
        scorers: f3.scorers,
        phase: f3.phase,
      );
    }

    updates.forEach((id, matchModel) {
      final docRef = FirebaseFirestore.instance.collection('matches').doc(id);
      batch.set(docRef, matchModel.toJson());
    });

    await batch.commit();
  }

  void updatePenalties(String matchId, int homePen, int awayPen) {
    final idx = matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      final match = matches[idx];
      final updated = MatchModel(
        id: match.id,
        group: match.group,
        home: match.home,
        away: match.away,
        day: match.day,
        time: match.time,
        status: match.status,
        homeGoals: match.homeGoals,
        awayGoals: match.awayGoals,
        scorers: match.scorers,
        phase: match.phase,
        homeFouls: match.homeFouls,
        awayFouls: match.awayFouls,
        homePenalties: homePen,
        awayPenalties: awayPen,
        isExtraTime: match.isExtraTime,
      );

      FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .set(updated.toJson());
    }
  }

  void toggleExtraTime(String matchId) {
    final idx = matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      final match = matches[idx];
      final updated = MatchModel(
        id: match.id,
        group: match.group,
        home: match.home,
        away: match.away,
        day: match.day,
        time: match.time,
        status: match.status,
        homeGoals: match.homeGoals,
        awayGoals: match.awayGoals,
        scorers: match.scorers,
        phase: match.phase,
        homeFouls: match.homeFouls,
        awayFouls: match.awayFouls,
        homePenalties: match.homePenalties,
        awayPenalties: match.awayPenalties,
        isExtraTime: !match.isExtraTime,
      );

      FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .set(updated.toJson());
    }
  }

  Future<void> updateMatch(MatchModel updatedMatch) async {
    try {
      if (updatedMatch.status == MatchStatus.done && updatedMatch.group == 'KO') {
        _endBracketMatch(updatedMatch);
      } else {
        await FirebaseFirestore.instance
            .collection('matches')
            .doc(updatedMatch.id)
            .set(updatedMatch.toJson());
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Errore aggiornamento match: $e");
    }
  }

  // Team CRUD in Firestore
  void addTeam(Team team) {
    FirebaseFirestore.instance
        .collection('teams')
        .doc(team.id.toString())
        .set(team.toJson());
  }

  void updateTeam(Team team) {
    FirebaseFirestore.instance
        .collection('teams')
        .doc(team.id.toString())
        .set(team.toJson());
  }

  void deleteTeam(int id) {
    FirebaseFirestore.instance
        .collection('teams')
        .doc(id.toString())
        .delete();
  }

  // Clean subscriptions
  @override
  void dispose() {
    _teamsSubscription?.cancel();
    _matchesSubscription?.cancel();
    _configSubscription?.cancel();
    super.dispose();
  }

  // Goal Flash Animation
  void triggerGoalFlash() {
    goalFlash = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 700), () {
      goalFlash = false;
      notifyListeners();
    });
  }
}
