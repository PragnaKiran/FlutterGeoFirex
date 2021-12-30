import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'util.dart';

class FireGeoPoint {
  static Util _util = Util();
  double latitude, longitude;

  FireGeoPoint(this.latitude, this.longitude);

  /// return geographical distance between two Co-ordinates
  static double distanceBetween(
      {@required Coordinates to, @required Coordinates from}) {
    return Util.distance(to, from);
  }

  /// return neighboring geo-hashes of [hash]
  static List<String> neighborsOf({@required String hash}) {
    return _util.neighbors(hash);
  }

  /// return hash of [FireGeoPoint]
  String get hash {
    return _util.encode(this.latitude, this.longitude, 9);
  }

  /// return all neighbors of [FireGeoPoint]
  List<String> get neighbors {
    return _util.neighbors(this.hash);
  }

  /// return [GeoPoint] of [FireGeoPoint]
  GeoPoint get geoPoint {
    return GeoPoint(this.latitude, this.longitude);
  }

  Coordinates get coords {
    return Coordinates(this.latitude, this.longitude);
  }

  /// return distance between [FireGeoPoint] and ([lat], [lng])
  double distance({@required double lat, @required double lng}) {
    return distanceBetween(from: coords, to: Coordinates(lat, lng));
  }

  get data {
    return {'geopoint': this.geoPoint, 'geohash': this.hash};
  }

  /// haversine distance between [FireGeoPoint] and ([lat], [lng])
  haversineDistance({@required double lat, @required double lng}) {
    return FireGeoPoint.distanceBetween(
        from: coords, to: Coordinates(lat, lng));
  }
}

class Coordinates {
  double latitude;
  double longitude;

  Coordinates(this.latitude, this.longitude);
}
