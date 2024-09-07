import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  static const int backgroundServiceNotificationId = 1;
  static const String backgroundChannelKey = 'background_channel';
  static const String gasStationChannelKey = 'gas_station_channel';

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: backgroundChannelKey,
          channelName: 'Background Service Notifications',
          channelDescription: 'Notifications for background service status',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Min,
          playSound: true,
          enableVibration: true,
          locked: true,
        ),
        NotificationChannel(
          channelKey: gasStationChannelKey,
          channelName: 'Gas Station Notifications',
          channelDescription: 'Notifications for nearby gas stations',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,

        ),
      ],
    );
  }

  static Future<void> showBackgroundServiceNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: backgroundServiceNotificationId,
        channelKey: backgroundChannelKey,
        title: 'Background Location Service',
        body: 'The app is fetching your location in the background',
        notificationLayout: NotificationLayout.Default,
        autoDismissible: false,
        locked: true,
      ),
    );
  }



  static Future<void> showNearbyGasStationsNotification(List<Map<String, dynamic>> gasStations) async {
    String notificationBody = gasStations.map((station) =>
    "\r\n${station['name']} - ${_formatDistance(station['distance'])}\r\n"
    ).join('\r\n');

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: gasStationChannelKey,
        title: 'Nearby Gas Stations',
        body: notificationBody,
        notificationLayout: NotificationLayout.BigText,
      ),
    );
  }

  static Future<void> showLocationNotification(
      double latitude, double longitude) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'location_channel',
        title: 'Location Update',
        body: 'Lat: $latitude, Lon: $longitude',
        payload: {'lat': latitude.toString(), 'lon': longitude.toString()},
      ),
    );
  }

  static String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }


  static Future<void> cancelBackgroundServiceNotification() async {
    await AwesomeNotifications().cancel(backgroundServiceNotificationId);
  }

  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
    await AwesomeNotifications().cancelAll();
  }
}