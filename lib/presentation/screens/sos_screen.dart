import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/gps_repository.dart';
import '../providers/sos_provider.dart';

class SosScreen extends ConsumerWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosState = ref.watch(sosProvider);
    final countdown = ref.watch(countdownValueProvider);
    final flashActive = ref.watch(flashActiveProvider);
    final sirenActive = ref.watch(sirenActiveProvider);
    final posAsync = ref.watch(positionStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── GPS Bar ──
          _GpsBar(posAsync: posAsync),
          const SizedBox(height: 14),

          // ── Status Alert ──
          _StatusAlert(state: sosState),
          const SizedBox(height: 20),

          // ── SOS Button ──
          _SosButton(state: sosState, countdown: countdown),
          const SizedBox(height: 14),

          // ── System chips ──
          _SystemChips(),
          const SizedBox(height: 14),

          // ── Quick Actions ──
          _QuickActions(
            flashActive: flashActive,
            sirenActive: sirenActive,
            sosState: sosState,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── GPS Bar ──
class _GpsBar extends ConsumerWidget {
  final AsyncValue<Position> posAsync;
  const _GpsBar({required this.posAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedAddress = ref.watch(resolvedAddressProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: posAsync.when(
        data: (pos) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.green.withOpacity(0.3)),
                  ),
                  child: const Center(child: Text('📍', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GPS COORDINATES', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.textDim, letterSpacing: 1.5)),
                      Text(
                        '${pos.latitude.toStringAsFixed(4)}° ${pos.latitude >= 0 ? 'N' : 'S'}, '
                        '${pos.longitude.toStringAsFixed(4)}° ${pos.longitude >= 0 ? 'E' : 'W'}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.green, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('ACCURACY', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.textDim, letterSpacing: 1)),
                    Text('±${pos.accuracy.toStringAsFixed(0)}m', style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.yellow, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            if (resolvedAddress != null) ...[
              const SizedBox(height: 10),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('🏔️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resolvedAddress,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        loading: () => const Row(
          children: [
            Text('📍', style: TextStyle(fontSize: 20)),
            SizedBox(width: 12),
            Text('Locking GPS...', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textDim)),
            Spacer(),
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
          ],
        ),
        error: (_, __) => const Row(
          children: [
            Text('⚠', style: TextStyle(fontSize: 20)),
            SizedBox(width: 12),
            Text('GPS not available', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.yellow)),
          ],
        ),
      ),
    );
  }
}

// ── Status Alert ──
class _StatusAlert extends StatelessWidget {
  final SosState state;
  const _StatusAlert({required this.state});

  @override
  Widget build(BuildContext context) {
    final (icon, title, sub, borderColor, bgColor) = switch (state) {
      SosState.idle => ('🛡️', 'SYSTEM STANDBY', 'HOLD SOS BUTTON TO ACTIVATE',
          AppColors.border, Colors.transparent),
      SosState.countdown => ('⚠', 'COUNTING DOWN...', 'RELEASE BUTTON TO CANCEL',
          AppColors.orange, AppColors.orange.withOpacity(0.08)),
      SosState.active => ('🚨', 'SOS ACTIVE — ASSISTANCE REQUIRED!', 'SMS SENT · SIREN ACTIVE',
          AppColors.red, AppColors.red.withOpacity(0.08)),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(state == SosState.idle ? 1 : 0.5)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  color: state == SosState.idle ? AppColors.textDim : state == SosState.countdown ? AppColors.orange : AppColors.red,
                )),
                Text(sub, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.textDim, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── SOS Button ──
class _SosButton extends ConsumerStatefulWidget {
  final SosState state;
  final int countdown;
  const _SosButton({required this.state, required this.countdown});

  @override
  ConsumerState<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends ConsumerState<_SosButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _ringController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
  }

  @override
  void didUpdateWidget(_SosButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == SosState.countdown && oldWidget.state != SosState.countdown) {
      _ringController.forward(from: 0);
    } else if (widget.state == SosState.idle) {
      _ringController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sos = ref.read(sosProvider.notifier);
    final isActive = widget.state == SosState.active;
    final isCounting = widget.state == SosState.countdown;

    return Column(
      children: [
        SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse rings
              if (isActive || isCounting)
                ...List.generate(3, (i) => AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Transform.scale(
                    scale: 0.9 + (_pulseController.value * 0.3) + (i * 0.1),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isActive ? AppColors.red : AppColors.orange).withOpacity(
                            (1 - _pulseController.value) * 0.4 / (i + 1),
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                )),

              // Countdown ring (SVG-like)
              if (isCounting)
                AnimatedBuilder(
                  animation: _ringController,
                  builder: (_, __) => CustomPaint(
                    size: const Size(210, 210),
                    painter: _CountdownRingPainter(progress: _ringController.value),
                  ),
                ),

              // Main button
              GestureDetector(
                onTapDown: isActive ? null : (_) => sos.beginCountdown(),
                onTapUp: isCounting ? (_) => sos.cancelCountdown() : null,
                onTapCancel: isCounting ? sos.cancelCountdown : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      colors: isActive
                          ? [const Color(0xFFFF2200), const Color(0xFFCC0000), const Color(0xFF880000)]
                          : [const Color(0xFF3D0000), const Color(0xFF1A0000), const Color(0xFF0D0000)],
                    ),
                    border: Border.all(
                      color: isActive ? AppColors.red : isCounting ? AppColors.orange : AppColors.redDim,
                      width: isActive ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isActive ? AppColors.red : isCounting ? AppColors.orange : AppColors.redDim)
                            .withOpacity(isActive ? 0.6 : isCounting ? 0.4 : 0.2),
                        blurRadius: isActive ? 60 : isCounting ? 40 : 20,
                        spreadRadius: isActive ? 10 : 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isCounting ? 'SOS' : 'SOS',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: isCounting ? 32 : 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: isActive || isCounting ? Colors.white : AppColors.red,
                          shadows: [Shadow(color: AppColors.red, blurRadius: isActive ? 30 : 20)],
                        ),
                      ),
                      if (isCounting) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${widget.countdown}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.yellow, shadows: [Shadow(color: AppColors.yellow, blurRadius: 15)]),
                        ),
                      ],
                      Text(
                        isActive ? '● ACTIVE' : 'PANIC BUTTON',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.textDim, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Hint / Cancel button
        if (widget.state == SosState.idle)
          const Text('⬆ HOLD 5 SECONDS TO ACTIVATE', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textDim, letterSpacing: 1.5)),

        if (widget.state == SosState.countdown || widget.state == SosState.active)
          TextButton(
            onPressed: sos.abortSos,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.orange,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              widget.state == SosState.active ? '✕ STOP SOS' : '✕ CANCEL',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, letterSpacing: 2),
            ),
          ),
      ],
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  final double progress;
  const _CountdownRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width, height: size.height);
    canvas.drawArc(rect, -math.pi / 2, progress * 2 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter old) => old.progress != progress;
}

