import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:torch_light/torch_light.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/repositories/gps_repository.dart';
import '../../data/repositories/sms_repository.dart';
import '../../data/models/emergency_contact.dart';
import '../../data/models/activity_log.dart';

// ── SOS States ──
enum SosState { idle, countdown, active }

// ── SOS Notifier ──
class SosNotifier extends StateNotifier<SosState> {
  final Ref _ref;
  Timer? _countdownTimer;
  Timer? _flashTimer;
  int _countdown = 5;
  bool _flashOn = false;
  bool _sirenOn = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Position? _lastPosition;

  SosNotifier(this._ref) : super(SosState.idle);

  int get remainingSeconds => _countdown;

  // ─────────────────────────────────────────────
  // COUNTDOWN START (hold button)
  // ─────────────────────────────────────────────
  void beginCountdown() {
    if (state != SosState.idle) return;
    _countdown = 5;
    state = SosState.countdown;
    _ref.read(countdownValueProvider.notifier).state = 5;

    _log('SOS button pressed — countdown started...', 'warning');
    _vibrate([100, 50, 100]); // double buzz

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _countdown--;
      _ref.read(countdownValueProvider.notifier).state = _countdown;
      _vibrate([80]);

      if (_countdown <= 0) {
        t.cancel();
        _activateSos();
      }
    });
  }

  // ─────────────────────────────────────────────
  // CANCEL (release before countdown ends)
  // ─────────────────────────────────────────────
  void cancelCountdown() {
    if (state != SosState.countdown) return;
    _countdownTimer?.cancel();
    _countdown = 5;
    _ref.read(countdownValueProvider.notifier).state = 5;
    state = SosState.idle;
    _log('SOS canceled (button released)', 'info');
  }

  // ─────────────────────────────────────────────
  // ACTIVATE SOS
  // ─────────────────────────────────────────────
  Future<void> _activateSos() async {
    state = SosState.active;
    _log('🚨 SOS ACTIVATED', 'critical');
    _vibrate([200, 100, 200, 100, 500]);

    // Get GPS
    final gpsRepo = _ref.read(gpsRepositoryProvider);
    _lastPosition = await gpsRepo.getCurrentPosition();
    if (_lastPosition != null) {
      _log('GPS: ${_lastPosition!.latitude.toStringAsFixed(5)}, ${_lastPosition!.longitude.toStringAsFixed(5)}', 'success');
    }

    // Send SMS
    await _sendSos();

    // Flash + Siren auto-on
    if (!_flashOn) toggleFlash();
    if (!_sirenOn) toggleSiren();
  }

  // ─────────────────────────────────────────────
  // ABORT SOS (manual stop)
  // ─────────────────────────────────────────────
  void abortSos() {
    _countdownTimer?.cancel();
    _flashTimer?.cancel();
    _audioPlayer.stop();
    _flashOff();
    state = SosState.idle;
    _flashOn = false;
    _sirenOn = false;
    _countdown = 5;
    _ref.read(countdownValueProvider.notifier).state = 5;
    _ref.read(flashActiveProvider.notifier).state = false;
    _ref.read(sirenActiveProvider.notifier).state = false;
    _log('SOS stopped by user', 'warning');
  }

  // ─────────────────────────────────────────────
  // SEND SMS
  // ─────────────────────────────────────────────
  Future<void> _sendSos() async {
    if (_lastPosition == null) {
      _log('GPS not available — SMS cannot be sent', 'warning');
      return;
    }

    final box = Hive.box<EmergencyContact>('contacts');
    final contacts = box.values.toList();

    if (contacts.isEmpty) {
      _log('No emergency contacts saved', 'warning');
      return;
    }

    final smsRepo = SmsRepository();
    final result = await smsRepo.sendSosToAll(
      contacts: contacts,
      position: _lastPosition!,
      senderName: 'SOS App User',
    );

    _log(result.message, result.success ? 'success' : 'critical');
  }

  // ─────────────────────────────────────────────
  // FLASH STROBE — Morse SOS (... --- ...)
  // ─────────────────────────────────────────────
  void toggleFlash() {
    _flashOn = !_flashOn;
    _ref.read(flashActiveProvider.notifier).state = _flashOn;

    if (_flashOn) {
      _log('Flash strobe SOS active (... --- ...)', 'info');
      _runMorseSos();
    } else {
      _flashTimer?.cancel();
      _flashOff();
      _log('Flash turned off', 'info');
    }
  }

  void _runMorseSos() {
    // Morse SOS: ... --- ...
    // dot=150ms, dash=450ms, symbol_gap=150ms, letter_gap=450ms
    final pattern = [
      150, 150, 150, 150, 150, 450, // ...
      450, 450, 450, 450, 450, 450, // ---
      150, 150, 150, 150, 150, 800, // ... (pause)
    ];
    int idx = 0;
    bool isOn = true;

    void tick() {
      if (!_flashOn) return;
      if (isOn) {
        TorchLight.enableTorch().catchError((_) {});
      } else {
        TorchLight.disableTorch().catchError((_) {});
      }
      final delay = pattern[idx % pattern.length];
      isOn = !isOn;
      idx++;
      _flashTimer = Timer(Duration(milliseconds: delay), tick);
    }
    tick();
  }

  void _flashOff() {
    TorchLight.disableTorch().catchError((_) {});
  }

  // ─────────────────────────────────────────────
  // SIREN
  // ─────────────────────────────────────────────
  void toggleSiren() {
    _sirenOn = !_sirenOn;
    _ref.read(sirenActiveProvider.notifier).state = _sirenOn;

    if (_sirenOn) {
      _log('Emergency siren activated', 'warning');
      _playSiren();
    } else {
      _audioPlayer.stop();
      _log('Siren turned off', 'info');
    }
  }

  void _playSiren() async {
    try {
      print('--- Audio: Starting to play siren (audioplayers) ---');
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      print('--- Audio: Loading asset audio/siren.mp3 ---');
      await _audioPlayer.play(AssetSource('audio/siren.mp3'));
      print('--- Audio: play() called successfully ---');
    } catch (e) {
      print('!!! AUDIO ERROR: $e !!!');
      _log('Audio error: $e', 'warning');
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  void _vibrate(List<int> pattern) async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: pattern);
    }
  }

  void _log(String message, String level) {
    final box = Hive.box<ActivityLog>('logs');
    final log = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      timestamp: DateTime.now(),
      level: level,
    );
    box.add(log);
    _ref.read(activityLogProvider.notifier).addLog(log);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _flashTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

// ── Providers ──
final sosProvider = StateNotifierProvider<SosNotifier, SosState>(
  (ref) => SosNotifier(ref),
);

final countdownValueProvider = StateProvider<int>((ref) => 5);
final flashActiveProvider = StateProvider<bool>((ref) => false);
final sirenActiveProvider = StateProvider<bool>((ref) => false);

// ── Activity Log Provider ──
class ActivityLogNotifier extends StateNotifier<List<ActivityLog>> {
  ActivityLogNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = Hive.box<ActivityLog>('logs');
    state = box.values.toList().reversed.toList();
  }

  void addLog(ActivityLog log) {
    state = [log, ...state];
  }

  void clearAll() {
    Hive.box<ActivityLog>('logs').clear();
    state = [];
  }
}

final activityLogProvider = StateNotifierProvider<ActivityLogNotifier, List<ActivityLog>>(
  (ref) => ActivityLogNotifier(),
);
