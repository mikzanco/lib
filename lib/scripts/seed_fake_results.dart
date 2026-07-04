// Script per inserire risultati fittizi nelle partite di girone
// Eseguire con: dart run lib/scripts/seed_fake_results.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final random = Random(42); // seed fisso per risultati riproducibili
  final batch = firestore.batch();

  // Tutte le 40 partite dei gironi (A1-A10, B1-B10, C1-C10, D1-D10)
  final matchIds = [
    for (final g in ['A', 'B', 'C', 'D'])
      for (int i = 1; i <= 10; i++) '$g$i',
  ];

  print('🏁 Inserimento risultati fittizi per ${matchIds.length} partite...\n');

  for (final matchId in matchIds) {
    final docRef = firestore.collection('matches').doc(matchId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      print('⚠️  Partita $matchId non trovata, skip.');
      continue;
    }

    final data = snapshot.data()!;
    final homeGoals = random.nextInt(5); // 0-4 gol
    final awayGoals = random.nextInt(5);

    print('  $matchId: ${data['home']} $homeGoals - $awayGoals ${data['away']}');

    batch.update(docRef, {
      'status': 'done',
      'homeGoals': homeGoals,
      'awayGoals': awayGoals,
      'scorers': [],
      'homeFouls': random.nextInt(5),
      'awayFouls': random.nextInt(5),
    });
  }

  await batch.commit();
  print('\n✅ Tutti i risultati fittizi inseriti! Ora puoi generare il tabellone.');
}
