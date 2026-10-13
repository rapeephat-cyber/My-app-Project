import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../services/location_tracking_service.dart';
import '../screens/outside_work_screen.dart';
import '../services/timeguard_service.dart';
import 'common.dart';

/// Interactive Map Popup Modal showing:
/// - Real-time GPS Location Tracking
/// - Work Area Geofence Polygon & Center
/// - Periodic Location Updates status
/// - Geofence Validation & Location-based Decision
class WorkAreaMapDialog extends StatefulWidget {
  final WorkArea? initialArea;
  final List<WorkArea> allAreas;
  final TimeGuardService? dataService;
  final VoidCallback? onCheckInPressed;

  const WorkAreaMapDialog({
    super.key,
    this.initialArea,
    required this.allAreas,
    this.dataService,
    this.onCheckInPressed,
  });

  static Future<void> show(
    BuildContext context, {
    WorkArea? area,
    required List<WorkArea> allAreas,
    TimeGuardService? dataService,
    VoidCallback? onCheckInPressed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WorkAreaMapDialog(
        initialArea: area,
        allAreas: allAreas,
        dataService: dataService,
        onCheckInPressed: onCheckInPressed,
      ),
    );
  }

  @override
  State<WorkAreaMapDialog> createState() => _WorkAreaMapDialogState();
}

