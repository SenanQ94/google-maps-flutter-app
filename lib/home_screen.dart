import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:workmanager/workmanager.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'map_service.dart';

const fetchBackgroundLocationTask = "fetchBackgroundLocation";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case fetchBackgroundLocationTask:
        await _handleBackgroundLocationTask();
        break;
    }
    return Future.value(true);
  });
}

Future<void> _handleBackgroundLocationTask() async {
  Location location = Location();
  LocationData? locationData = await location.getLocation();
  if (locationData.latitude != null && locationData.longitude != null)
  {
  LatLng currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
  List<Map<String, dynamic>> gasStations = await MapService.getNearbyGasStations(currentPosition);
  if (gasStations.isNotEmpty) {
  await NotificationService.showNearbyGasStationsNotification(gasStations);
  }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  final Location _locationController = Location();
  final Set<Marker> _markers = {};
  Map<PolylineId, Polyline> polylines = {};

  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();

  }


  Future<void> _initServices() async {
    await LocationService.initialize();
    await NotificationService.initialize();
    NotificationService.showBackgroundServiceNotification();
    _listenToNotifications();
    await getLocationUpdates();
    await _updateMapWithCurrentLocation();
    _startBackgroundLocationTask();
  }

  void _startBackgroundLocationTask() {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Workmanager().registerPeriodicTask(
      "1",
      fetchBackgroundLocationTask,
      frequency: Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  @override
  void dispose() {
    NotificationService.cancelAllNotifications();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _startBackgroundLocationTask();
      NotificationService.showBackgroundServiceNotification();
      _sendGasStationNotificationIfPaused();
    } else if (state == AppLifecycleState.resumed) {
      NotificationService.cancelBackgroundServiceNotification();
    } else {
      NotificationService.cancelBackgroundServiceNotification();
    }
  }

  void _sendGasStationNotificationIfPaused() async {
    if (_currentPosition == null) return;

    List<Map<String, dynamic>> gasStations = await MapService.getNearbyGasStations(_currentPosition!);

    if (gasStations.isNotEmpty) {
      await NotificationService.showNearbyGasStationsNotification(gasStations);
    }
  }




  Future<void> _updateNearbyGasStations() async {
    if (_currentPosition == null) return;

    List<Map<String, dynamic>> gasStations = await MapService.getNearbyGasStations(_currentPosition!);
    _updateMarkers(gasStations);


  }

  void _listenToNotifications() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    print("Notification action received: ${receivedAction.id}");
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        _updateNearbyGasStations();
      }
    });
  }

  Future<void> _updateMapWithCurrentLocation() async {
    List<LatLng> polylineCoords = await MapService.getPolyLinePoints();
    _generatePolyLineFromPoints(polylineCoords);
    if (_currentPosition != null) {
      _cameraToPosition(_currentPosition!);
    }
  }



  void _updateMarkers(List<Map<String, dynamic>> gasStations) async {
    _markers.clear();

    BitmapDescriptor gasStationIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/gas_station_icon.png',
      height: 24,
      width: 24
    );

    for (var station in gasStations) {
      var marker = Marker(
        markerId: MarkerId(station['name']),
        position: LatLng(station['lat'], station['lng']),
        icon: gasStationIcon,
        infoWindow: InfoWindow(
          title: station['name'],
          snippet: 'Distance: ${_formatDistance(station['distance'])}',
        ),
      );

      _markers.add(marker);
    }

    setState(() {});
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  void _generatePolyLineFromPoints(List<LatLng> polylineCoords) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoords,
      width: 4,
    );

    setState(() {
      polylines[id] = polyline;
    });
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition newCameraPosition = CameraPosition(target: pos, zoom: 14);
    await controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        onMapCreated: ((GoogleMapController controller) => _mapController.complete(controller)),
        initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 13),
        markers: _markers,
        polylines: Set<Polyline>.of(polylines.values),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) _cameraToPosition(_currentPosition!);
        },
        mini: true,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}