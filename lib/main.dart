import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // launch the flutter app
  runApp(const carHudApp());
}

// Root widget of the app
class carHudApp extends StatelessWidget {
  const carHudApp({super.key}); // Constructor

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // Hides the debug banner
      home: HUDPage(), // Sets the main screen to the HUDPage
    );
  }
}

// Main screen widget showing the HUD (speed + time)
class HUDPage extends StatefulWidget {
  const HUDPage({super.key});
  @override
  State<HUDPage> createState() => _HUDPageState();
}

// State class for the HUDPage
class _HUDPageState extends State<HUDPage> {
  // Speed in km/h (as String to display in Text Widget)
  String _speed = "0";

  // Current time formatted like 14:05:23
  String _time = DateFormat('HH:mm:ss').format(DateTime.now());

  @override
  void initState() {
    // Initial state as the app starts
    super.initState();

    // Start listening to location changes
    startLocationStream();

    // Start updating time every second
    startTimeStream();
  }

  // Function to listen speed from GPS
  void startLocationStream() async {
    // check permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // request permission if not granted
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        // If still not granted, show alert and return
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Permission Required"),
            content: const Text(
              "Location permission is needed to measure speed.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        // return;
      }
    }

    // Check if location services are enabled (i.e. GPS is on)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Ask the user to enable location services
      await Geolocator.openLocationSettings();
      return;
    }

    // Start stream once permission and GPS are active
    // Define how accurate and frequent the updates should be
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // accuracy
      distanceFilter: 0, // Notify on every small movement
    );

    // Start a stream of position updates
    Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position position,
    ) {
      // Convert speed from m/s to km/h
      double speedKmh = position.speed * 3.6; // 18/5

      // Update speed on UI
      setState(() {
        _speed = speedKmh.toStringAsFixed(0); // Round off to integer string
      });
    });
  }

  // Function to update time every second
  void startTimeStream() {
    Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _time = DateFormat('HH:mm:ss').format(DateTime.now()); // Update time
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mirror the entire screen horizontally using Transform
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi), // Rotate 180 degree on Y-axis
      // Main UI
      child: Scaffold(
        backgroundColor: Colors.black, // Set background to black
        body: Row(
          children: [
            // LEFT SIDE: Shows Speed (large bold glowing)
            Expanded(
              flex: 1, // 50% width of the screen
              child: Center(
                child: Text(
                  _speed,
                  style: TextStyle(
                    fontSize: 180, // Huge font size for visibility
                    fontWeight: FontWeight.bold, // Make it bold
                    color: Colors.greenAccent, // Neon green
                    shadows: [
                      Shadow(
                        blurRadius: 30,
                        color: Colors.greenAccent,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // RIGHT SIDE: Column with km/h on top, time on bottom
            Expanded(
              flex: 1, // 50% width of the screen
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Even spacing
                children: [
                  // "km/h label"
                  Text(
                    "km/h",
                    style: TextStyle(
                      fontSize: 45,
                      color: Colors.grey[300], // Light gray color
                      fontWeight: FontWeight.w400,
                      // letterSpacing: 1.5, // Slightly spaced letters
                    ),
                  ),

                  // Current Time
                  Text(
                    _time,
                    style: TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5, // Slightly spaced letters
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
