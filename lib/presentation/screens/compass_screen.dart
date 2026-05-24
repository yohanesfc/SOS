import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/compass_repository.dart';

class CompassScreen extends ConsumerStatefulWidget {
  const CompassScreen({super.key});

  @override
  ConsumerState<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends ConsumerState<CompassScreen>
    with SingleTickerProviderStateMixin {
  double? _lockedBearing;
  bool _isLocked = false;
  late AnimationController _needleController;

  @override
  void initState() {
    super.initState();
    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _needleController.dispose();
    super.dispose();
  }

  void _toggleLock(double currentHeading) {
    setState(() {
      _isLocked = !_isLocked;
      _lockedBearing = _isLocked ? currentHeading : null;
    });
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎯 Bearing ${currentHeading.toStringAsFixed(0)}° locked',
            style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1),
          ),
          backgroundColor: AppColors.surface2,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final compassStream = ref.watch(compassStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: compassStream.when(
        data: (event) => _buildCompass(event.heading ?? 0, event.accuracy),
        loading: () => _buildCompass(0, null),
        error: (_, __) => _buildCompass(0, null, noSensor: true),
      ),
    );
  }

  Widget _buildCompass(double heading, double? accuracy, {bool noSensor = false}) {
    final displayHeading = _isLocked ? _lockedBearing! : heading;
    final label = CompassRepository.headingToLabel(displayHeading);
    final short = CompassRepository.headingToShort(displayHeading);

    return Column(
      children: [
        // ── Compass Rose ──
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer bezel
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.3, -0.3),
                    colors: [Color(0xFF2A2A2A), Color(0xFF0F0F0F), Color(0xFF000000)],
                  ),
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 24, spreadRadius: 4),
                  ],
                ),
              ),

              // Tick marks (CustomPainter)
              CustomPaint(
                size: const Size(280, 280),
                painter: _TickPainter(),
              ),

              // Rotating rose dial
              AnimatedRotation(
                turns: -displayHeading / 360,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: _CompassDial(),
              ),

              // Fixed needle
              _CompassNeedle(),

              // Fixed top marker
              Positioned(
                top: 12,
                child: Container(
                  width: 0,
                  height: 0,
                  decoration: const BoxDecoration(),
                  child: CustomPaint(
                    size: const Size(10, 12),
                    painter: _TrianglePainter(),
                  ),
                ),
              ),

              // Center pivot
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF555555), Color(0xFF111111)],
                  ),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),

              // Heading readout
              Positioned(
                bottom: 28,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${displayHeading.toStringAsFixed(0).padLeft(3, '0')}°',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: AppColors.textDim,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Data chips ──
        Row(
          children: [
            Expanded(child: _DataChip(label: 'HEADING', value: '${displayHeading.toStringAsFixed(0).padLeft(3,'0')}°')),
            const SizedBox(width: 8),
            const Expanded(child: _DataChip(label: 'DIRECTION', value: '—', valueColor: AppColors.yellow)),
            const SizedBox(width: 8),
            Expanded(child: _DataChip(
              label: 'ACCURACY',
              value: accuracy != null ? '±${accuracy.toStringAsFixed(0)}°' : 'N/A',
              valueColor: accuracy != null && accuracy < 15 ? AppColors.green : AppColors.yellow,
            )),
          ],
        ),

        const SizedBox(height: 10),

        // ── Sensor status ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Text('🧲', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noSensor ? 'SENSOR NOT AVAILABLE' : 'MAGNETOMETER ACTIVE',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1),
                    ),
                    Text(
                      noSensor ? 'Device does not have a compass' : 'DeviceOrientation · REAL-TIME',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.textDim, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: noSensor ? AppColors.yellow.withOpacity(0.1) : AppColors.green.withOpacity(0.08),
                  border: Border.all(
                    color: noSensor ? AppColors.yellow.withOpacity(0.3) : AppColors.green.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  noSensor ? 'SIM' : 'LIVE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: noSensor ? AppColors.yellow : AppColors.green,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Lock bearing ──
        GestureDetector(
          onTap: () => _toggleLock(heading),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isLocked ? AppColors.green.withOpacity(0.06) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isLocked ? AppColors.greenDim : AppColors.border,
              ),
            ),
            child: Text(
              _isLocked
                  ? '🔒 BEARING ${_lockedBearing!.toStringAsFixed(0)}° LOCKED — TAP TO UNLOCK'
                  : '🎯 LOCK CURRENT BEARING',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 1.5,
                color: _isLocked ? AppColors.green : AppColors.textDim,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Tips ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.yellow.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.yellow.withOpacity(0.15)),
          ),
          child: const Text(
            '⚠ MOUNTAIN TIPS:\n'
            '· Keep away from metal & powerbanks\n'
            '· Calibration: wave phone in figure-8 pattern\n'
            '· Magnetic North ≠ True North (declination ~1°E)\n'
            '· Always cross-check with landmarks',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: AppColors.textDim,
              height: 1.8,
              letterSpacing: 0.8,
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Sub Widgets ──

class _CompassDial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 228,
      height: 228,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0D0D0D),
            ),
          ),
          // Cardinals
          ...[
            ('N', Alignment(0, -0.82), AppColors.red, 20.0),
            ('S', Alignment(0, 0.82), AppColors.textPrimary, 18.0),
            ('E', Alignment(0.82, 0), AppColors.textPrimary, 18.0),
            ('W', Alignment(-0.82, 0), AppColors.textPrimary, 18.0),
          ].map((e) => Align(
            alignment: e.$2,
            child: Text(
              e.$1,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: e.$4,
                fontWeight: FontWeight.bold,
                color: e.$3,
                shadows: e.$3 == AppColors.red
                    ? [const Shadow(color: AppColors.red, blurRadius: 8)]
                    : null,
              ),
            ),
          )),
          // Intercardinals
          ...[
            ('NE', Alignment(0.55, -0.55)),
            ('NW', Alignment(-0.55, -0.55)),
            ('SE', Alignment(0.55, 0.55)),
            ('SW', Alignment(-0.55, 0.55)),
          ].map((e) => Align(
            alignment: e.$2,
            child: Text(
              e.$1,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: AppColors.textDim,
                letterSpacing: 0.5,
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _CompassNeedle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 14,
      child: Column(
        children: [
          CustomPaint(
            size: const Size(14, 55),
            painter: _NorthNeedlePainter(),
          ),
          CustomPaint(
            size: const Size(14, 45),
            painter: _SouthNeedlePainter(),
          ),
        ],
      ),
    );
  }
}

class _NorthNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.red
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = AppColors.red.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.85)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SouthNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF444444)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height * 0.15)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final R = size.width / 2 - 4;

    for (int i = 0; i < 72; i++) {
      final angle = (i * 5 - 90) * math.pi / 180;
      final isMajor = i % 9 == 0;
      final isMed = i % 3 == 0 && !isMajor;
      final len = isMajor ? 16.0 : isMed ? 10.0 : 5.0;
      final color = isMajor
          ? const Color(0xFF555555)
          : isMed
              ? const Color(0xFF3A3A3A)
              : const Color(0xFF2A2A2A);

      final paint = Paint()
        ..color = color
        ..strokeWidth = isMajor ? 2 : 1
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(cx + (R - len) * math.cos(angle), cy + (R - len) * math.sin(angle)),
        Offset(cx + R * math.cos(angle), cy + R * math.sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.red
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
    paint.maskFilter = null;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _DataChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DataChip({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 8, color: AppColors.textDim, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
