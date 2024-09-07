import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermission(Permission.notification);
  await _requestPermission(Permission.location);
  await _requestPermission(Permission.locationAlways);

  await NotificationService.initialize();
  await LocationService.initialize();
  runApp(const MyApp());
}

Future<void> _requestPermission(Permission permission) async {
  if (await permission.isDenied) {
    final status = await permission.request();
    if (status.isDenied) {
      print('${permission.toString()} permission is denied.');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Charging Time',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}