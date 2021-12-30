import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '/src/point.dart';
import '/src/collection.dart';

class FlutterGeoFireX {
  FlutterGeoFireX();

  FirestoreGeoCollectionRef collection({@required Query collectionRef}) {
    return FirestoreGeoCollectionRef(collectionRef);
  }

  FireGeoPoint point({@required double latitude, @required double longitude}) {
    return FireGeoPoint(latitude, longitude);
  }
}
