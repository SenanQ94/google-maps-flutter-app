import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'nearby.dart';

const String GOOGLE_API_KEY = 'xxxxxxxx';

class MapService {
  static const LatLng _home = LatLng(51.8086715, 10.2384164);
  static const LatLng _goslar = LatLng(51.9095, 10.4301);

  static Future<List<LatLng>> getPolyLinePoints() async {
    List<LatLng> polyLineCoords = [];
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: GOOGLE_API_KEY,
        request: PolylineRequest( origin: PointLatLng(_home.latitude, _home.longitude),
      destination: PointLatLng(_goslar.latitude, _goslar.longitude),
      mode: TravelMode.driving,)
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polyLineCoords.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      print(result.errorMessage);
    }

    return polyLineCoords;
  }

  static Future<List<Map<String, dynamic>>> getNearbyGasStations(LatLng position, {double radius = 5000}) async {
    var url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=$radius&type=gas_station&key=$GOOGLE_API_KEY');

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        NearbyPlacesResponse nearbyPlacesResponse = NearbyPlacesResponse.fromJson(jsonResponse);

        List<Map<String, dynamic>> gasStations = [];

        for (var place in nearbyPlacesResponse.results ?? []) {
          if (place.geometry?.location != null) {
            double distance = _calculateDistance(
                position.latitude,
                position.longitude,
                place.geometry!.location.lat,
                place.geometry!.location.lng
            );

            gasStations.add({
              'name': place.name ?? 'Unknown Gas Station',
              'distance': distance,
              'lat': place.geometry!.location.lat,
              'lng': place.geometry!.location.lng,
            });
          }
        }

        gasStations.sort((a, b) => a['distance'].compareTo(b['distance']));
        return gasStations;
      } else {
        print('Failed to fetch nearby places: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
      return [];
    }
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}