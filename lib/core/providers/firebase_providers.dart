// lib/core/providers/firebase_providers.dart
// ✅ PATCH DAY-1-B: NOT_FOUND fix — region 'us-central1' ko'rsatildi
//
// ROOT CAUSE: FirebaseFunctions.instance default region 'us-central1' bo'lsa
// ham, ba'zi SDK versiyalarida region mismatch yuzaga keladi.
// index.ts da functions.region('us-central1') ishlatilgani uchun
// client ham instanceFor(region:'us-central1') ishlatishi SHART.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// ✅ FIX: instanceFor(region) — index.ts region bilan mos bo'lishi SHART
/// index.ts: functions.region('us-central1').https.onCall(...)
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: 'us-central1');
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});
