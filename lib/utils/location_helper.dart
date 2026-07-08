import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationHelper {

  /// =========================================================
  /// 🔹 TEXT → GEOPOINT
  /// =========================================================
  static Future<GeoPoint?> geoFromText(String address) async {
    try {
      final List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final loc = locations.first;
        return GeoPoint(loc.latitude, loc.longitude);
      }
    } catch (e, s) {
  debugPrint("==============");
  debugPrint(address);
  debugPrint(e.toString());
  debugPrint(s.toString());
}
    return null;
  }

  /// =========================================================
  /// 🔹 GEOPOINT → TEXT
  /// =========================================================
  static Future<String?> textFromGeo(GeoPoint geo) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        geo.latitude,
        geo.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
    return null;
  }

  /// =========================================================
  /// 🔥 LAT/LNG → ADDRESS
  /// =========================================================
  static Future<String?> getAddressFromLatLng(
    double lat,
    double lng,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      debugPrint("LatLng to address error: $e");
    }
    return null;
  }

  /// =========================================================
  /// 🔥 NEW: EXTRACT CITY FROM TEXT
  /// =========================================================
  static String extractCity(String address) {
    try {
      final parts = address.split(",");
      return parts.isNotEmpty ? parts.last.trim() : address;
    } catch (e) {
      return address;
    }
  }

  /// =========================================================
  /// 🔥 NEW: LAT/LNG → GEOPOINT
  /// =========================================================
  static GeoPoint geoFromLatLng(double lat, double lng) {
    return GeoPoint(lat, lng);
  }

  /// =========================================================
  /// 🔥 NEW: GEOPOINT → LAT/LNG
  /// =========================================================
  static Map<String, double> latLngFromGeo(GeoPoint geo) {
    return {
      "lat": geo.latitude,
      "lng": geo.longitude,
    };
  }

  /// =========================================================
  /// 🔥 NEW: GOOGLE MAP URL
  /// =========================================================
  static String generateMapUrl(double lat, double lng) {
    return "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
  }

  /// =========================================================
  /// 🔥 GET CURRENT LOCATION
  /// =========================================================
  static Future<GeoPoint?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permanently denied.");
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      return GeoPoint(position.latitude, position.longitude);

    } catch (e) {
      debugPrint("Location fetch error: $e");
      return null;
    }
  }

  /// =========================================================
  /// 🔹 DISTANCE CALCULATION
  /// =========================================================
  static double calculateDistance(
    GeoPoint from,
    GeoPoint to,
  ) {
    final meters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );

    return meters / 1000;
  }

  /// =========================================================
  /// 🔹 DISTANCE LABEL
  /// =========================================================
  static String getDistanceLabel(double km) {
    if (km <= 5) return "Near you";
    if (km <= 15) return "Within your area";
    return "Far";
  }

  /// =========================================================
  /// 🔹 PRIORITY FOR SORTING
  /// =========================================================
  static int getPriority(double km) {
    if (km <= 5) return 1;
    if (km <= 15) return 2;
    return 3;
  }

  /// =========================================================
  /// 🔥 FILTER BY RADIUS
  /// =========================================================
  static List<T> filterByRadius<T>({
    required List<T> items,
    required GeoPoint userLocation,
    required GeoPoint? Function(T item) getLocation,
    double radiusKm = 5,
  }) {
    return items.where((item) {
      final loc = getLocation(item);
      if (loc == null) return false;

      final distance = calculateDistance(userLocation, loc);
      return distance <= radiusKm;
    }).toList();
  }

  /// =========================================================
  /// 🔥 SORT BY DISTANCE
  /// =========================================================
  static List<T> sortByDistance<T>({
    required List<T> items,
    required GeoPoint userLocation,
    required GeoPoint? Function(T item) getLocation,
  }) {
    items.sort((a, b) {
      final locA = getLocation(a);
      final locB = getLocation(b);

      if (locA == null) return 1;
      if (locB == null) return -1;

      final distA = calculateDistance(userLocation, locA);
      final distB = calculateDistance(userLocation, locB);

      return distA.compareTo(distB);
    });

    return items;
  }
}