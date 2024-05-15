import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationTrackingPage extends StatefulWidget {
  @override
  _LocationTrackingPageState createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> {
  Position? _currentPosition;
  List<String> _geofenceEvents = [];

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  
  get ios => null;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // var ios = IOSInitializationSettings();
    var initSettings = InitializationSettings(android: android, iOS: ios);
    _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void _showNotification(String title, String body) async {
    var android = const AndroidNotificationDetails(
        'channel id', 'channel name',
        importance: Importance.max);
    var platform = NotificationDetails(android: android);
    await _flutterLocalNotificationsPlugin.show(0, title, body, platform);
  }

  void _initLocationTracking() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _checkGeofence(position);
    });
  }

 void _checkGeofence(Position position) async {
    final apiKey = 'AIzaSyBCxtj4T41F9GSup5aFv5lxXN-_S6-x_q4';
    final url =
        'https://www.googleapis.com/geolocation/v1/geolocate?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'considerIp': 'true',
        'wifiAccessPoints': [],
      }),
    );

    if (response.statusCode == 200) {
      final locationData = jsonDecode(response.body);
      final double latitude = locationData['location']['lat'];
      final double longitude = locationData['location']['lng'];

      // Check if the received location is within the predefined geofence
      final isInside = _isInsideGeofence(latitude, longitude);

      // Check if the latest event is different from the current status
      if (_geofenceEvents.isEmpty ||
          (_geofenceEvents.last !=
              (isInside
                  ? "Entered predefined geofence"
                  : "Exited predefined geofence"))) {
        _showNotification(
            "Geofence Alert",
            isInside
                ? "Entered predefined geofence"
                : "Exited predefined geofence");
        setState(() {
          _geofenceEvents.add(isInside
              ? "Entered predefined geofence"
              : "Exited predefined geofence");
        });
      }
    } else {
      // Handle errors
      print('Failed to fetch location: ${response.statusCode}');
    }
  }


  bool _isInsideGeofence(double latitude, double longitude) {
    // You can implement your geofencing logic here.
    // For demonstration, let's assume a predefined geofence area
    final double predefinedLatitude = -1.9410;
    final double predefinedLongitude = 30.1015;
    final double predefinedRadius = 1000;

    final distance = Geolocator.distanceBetween(
      predefinedLatitude,
      predefinedLongitude,
      latitude,
      longitude,
    );

    return distance <= predefinedRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Tracking & Geofencing'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_currentPosition != null)
              Text(
                'Current Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
              ),
            SizedBox(height: 20),
            Text(
              'Geofence Events:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _geofenceEvents.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_geofenceEvents[index]),
                    subtitle: Text('Timestamp: ${DateTime.now()}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
