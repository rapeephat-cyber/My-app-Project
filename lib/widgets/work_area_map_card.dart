import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/location_tracking_service.dart';
import '../services/timeguard_service.dart';
import 'work_area_map_dialog.dart';

/// Map Card displayed on the HomeScreen for "ตำแหน่งที่ทำงาน / พื้นที่ปฏิบัติงานของแผนก".
/// Tapping this card opens the interactive WorkAreaMapDialog popup.
class WorkAreaMapCard extends StatefulWidget {
  final List<WorkArea> areas;
  final TimeGuardService? dataService;
  final VoidCallback? onCheckInPressed;

  const WorkAreaMapCard({
    super.key,
    required this.areas,
    this.dataService,
    this.onCheckInPressed,
  });

  @override
  State<WorkAreaMapCard> createState() => _WorkAreaMapCardState();
}

class _WorkAreaMapCardState extends State<WorkAreaMapCard>
    with SingleTickerProviderStateMixin {
  final LocationTrackingService _tracking = LocationTrackingService();
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    // Don't repeat infinitely in test environments to avoid pumpAndSettle timeout
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest && widget.areas.isNotEmpty) {
      _radarController.repeat();
    }
    _tracking.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _radarController.dispose();
    _tracking.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _openMapPopup() {
    WorkAreaMapDialog.show(
      context,
      area: widget.areas.isNotEmpty ? widget.areas.first : null,
      allAreas: widget.areas,
      dataService: widget.dataService,
      onCheckInPressed: widget.onCheckInPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.areas.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ตำแหน่งที่ทำงาน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.location_off_outlined,
                  size: 40,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(height: 10),
                Text(
                  'แผนกยังไม่ได้กำหนดพื้นที่ปฏิบัติงาน',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final area = widget.areas.first;
    final geofence = _tracking.geofenceResult;
    final isInside = geofence.isInside;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ตำแหน่งที่ทำงาน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            GestureDetector(
              onTap: _openMapPopup,
              child: Row(
                children: [
                  Text(
                    isInside ? 'อยู่ในพื้นที่' : 'อยู่นอกพื้นที่',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isInside
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: isInside
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Interactive Map Card Container matching user mockup
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openMapPopup,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Styled Blueprint Map Canvas
                    CustomPaint(
                      painter: _MapBlueprintPainter(),
                    ),

                    // Radar Pulse & Geofence Rings Animation
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _GeofenceRadarPainter(
                            progress: _radarController.value,
                            isInside: isInside,
                          ),
                        );
                      },
                    ),

                    // Center Location Pin (Cyan / Neon Blue Icon)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C6FF)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              size: 44,
                              color: Color(0xFF00C6FF),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),

                    // Bottom info gradient overlay with area name and tap hint
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                area.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 12,
                                    color: Color(0xFF2563EB),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'แตะเพื่อดูแผนที่',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter to draw the light blue architectural street map texture
class _MapBlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Map Base Color (Light cyan / slate blue)
    final bgPaint = Paint()..color = const Color(0xFF90C2DE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Water / Coast curves
    final waterPaint = Paint()
      ..color = const Color(0xFF7CB6D8)
      ..style = PaintingStyle.fill;

    final waterPath = Path();
    waterPath.moveTo(0, size.height * 0.7);
    waterPath.cubicTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width * 0.6,
      size.height * 0.4,
      size.width,
      size.height * 0.8,
    );
    waterPath.lineTo(size.width, size.height);
    waterPath.lineTo(0, size.height);
    waterPath.close();
    canvas.drawPath(waterPath, waterPaint);

    // 3. Grid road lines (subtle white curves and street grid)
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final majorRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // Major Highway curve
    final majorPath = Path();
    majorPath.moveTo(0, size.height * 0.82);
    majorPath.cubicTo(
      size.width * 0.35,
      size.height * 0.75,
      size.width * 0.65,
      size.height * 0.45,
      size.width,
      size.height * 0.35,
    );
    canvas.drawPath(majorPath, majorRoadPaint);

    // Secondary curve
    final secondaryPath = Path();
    secondaryPath.moveTo(0, size.height * 0.4);
    secondaryPath.cubicTo(
      size.width * 0.4,
      size.height * 0.3,
      size.width * 0.7,
      size.height * 0.85,
      size.width,
      size.height * 0.65,
    );
    canvas.drawPath(secondaryPath, majorRoadPaint);

    // Grid of local streets
    for (double x = 10; x < size.width; x += 28) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.4, size.height),
        roadPaint,
      );
    }

    for (double y = 10; y < size.height; y += 22) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 15),
        roadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the animated green Geofence concentric radar rings
class _GeofenceRadarPainter extends CustomPainter {
  final double progress;
  final bool isInside;

  _GeofenceRadarPainter({
    required this.progress,
    required this.isInside,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const baseColor = Color(0xFF10B981);

    // Concentric green geofence zones
    final fixedRingPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final fillPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Outer Geofence Zone
    canvas.drawCircle(center, 58, fillPaint);
    canvas.drawCircle(center, 58, fixedRingPaint);

    // Mid Geofence Zone
    canvas.drawCircle(
      center,
      42,
      Paint()
        ..color = baseColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Inner Geofence Zone
    canvas.drawCircle(
      center,
      26,
      Paint()
        ..color = baseColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Pulsing radar ripple
    final pulseRadius = 26 + (progress * 38);
    final pulseAlpha = (1.0 - progress).clamp(0.0, 1.0);
    final pulsePaint = Paint()
      ..color = baseColor.withValues(alpha: pulseAlpha * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _GeofenceRadarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isInside != isInside;
  }
}