// ── System Chips ──
class _SystemChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';

    return Row(
      children: [
        Expanded(child: _SysChip(icon: '🔋', label: 'BATTERY', value: '78%', valueColor: AppColors.green)),
        const SizedBox(width: 8),
        Expanded(child: _SysChip(icon: '📡', label: 'SIGNAL', value: 'WEAK', valueColor: AppColors.yellow)),
        const SizedBox(width: 8),
        Expanded(child: _SysChip(icon: '⏱', label: 'TIME', value: time, valueColor: AppColors.textPrimary)),
      ],
    );
  }
}

class _SysChip extends StatelessWidget {
  final String icon, label, value;
  final Color valueColor;
  const _SysChip({required this.icon, required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 8, color: AppColors.textDim, letterSpacing: 1.5)),
                Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: valueColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ──
class _QuickActions extends ConsumerWidget {
  final bool flashActive, sirenActive;
  final SosState sosState;
  const _QuickActions({required this.flashActive, required this.sirenActive, required this.sosState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sos = ref.read(sosProvider.notifier);
    final posAsync = ref.watch(positionStreamProvider);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: [
        _QaButton(
          icon: '🔦', label: flashActive ? 'Flash: ON ●' : 'Flash Strobe',
          sub: 'SOS MORSE SIGNAL', active: flashActive,
          onTap: sos.toggleFlash,
        ),
        _QaButton(
          icon: '🔊', label: sirenActive ? 'Sirine: ON ●' : 'Emergency Siren',
          sub: '115 dB MAX', active: sirenActive,
          onTap: sos.toggleSiren,
        ),
        _QaButton(
          icon: '📤', label: 'Send SOS SMS',
          sub: '+ GPS COORDINATES', active: false,
          onTap: () {/* open SMS modal */},
        ),
        _QaButton(
          icon: '🗺', label: 'Location Info',
          sub: 'GPS DETAILS', active: false,
          onTap: () => _showLocationInfo(context, posAsync),
        ),
      ],
    );
  }

