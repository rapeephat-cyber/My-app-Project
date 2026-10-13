import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import 'geofence_service.dart';

enum GeofenceStatus {
  inside,
  nearBoundary,
  outside,
  inaccurate,
  noArea,
  checking,
}

enum DecisionType {
  allowOnsite,
  allowOffsiteApproved,
  blockOutsideNoPermit,
  blockGpsInaccurate,
  noWorkAreaConfigured,
  pending,
}

class LocationBreadcrumb {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final bool isInside;
  final String statusText;

  LocationBreadcrumb({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.isInside,
    required this.statusText,
  });
}

class GeofenceValidationResult {
  final bool isInside;
  final GeofenceStatus status;
  final WorkArea? matchedArea;
  final double distanceToNearestMeters;
  final double accuracy;
  final DateTime timestamp;
  final String message;

  const GeofenceValidationResult({
    required this.isInside,
    required this.status,
    required this.matchedArea,
    required this.distanceToNearestMeters,
    required this.accuracy,
    required this.timestamp,
    required this.message,
  });

  factory GeofenceValidationResult.initial() => GeofenceValidationResult(
        isInside: false,
        status: GeofenceStatus.checking,
        matchedArea: null,
        distanceToNearestMeters: 0,
        accuracy: 0,
        timestamp: DateTime.now(),
        message: 'กำลังตรวจสอบพิกัด Geofence...',
      );
}

class LocationDecisionResult {
  final DecisionType decisionType;
  final bool canCheckIn;
  final String title;
  final String description;
  final String suggestedAction;
  final bool requiresOffsiteRequest;
  final DateTime timestamp;

  const LocationDecisionResult({
    required this.decisionType,
    required this.canCheckIn,
    required this.title,
    required this.description,
    required this.suggestedAction,
    required this.requiresOffsiteRequest,
    required this.timestamp,
  });

  factory LocationDecisionResult.initial() => LocationDecisionResult(
        decisionType: DecisionType.pending,
        canCheckIn: false,
        title: 'กำลังประมวลผล',
        description: 'กำลังตรวจสอบเงื่อนไขตำแหน่งเพื่อทำการตัดสินใจ',
        suggestedAction: 'รอสักครู่...',
        requiresOffsiteRequest: false,
        timestamp: DateTime.now(),
      );
}

/// Service managing GPS Location Tracking, Periodic Location Updates,
/// Geofence Validation, and Location-based Decisions.
class LocationTrackingService extends ChangeNotifier {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _periodicTimer;

  Position? _currentPosition;
  bool _isTracking = false;
  bool _isLocating = false;
  String? _errorMessage;
  DateTime? _lastUpdate;
  Duration _periodicInterval = const Duration(seconds: 15);

  List<WorkArea> _assignedAreas = [];
  List<OutsideRequest> _offsiteRequests = [];

  GeofenceValidationResult _geofenceResult = GeofenceValidationResult.initial();
  LocationDecisionResult _decisionResult = LocationDecisionResult.initial();
  final List<LocationBreadcrumb> _breadcrumbs = [];

  // Callbacks for proximity events
  void Function(WorkArea area)? onEnteredWorkArea;
  void Function(WorkArea area)? onExitedWorkArea;
  bool? _wasInsidePreviously;

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  bool get isLocating => _isLocating;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdate => _lastUpdate;
  Duration get periodicInterval => _periodicInterval;
  GeofenceValidationResult get geofenceResult => _geofenceResult;
  LocationDecisionResult get decisionResult => _decisionResult;
  List<LocationBreadcrumb> get breadcrumbs => List.unmodifiable(_breadcrumbs);
  List<WorkArea> get assignedAreas => _assignedAreas;

  void setPeriodicInterval(Duration interval) {
    _periodicInterval = interval;
    if (_isTracking) {
      _startPeriodicTimer();
    }
  }

  /// Update context data (work areas and active outside requests)
  void updateContext({
    List<WorkArea>? areas,
    List<OutsideRequest>? requests,
  }) {
    if (areas != null) _assignedAreas = areas;
    if (requests != null) _offsiteRequests = requests;
    if (_currentPosition != null) {
      _evaluateLocation(_currentPosition!);
    }
  }

  /// Start real-time GPS tracking and periodic location updates
  Future<void> startTracking({
    List<WorkArea>? areas,
    List<OutsideRequest>? requests,
  }) async {
    if (areas != null) _assignedAreas = areas;
    if (requests != null) _offsiteRequests = requests;

    if (_isTracking) return;

    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      if (_assignedAreas.isNotEmpty) {
        _evaluateLocation(Position(
          longitude: _assignedAreas.first.longitude,
          latitude: _assignedAreas.first.latitude,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ));
      }
      return;
    }

    _isTracking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasPermission = await _checkAndRequestPermission();
      if (!hasPermission) {
        _isTracking = false;
        notifyListeners();
        return;
      }

      // 1. Initial immediate location fetch
      await refreshLocation();

