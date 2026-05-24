import 'package:another_telephony/telephony.dart';
import 'package:geolocator/geolocator.dart';
import '../models/emergency_contact.dart';

class SmsRepository {
  final Telephony _telephony = Telephony.instance;

  Future<bool> requestPermission() async {
    return await _telephony.requestSmsPermissions ?? false;
  }

  Future<SmsResult> sendSosToAll({
    required List<EmergencyContact> contacts,
    required Position position,
    required String senderName,
  }) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      return SmsResult(success: false, failedCount: contacts.length, message: 'Permission denied');
    }

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
    final lat = position.latitude.toStringAsFixed(6);
    final lng = position.longitude.toStringAsFixed(6);
    final alt = position.altitude.toStringAsFixed(0);
    final acc = position.accuracy.toStringAsFixed(0);

    final smsBody = '🚨 EMERGENCY SOS 🚨\n'
        '$senderName needs immediate assistance!\n\n'
        '📍 LOCATION:\n'
        'Lat: $lat, Lng: $lng\n'
        '⬆ Elevation: ${alt}m | Accuracy: ±${acc}m\n\n'
        '⏰ Time: $timeStr\n'
        '🗺 https://maps.google.com/?q=${position.latitude},${position.longitude}\n\n'
        'Send assistance to this location immediately!';

    int sent = 0;
    int failed = 0;

    for (final contact in contacts) {
      try {
        await _telephony.sendSms(
          to: contact.phone,
          message: smsBody,
          isMultipart: true,
        );
        sent++;
      } catch (e) {
        failed++;
      }
    }

    return SmsResult(
      success: sent > 0,
      sentCount: sent,
      failedCount: failed,
      message: 'Sent to $sent/${contacts.length} contacts',
    );
  }
}

class SmsResult {
  final bool success;
  final int sentCount;
  final int failedCount;
  final String message;

  const SmsResult({
    required this.success,
    this.sentCount = 0,
    required this.failedCount,
    required this.message,
  });
}