  void _showLocationInfo(BuildContext context, AsyncValue<Position> posAsync) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📍', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                const Text('LOCATION INFO',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    )),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, color: AppColors.textDim, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 16),
            posAsync.when(
              data: (pos) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow('LATITUDE',
                      '${pos.latitude.toStringAsFixed(6)}° ${pos.latitude >= 0 ? 'N' : 'S'}'),
                  const SizedBox(height: 10),
                  _InfoRow('LONGITUDE',
                      '${pos.longitude.toStringAsFixed(6)}° ${pos.longitude >= 0 ? 'E' : 'W'}'),
                  const SizedBox(height: 10),
                  _InfoRow('ELEVATION', '${pos.altitude.toStringAsFixed(1)} m'),
                  const SizedBox(height: 10),
                  _InfoRow('ACCURACY', '±${pos.accuracy.toStringAsFixed(0)} m'),
                  const SizedBox(height: 10),
                  _InfoRow('UPDATED', _formatTime(pos.timestamp)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green.withOpacity(0.15),
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.green),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('OPEN IN GOOGLE MAPS',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, letterSpacing: 1)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final mapsUrl = Uri.parse(
                          'geo:${pos.latitude},${pos.longitude}?q=${pos.latitude},${pos.longitude}&z=17',
                        );
                        // Try native geo: URI first (opens Google Maps on Android)
                        if (await canLaunchUrl(mapsUrl)) {
                          await launchUrl(mapsUrl);
                        } else {
                          // Fallback: open in browser
                          final webUrl = Uri.parse(
                            'https://maps.google.com/?q=${pos.latitude},${pos.longitude}',
                          );
                          await launchUrl(webUrl,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                ],
              ),
              loading: () => const Center(
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    CircularProgressIndicator(color: AppColors.green, strokeWidth: 2),
                    SizedBox(height: 12),
                    Text('Waiting for GPS signal...',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textDim)),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              error: (e, _) => Column(
                children: [
                  const Text('⚠', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  const Text('Location permission required',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.yellow)),
                  const SizedBox(height: 4),
                  const Text('Please grant location access in\nAndroid Settings → App Permissions',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.textDim)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Geolocator.openAppSettings();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Open App Settings',
                        style: TextStyle(fontFamily: 'monospace', color: AppColors.green, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
}

// ── Info Row for Location Bottom Sheet ──
class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: AppColors.textDim,
                letterSpacing: 1.5,
              )),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              )),
        ),
      ],
    );
  }
}

class _QaButton extends StatelessWidget {
  final String icon, label, sub;
  final bool active;
  final VoidCallback onTap;
  const _QaButton({required this.icon, required this.label, required this.sub, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.yellow.withOpacity(0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.yellow.withOpacity(0.3) : AppColors.border),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? AppColors.yellow : AppColors.textPrimary)),
                  Text(sub, style: const TextStyle(fontFamily: 'monospace', fontSize: 8, color: AppColors.textDim, letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