class _WorkAreaMapDialogState extends State<WorkAreaMapDialog> {
  final MapController _mapController = MapController();
  final LocationTrackingService _trackingService = LocationTrackingService();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _trackingService.addListener(_onTrackingUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !Platform.environment.containsKey('FLUTTER_TEST')) {
        _trackingService.refreshLocation();
      }
    });
  }

  @override
  void dispose() {
    _trackingService.removeListener(_onTrackingUpdate);
    super.dispose();
  }

  void _onTrackingUpdate() {
    if (mounted) setState(() {});
  }

  void _centerToUser() {
    final pos = _trackingService.currentPosition;
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 17);
    }
  }

  void _centerToWorkplace(WorkArea area) {
    _mapController.move(LatLng(area.latitude, area.longitude), 17);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pos = _trackingService.currentPosition;
    final geofence = _trackingService.geofenceResult;
    final decision = _trackingService.decisionResult;
    final activeArea = widget.initialArea ??
        geofence.matchedArea ??
        (widget.allAreas.isNotEmpty ? widget.allAreas.first : null);

    // Initial map center
    final centerLatLng = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : activeArea != null
            ? LatLng(activeArea.latitude, activeArea.longitude)
            : const LatLng(13.7563, 100.5018); // Default Bangkok

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: [
            // Header Bar
            _buildHeader(context, activeArea),

            // Map Area
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: centerLatLng,
                      initialZoom: 16.5,
                      minZoom: 10,
                      maxZoom: 19,
                    ),
                    children: [
                      // OpenStreetMap Tiles
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.timeguard.app',
                      ),

                      // Geofence Polygon Layer
                      if (activeArea != null && activeArea.polygon.isNotEmpty)
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: activeArea.polygon
                                  .map((c) => LatLng(c.lat, c.lng))
                                  .toList(),
                              color: geofence.isInside
                                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                  : const Color(0xFF3B82F6).withValues(alpha: 0.20),
                              borderColor: geofence.isInside
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF2563EB),
                              borderStrokeWidth: 3,
                            ),
                          ],
                        ),

                      // Geofence Circle radius fallback/buffer
                      if (activeArea != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(
                                activeArea.latitude,
                                activeArea.longitude,
                              ),
                              radius: 80,
                              useRadiusInMeter: true,
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                              borderStrokeWidth: 2,
                            ),
                            // User accuracy circle
                            if (pos != null)
                              CircleMarker(
                                point: LatLng(pos.latitude, pos.longitude),
                                radius: pos.accuracy.clamp(5, 80),
                                useRadiusInMeter: true,
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                borderColor: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                                borderStrokeWidth: 1.5,
                              ),
                          ],
                        ),

                      // Markers Layer
                      MarkerLayer(
                        markers: [
                          // 1. Workplace Center Marker
                          if (activeArea != null)
                            Marker(
                              point: LatLng(
                                activeArea.latitude,
                                activeArea.longitude,
                              ),
                              width: 60,
                              height: 60,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.business_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // 2. Employee Live GPS Marker
                          if (pos != null)
                            Marker(
                              point: LatLng(pos.latitude, pos.longitude),
                              width: 65,
                              height: 65,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: geofence.isInside
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (geofence.isInside
                                                  ? Colors.green
                                                  : Colors.red)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_pin_circle_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Map Controls
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Column(
                      children: [
                        _mapButton(
                          icon: Icons.my_location,
                          tooltip: 'พิกัดของฉัน',
                          onPressed: _centerToUser,
                        ),
                        const SizedBox(height: 8),
                        if (activeArea != null)
                          _mapButton(
                            icon: Icons.business,
                            tooltip: 'ตำแหน่งที่ทำงาน',
                            onPressed: () => _centerToWorkplace(activeArea),
                          ),
                        const SizedBox(height: 8),
                        _mapButton(
                          icon: _trackingService.isLocating
                              ? Icons.hourglass_top
                              : Icons.refresh,
                          tooltip: 'อัปเดต GPS',
                          onPressed: _trackingService.isLocating
                              ? null
                              : () => _trackingService.refreshLocation(),
                        ),
                      ],
                    ),
                  ),

                  // Live Geofence Banner on top of map
                  Positioned(
                    left: 16,
                    top: 16,
                    right: 76,
                    child: _buildLiveStatusBadge(geofence),
                  ),
                ],
              ),
            ),

            // Bottom Info & Location Decision Sheet
            _buildBottomDecisionPanel(context, pos, geofence, decision, activeArea, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorkArea? activeArea) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.map_rounded, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'พื้นที่ปฏิบัติงาน (Geofence & Tracking)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  activeArea?.name ?? 'ไม่พบข้อมูลแผนก',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusBadge(GeofenceValidationResult geofence) {
    final isInside = geofence.isInside;
    final color = isInside ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isInside
                  ? 'อยู่ในพื้นที่ทำงาน'
                  : 'อยู่นอกพื้นที่ (${geofence.distanceToNearestMeters.round()} ม.)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDecisionPanel(
    BuildContext context,
    dynamic pos,
    GeofenceValidationResult geofence,
    LocationDecisionResult decision,
    WorkArea? activeArea,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Decision Card (Location-based Decision)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: decision.canCheckIn
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: decision.canCheckIn
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    decision.canCheckIn
                        ? Icons.check_circle_rounded
                        : Icons.info_rounded,
                    color: decision.canCheckIn
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          decision.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: decision.canCheckIn
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB91C1C),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          decision.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Periodic Tracking Metadata Row
            Row(
              children: [
                const Icon(
                  Icons.sensors_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Periodic Tracking: อัปเดตทุก ${_trackingService.periodicInterval.inSeconds} วินาที',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                if (_trackingService.lastUpdate != null)
                  Text(
                    'อัปเดตล่าสุด: ${_timeFormat(_trackingService.lastUpdate!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Coordinates Row
            if (pos != null)
              Text(
                'พิกัด: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)} • ความแม่นยำ ±${pos.accuracy.toStringAsFixed(1)} ม.',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            const SizedBox(height: 16),

            // Action Buttons based on Location Decision
            Row(
              children: [
                if (decision.requiresOffsiteRequest && widget.dataService != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        openPage(
                          context,
                          OutsideWorkScreen(data: widget.dataService!),
                        );
                      },
                      icon: const Icon(Icons.business_center_outlined, size: 18),
                      label: const Text('ขอยื่นนอกสถานที่'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (decision.requiresOffsiteRequest && widget.dataService != null)
                  const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (decision.canCheckIn && widget.onCheckInPressed != null) {
                        widget.onCheckInPressed!();
                      }
                    },
                    icon: Icon(
                      decision.canCheckIn
                          ? Icons.fingerprint
                          : Icons.check,
                      size: 18,
                    ),
                    label: Text(
                      decision.canCheckIn
                          ? 'ลงเวลาทำงาน'
                          : 'เข้าใจแล้ว',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: decision.canCheckIn
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

            // Toggle Tracking History
            if (_trackingService.breadcrumbs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showHistory = !_showHistory),
                  icon: Icon(
                    _showHistory
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                  label: Text(
                    _showHistory
                        ? 'ซ่อนประวัติการอัปเดต (${_trackingService.breadcrumbs.length})'
                        : 'ดูประวัติ Periodic Location Updates (${_trackingService.breadcrumbs.length})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (_showHistory)
                Container(
                  height: 110,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: _trackingService.breadcrumbs.length,
                    separatorBuilder: (_, _) => const Divider(height: 8),
                    itemBuilder: (ctx, idx) {
                      final item = _trackingService.breadcrumbs[idx];
                      return Row(
                        children: [
                          Icon(
                            item.isInside
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 14,
                            color: item.isInside
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeFormat(item.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)} (±${item.accuracy.round()}ม.)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Text(
                            item.isInside ? 'ในพื้นที่' : 'นอกพื้นที่',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.isInside
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF1E293B), size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  String _timeFormat(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} น.';
  }
}
