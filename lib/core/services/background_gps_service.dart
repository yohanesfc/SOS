import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
class BackgroundGpsService {
  static const String notificationChannelId = 'sos_gps_channel';
  static const int notificationId = 888;

  /// Configure the background service settings
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'SOS Background GPS Tracking',
      description: 'Keeps tracking GPS location during active SOS emergencies',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: '🚨 EMERGENCY SOS ACTIVE 🚨',
        initialNotificationContent: 'Locating GPS satellites...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Start the background foreground service
  static Future<void> start() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
  }

  /// Stop the background service and clean up notifications
  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    StreamSubscription<Position>? positionSub;

    // Listen to stop command
    service.on('stopService').listen((event) {
      positionSub?.cancel();
      service.stopSelf();
    });

    // Monitor coordinates continuously
    try {
      positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 3, // Update every 3 meters of movement
        ),
      ).listen((Position position) {
        // Send updates back to main isolate UI layer
        service.invoke('updateLocation', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
        });

        // Push persistent notification update
        flutterLocalNotificationsPlugin.show(
          notificationId,
          '🚨 EMERGENCY SOS ACTIVE 🚨',
          'GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)} (±${position.accuracy.toStringAsFixed(0)}m)',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'SOS Background GPS Tracking',
              channelDescription: 'Keeps tracking GPS location during active SOS emergencies',
              ongoing: true,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      });
    } catch (e) {
      print('--- Background GPS Isolate: Error starting stream: $e ---');
    }
  }
}
