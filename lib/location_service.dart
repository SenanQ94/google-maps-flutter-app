import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'notification_service.dart';
import 'map_service.dart';

class LocationService {


  static const String backgroundLocationTask = 'backgroundLocationTask';
  static Position? _lastPosition;
  static StreamSubscription<Position>? _positionStream;
  static bool _isBackgroundMode = false;

  static Future<void> initialize() async {
    await _checkLocationPermission();
    _startLocationTracking();
  }

  static Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }
    if (permission == LocationPermission.denied) {
      return;
    }
  }

  static void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1000,
      ),
    ).listen(_handleLocationUpdate);
  }

  static void _handleLocationUpdate(Position position) async {
    if (_lastPosition == null ||
        Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        ) >= 2000) {
      _lastPosition = position;
      if (_isBackgroundMode) {
        await _checkNearbyGasStations(position);
      }
    }
  }

  static Future<void> _checkNearbyGasStations(Position position) async {
    LatLng currentPosition = LatLng(position.latitude, position.longitude);
    List<Map<String, dynamic>> gasStations = await MapService.getNearbyGasStations(currentPosition);
    if (gasStations.isNotEmpty) {
      await NotificationService.showNearbyGasStationsNotification(gasStations);
    }
  }

  static void enterBackgroundMode() {
    _isBackgroundMode = true;
  }

  static void enterForegroundMode() {
    _isBackgroundMode = false;
  }

  static void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _lastPosition = null;
  }
}