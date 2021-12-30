import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '/src/models/DistanceDocSnapshot.dart';
import '/src/point.dart';
import 'util.dart';

class FirestoreGeoCollectionRef {
  Query _collectionReference;
  Stream<QuerySnapshot> _stream;

  FirestoreGeoCollectionRef(this._collectionReference)
      : assert(_collectionReference != null) {
    _stream = _createStream(_collectionReference).shareReplay(maxSize: 1);
  }

  /// return QuerySnapshot stream
  Stream<QuerySnapshot> snapshot() {
    return _stream;
  }

  /// return the Document mapped to the [id]
  Stream<List<DocumentSnapshot>> queryDocuments(String id) {
    return _stream.map((QuerySnapshot querySnapshot) {
      querySnapshot.docs.where((DocumentSnapshot documentSnapshot) {
        return documentSnapshot.id == id;
      });
      return querySnapshot.docs;
    });
  }

  /// add a document to collection with [data]
  Future<DocumentReference> createDocument(Map<String, dynamic> data) {
    try {
      CollectionReference colRef = _collectionReference;
      return colRef.add(data);
    } catch (e) {
      throw Exception(
          'cannot call add on Query, use collection reference instead');
    }
  }

  /// delete document with [id] from the collection
  Future<void> deleteDocument(id) {
    try {
      CollectionReference colRef = _collectionReference;
      return colRef.doc(id).delete();
    } catch (e) {
      throw Exception(
          'cannot call delete on Query, use collection reference instead');
    }
  }

  /// create or update a document with [id], [merge] defines whether the document should overwrite
  Future<void> updateDocument(String id, var data, {bool merge = false}) {
    try {
      CollectionReference colRef = _collectionReference;
      return colRef.doc(id).set(data, SetOptions(merge: merge));
    } catch (e) {
      throw Exception(
          'cannot call set on Query, use collection reference instead');
    }
  }

  /// set a geo point with [latitude] and [longitude] using [field] as the object key to the document with [id]
  Future<void> setGeoPoint(
      String id, String field, double latitude, double longitude) {
    try {
      CollectionReference colRef = _collectionReference;
      var point = FireGeoPoint(latitude, longitude).data;
      return colRef.doc(id).set({'$field': point}, SetOptions(merge: true));
    } catch (e) {
      throw Exception(
          'cannot call set on Query, use collection reference instead');
    }
  }

  /// query firestore documents based on geographic [radius] from geoFirePoint [centerLocation]
  /// [field] specifies the name of the key in the document
  Stream<List<DocumentSnapshot>> geoSearch({
    @required FireGeoPoint centerLocation,
    @required double radius,
    @required String field,
    bool strictMode = true,
  }) {
    final precision = Util.setPrecision(radius);
    final centerHash = centerLocation.hash.substring(0, precision);
    final area = FireGeoPoint.neighborsOf(hash: centerHash)..add(centerHash);

    Iterable<Stream<List<DistanceDocumentSnapshot>>> queries = area.map((hash) {
      final tempQuery = _queryPoint(hash, field);
      return _createStream(tempQuery).map((QuerySnapshot querySnapshot) {
        return querySnapshot.docs
            .map((element) => DistanceDocumentSnapshot(element, null))
            .toList();
      });
    });

    Stream<List<DistanceDocumentSnapshot>> mergedObservable =
        listDistanceDocuments(queries);

    var filtered = mergedObservable.map((List<DistanceDocumentSnapshot> list) {
      var mappedList = list.map((DistanceDocumentSnapshot distanceDocSnapshot) {
        // split and fetch geoPoint from the nested Map
        final List<String> fieldList = field.split('.');
        /*final String docName = fieldList[0];
        final doc = distanceDocSnapshot.documentSnapshot.data[docName];*/
        Map<String, dynamic> geoPointField =
            distanceDocSnapshot.documentSnapShot.data(); //[fieldList[0]]
        if (fieldList.length > 1) {
          for (int i = 0; i < fieldList.length; i++) {
            geoPointField = geoPointField[fieldList[i]];
          }
        }
        final GeoPoint geoPoint = geoPointField['geopoint'];
        distanceDocSnapshot.distance =
            centerLocation.distance(lat: geoPoint.latitude, lng: geoPoint.longitude);
        return distanceDocSnapshot;
      });

      final filteredList = strictMode
          ? mappedList
              .where((DistanceDocumentSnapshot doc) =>
                      doc.distance <=
                      radius * 1.02 // buffer for edge distances;
                  )
              .toList()
          : mappedList.toList();
      filteredList.sort((a, b) {
        final distA = a.distance;
        final distB = b.distance;
        final val = (distA * 1000).toInt() - (distB * 1000).toInt();
        return val;
      });
      return filteredList.map((element) => element.documentSnapShot).toList();
    });
    return filtered.asBroadcastStream();
  }

  //listDistanceDocuments
  Stream<List<DistanceDocumentSnapshot>> listDistanceDocuments(
      Iterable<Stream<List<DistanceDocumentSnapshot>>> queries) {
    Stream<List<DistanceDocumentSnapshot>> mergedObservable = Rx.combineLatest(
        queries, (List<List<DistanceDocumentSnapshot>> originalList) {
      final reducedList = <DistanceDocumentSnapshot>[];
      originalList.forEach((t) {
        reducedList.addAll(t);
      });
      return reducedList;
    });
    return mergedObservable;
  }

  /// INTERNAL FUNCTIONS

  /// construct a query for the [geoHash] and [field]
  Query _queryPoint(String geoHash, String field) {
    final end = '$geoHash~';
    final temp = _collectionReference;
    return temp.orderBy('$field.geohash').startAt([geoHash]).endAt([end]);
  }

  /// create an observable for [ref], [ref] can be [Query] or [CollectionReference]
  Stream<QuerySnapshot> _createStream(var ref) {
    return ref.snapshots();
  }
}
