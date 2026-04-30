import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fling/features/me/domain/me.dart';

class MeRepository {
  MeRepository({required this.firestore});

  final FirebaseFirestore firestore;

  Stream<Me?> watch(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return Me.fromFirestoreDoc(uid, data);
    });
  }
}