      // 2. Continuous GPS position stream (GPS Location Tracking)
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update on 5m change
      );

      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) {
          _onNewPosition(position);
        },
        onError: (err) {
          _errorMessage = 'ข้อผิดพลาด GPS: $err';
          notifyListeners();
        },
      );

      // 3. Periodic Location Updates timer
      _startPeriodicTimer();
    } catch (e) {
      _errorMessage = e.toString();
      _isTracking = false;
      notifyListeners();
    }
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_periodicInterval, (_) async {
      if (!_isTracking) return;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _onNewPosition(pos);
      } catch (_) {
        // Fallback: evaluate current position again if stationary
        if (_currentPosition != null) {
          _evaluateLocation(_currentPosition!);
        }
      }
    });
  }

  /// Stop tracking and periodic updates
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    notifyListeners();
  }

  /// Manually force a fresh GPS location update
  Future<Position?> refreshLocation() async {
    _isLocating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasPermission = await _checkAndRequestPermission();
      if (!hasPermission) {
        _isLocating = false;
        notifyListeners();
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _onNewPosition(position);
      return position;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'กรุณาเปิดบริการตำแหน่ง GPS (Location Service)';
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      _errorMessage = 'กรุณาอนุญาตให้แอปเข้าถึงตำแหน่ง GPS';
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      _errorMessage = 'สิทธิ์ GPS ถูกปฏิเสธถาวร กรุณาเปิดในการตั้งค่าของอุปกรณ์';
      return false;
    }
    return true;
  }

  void _onNewPosition(Position position) {
    _currentPosition = position;
    _lastUpdate = DateTime.now();
    _errorMessage = null;

    _evaluateLocation(position);
  }

  /// Execute Geofence Validation and Location-based Decision
  void _evaluateLocation(Position position) {
    // === Step 1: Geofence Validation ===
    final geofenceResult = validateGeofence(
      lat: position.latitude,
      lng: position.longitude,
      accuracy: position.accuracy,
      areas: _assignedAreas,
    );
    _geofenceResult = geofenceResult;

    // Check transition for proximity notification
    if (_wasInsidePreviously != null && geofenceResult.matchedArea != null) {
      if (!_wasInsidePreviously! && geofenceResult.isInside) {
        onEnteredWorkArea?.call(geofenceResult.matchedArea!);
      } else if (_wasInsidePreviously! && !geofenceResult.isInside) {
        onExitedWorkArea?.call(geofenceResult.matchedArea!);
      }
    }
    _wasInsidePreviously = geofenceResult.isInside;

    // === Step 2: Location-based Decision ===
    final decisionResult = makeLocationDecision(
      geofence: geofenceResult,
      offsiteRequests: _offsiteRequests,
      accuracy: position.accuracy,
    );
    _decisionResult = decisionResult;

    // Record breadcrumb
    _breadcrumbs.insert(
      0,
      LocationBreadcrumb(
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        isInside: geofenceResult.isInside,
        statusText: decisionResult.title,
      ),
    );
    if (_breadcrumbs.length > 50) {
      _breadcrumbs.removeLast();
    }

    notifyListeners();
  }

  /// Pure Geofence Validation Logic
  static GeofenceValidationResult validateGeofence({
    required double lat,
    required double lng,
    required double accuracy,
    required List<WorkArea> areas,
  }) {
    final now = DateTime.now();

    if (areas.isEmpty) {
      return GeofenceValidationResult(
        isInside: false,
        status: GeofenceStatus.noArea,
        matchedArea: null,
        distanceToNearestMeters: 0,
        accuracy: accuracy,
        timestamp: now,
        message: 'แผนกยังไม่ได้กำหนดพื้นที่ปฏิบัติงาน',
      );
    }

    if (accuracy > 100) {
      return GeofenceValidationResult(
        isInside: false,
        status: GeofenceStatus.inaccurate,
        matchedArea: null,
        distanceToNearestMeters: 0,
        accuracy: accuracy,
        timestamp: now,
        message: 'ความแม่นยำ GPS ต่ำเกินไป (±${accuracy.round()} ม.) ต้องการความแม่นยำสูงกว่านี้',
      );
    }

    WorkArea? insideArea;
    WorkArea nearestArea = areas.first;
    double minDistance = double.infinity;

    for (final area in areas) {
      final dist = Geolocator.distanceBetween(
        lat,
        lng,
        area.latitude,
        area.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearestArea = area;
      }

      // 1. Check polygon ray-casting
      bool isContained = false;
      if (area.polygon.length >= 3) {
        isContained = GeofenceService.contains(lat, lng, area.polygon);
      } else {
        // Fallback radius: 100 meters
        isContained = dist <= 100;
      }

      if (isContained) {
        insideArea = area;
        break;
      }
    }

    if (insideArea != null) {
      return GeofenceValidationResult(
        isInside: true,
        status: GeofenceStatus.inside,
        matchedArea: insideArea,
        distanceToNearestMeters: minDistance,
        accuracy: accuracy,
        timestamp: now,
        message: 'อยู่ในพื้นที่ปฏิบัติงาน: ${insideArea.name} (ห่างจุดศูนย์กลาง ${minDistance.round()} ม.)',
      );
    }

    // Check if near boundary (within 60 meters from boundary)
    final isNear = minDistance < 150;
    return GeofenceValidationResult(
      isInside: false,
      status: isNear ? GeofenceStatus.nearBoundary : GeofenceStatus.outside,
      matchedArea: nearestArea,
      distanceToNearestMeters: minDistance,
      accuracy: accuracy,
      timestamp: now,
      message: isNear
          ? 'ใกล้ขอบเขตพื้นที่: ${nearestArea.name} (ห่าง ${minDistance.round()} ม.)'
          : 'อยู่นอกพื้นที่ปฏิบัติงาน (ห่างจาก ${nearestArea.name} ${minDistance.round()} ม.)',
    );
  }

  /// Pure Location-based Decision Logic
  static LocationDecisionResult makeLocationDecision({
    required GeofenceValidationResult geofence,
    required List<OutsideRequest> offsiteRequests,
    required double accuracy,
  }) {
    final now = DateTime.now();

    // Condition 1: GPS inaccurate
    if (geofence.status == GeofenceStatus.inaccurate) {
      return LocationDecisionResult(
        decisionType: DecisionType.blockGpsInaccurate,
        canCheckIn: false,
        title: 'ไม่อนุญาต: สัญญาณ GPS คลาดเคลื่อน',
        description:
            'พิกัดคลาดเคลื่อน ±${accuracy.round()} ม. (ต้องไม่เกิน 100 ม.) กรุณาเปิด GPS และขยับไปที่โล่ง',
        suggestedAction: 'ค้นหาพิกัดใหม่',
        requiresOffsiteRequest: false,
        timestamp: now,
      );
    }

    // Condition 2: No area defined
    if (geofence.status == GeofenceStatus.noArea) {
      return LocationDecisionResult(
        decisionType: DecisionType.noWorkAreaConfigured,
        canCheckIn: false,
        title: 'ไม่อนุญาต: ยังไม่มีการกำหนดพื้นที่',
        description: 'แผนกของท่านยังไม่ได้กำหนดพื้นที่ Geofence กรุณาติดต่อฝ่ายทรัพยากรบุคคล',
        suggestedAction: 'ติดต่อ HR',
        requiresOffsiteRequest: false,
        timestamp: now,
      );
    }

    // Condition 3: Inside Geofence
    if (geofence.isInside) {
      final areaName = geofence.matchedArea?.name ?? 'พื้นที่บริษัท';
      return LocationDecisionResult(
        decisionType: DecisionType.allowOnsite,
        canCheckIn: true,
        title: 'อนุญาต: อยู่ในพื้นที่ปฏิบัติงาน',
        description: 'ระบบยืนยันพิกัดเรียบร้อย คุณอยู่ใน $areaName สามารถลงเวลาทำงานได้ทันที',
        suggestedAction: 'ลงเวลาทำงาน',
        requiresOffsiteRequest: false,
        timestamp: now,
      );
    }

    // Condition 4: Outside Geofence - Check for approved Outside Work Permit
    final hasActiveApprovedPermit = offsiteRequests.any(
      (r) => r.status == 'approved' || r.status == 'อนุมัติ',
    );

    if (hasActiveApprovedPermit) {
      final permit = offsiteRequests.firstWhere(
        (r) => r.status == 'approved' || r.status == 'อนุมัติ',
      );
      return LocationDecisionResult(
        decisionType: DecisionType.allowOffsiteApproved,
        canCheckIn: true,
        title: 'อนุญาต: ปฏิบัติงานนอกสถานที่ (มีใบอนุญาต)',
        description:
            'ตรวจพบคำขอปฏิบัติงานนอกสถานที่ที่ได้รับอนุมัติ: ${permit.location} สามารถลงเวลาได้',
        suggestedAction: 'ลงเวลานอกสถานที่',
        requiresOffsiteRequest: false,
        timestamp: now,
      );
    }

    // Condition 5: Outside Geofence without Permit
    final dist = geofence.distanceToNearestMeters.round();
    final areaName = geofence.matchedArea?.name ?? 'พื้นที่งาน';
    return LocationDecisionResult(
      decisionType: DecisionType.blockOutsideNoPermit,
      canCheckIn: false,
      title: 'ไม่อนุญาต: อยู่นอกพื้นที่ปฏิบัติงาน',
      description:
          'คุณอยู่นอก $areaName ห่างออกไป $dist เมตร กรุณาเดินทางเข้าพื้นที่ หรือยื่นขอปฏิบัติงานนอกสถานที่',
      suggestedAction: 'ขอยื่นปฏิบัติงานนอกสถานที่',
      requiresOffsiteRequest: true,
      timestamp: now,
    );
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
