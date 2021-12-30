import 'package:cloud_firestore/cloud_firestore.dart';

class DistanceDocumentSnapshot {
  final DocumentSnapshot documentSnapShot;
  double distance;

  DistanceDocumentSnapshot(this.documentSnapShot, this.distance);
}
