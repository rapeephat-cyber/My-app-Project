import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp/models/models.dart';
import 'package:projectapp/services/location_tracking_service.dart';
import 'package:projectapp/widgets/work_area_map_card.dart';
import 'package:projectapp/widgets/work_area_map_dialog.dart';

void main() {
  group('Geofence Validation & Location-based Decision', () {
    final testArea = WorkArea.fromJson({
      'area_id': 'AREA_01',
      'area_name': 'สำนักงานใหญ่ พระราม 9',
      'department_id': 'DEP_01',
      'center_latitude': 13.7500,
      'center_longitude': 100.5500,
      'polygon_coordinates': [
        {'lat': 13.7490, 'lng': 100.5490},
        {'lat': 13.7510, 'lng': 100.5490},
        {'lat': 13.7510, 'lng': 100.5510},
        {'lat': 13.7490, 'lng': 100.5510},
      ],
      'status': 'active',
      'created_date': '2026-01-01',
    });

    test('Validates inside geofence polygon', () {
      final result = LocationTrackingService.validateGeofence(
        lat: 13.7500,
        lng: 100.5500,
        accuracy: 10.0,
        areas: [testArea],
      );

      expect(result.isInside, isTrue);
      expect(result.status, GeofenceStatus.inside);
      expect(result.matchedArea?.id, 'AREA_01');
    });

    test('Validates outside geofence polygon', () {
      final result = LocationTrackingService.validateGeofence(
        lat: 13.8000,
        lng: 100.6000,
        accuracy: 15.0,
        areas: [testArea],
      );

      expect(result.isInside, isFalse);
      expect(result.status, GeofenceStatus.outside);
      expect(result.distanceToNearestMeters, greaterThan(1000));
    });

    test('Rejects inaccurate GPS signal (>100m)', () {
      final result = LocationTrackingService.validateGeofence(
        lat: 13.7500,
        lng: 100.5500,
        accuracy: 150.0,
        areas: [testArea],
      );

      expect(result.isInside, isFalse);
      expect(result.status, GeofenceStatus.inaccurate);
    });

    test('Handles empty work areas', () {
      final result = LocationTrackingService.validateGeofence(
        lat: 13.7500,
        lng: 100.5500,
        accuracy: 10.0,
        areas: [],
      );

      expect(result.isInside, isFalse);
      expect(result.status, GeofenceStatus.noArea);
    });

    test('Decision: Allows check-in when inside geofence', () {
      final geofence = LocationTrackingService.validateGeofence(
        lat: 13.7500,
        lng: 100.5500,
        accuracy: 10.0,
        areas: [testArea],
      );

      final decision = LocationTrackingService.makeLocationDecision(
        geofence: geofence,
        offsiteRequests: [],
        accuracy: 10.0,
      );

      expect(decision.canCheckIn, isTrue);
      expect(decision.decisionType, DecisionType.allowOnsite);
      expect(decision.requiresOffsiteRequest, isFalse);
    });

    test('Decision: Blocks check-in when outside without permit', () {
      final geofence = LocationTrackingService.validateGeofence(
        lat: 13.8000,
        lng: 100.6000,
        accuracy: 10.0,
        areas: [testArea],
      );

      final decision = LocationTrackingService.makeLocationDecision(
        geofence: geofence,
        offsiteRequests: [],
        accuracy: 10.0,
      );

      expect(decision.canCheckIn, isFalse);
      expect(decision.decisionType, DecisionType.blockOutsideNoPermit);
      expect(decision.requiresOffsiteRequest, isTrue);
    });

    test('Decision: Allows check-in when outside with approved permit', () {
      final geofence = LocationTrackingService.validateGeofence(
        lat: 13.8000,
        lng: 100.6000,
        accuracy: 10.0,
        areas: [testArea],
      );

      final approvedPermit = OutsideRequest.fromJson({
        'offsite_request_id': 'REQ_01',
        'employee_id': 'E0001',
        'request_date': '2026-01-25',
        'work_date_start': '2026-01-25',
        'work_date_end': '2026-01-25',
        'location_description': 'Site A ลูกค้า',
        'reason': 'ติดตั้งระบบ',
        'approval_status': 'approved',
      });

      final decision = LocationTrackingService.makeLocationDecision(
        geofence: geofence,
        offsiteRequests: [approvedPermit],
        accuracy: 10.0,
      );

      expect(decision.canCheckIn, isTrue);
      expect(decision.decisionType, DecisionType.allowOffsiteApproved);
      expect(decision.requiresOffsiteRequest, isFalse);
    });
  });

  group('WorkAreaMapCard & Dialog Widgets', () {
    final testArea = WorkArea.fromJson({
      'area_id': 'AREA_01',
      'area_name': 'สำนักงานใหญ่ พระราม 9',
      'department_id': 'DEP_01',
      'center_latitude': 13.7500,
      'center_longitude': 100.5500,
      'polygon_coordinates': [
        {'lat': 13.7490, 'lng': 100.5490},
        {'lat': 13.7510, 'lng': 100.5490},
        {'lat': 13.7510, 'lng': 100.5510},
        {'lat': 13.7490, 'lng': 100.5510},
      ],
      'status': 'active',
      'created_date': '2026-01-01',
    });

    testWidgets('WorkAreaMapCard renders properly and responds to tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WorkAreaMapCard(
                areas: [testArea],
              ),
            ),
          ),
        ),
      );

      expect(find.text('ตำแหน่งที่ทำงาน'), findsOneWidget);
      expect(find.text('สำนักงานใหญ่ พระราม 9'), findsOneWidget);
      expect(find.text('แตะเพื่อดูแผนที่'), findsOneWidget);

      // Tap card to open map popup dialog
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(find.byType(WorkAreaMapDialog), findsOneWidget);
    });
  });
}

