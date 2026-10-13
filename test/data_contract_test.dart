import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp/models/models.dart';
import 'package:projectapp/services/geofence_service.dart';

void main() {
  const polygon = [
    Coordinate(0, 0),
    Coordinate(0, 2),
    Coordinate(1, 2),
    Coordinate(1, 1),
    Coordinate(2, 1),
    Coordinate(2, 0),
  ];
  test(
    'Polygon handles concavity, boundaries, reversed winding and outside',
    () {
      expect(GeofenceService.contains(0.5, 1.5, polygon), isTrue);
      expect(GeofenceService.contains(1.5, 1.5, polygon), isFalse);
      expect(GeofenceService.contains(1, 1, polygon), isTrue);
      expect(GeofenceService.contains(0, 1, polygon), isTrue);
      expect(
        GeofenceService.contains(0.5, 1.5, polygon.reversed.toList()),
        isTrue,
      );
      expect(GeofenceService.contains(-0.1, 0.5, polygon), isFalse);
    },
  );
  test('DA date range is inclusive, inactive and future are excluded', () {
    final assignment = DepartmentArea.fromJson({
      'department_area_id': 'DA0001',
      'department_id': 'D0001',
      'area_id': 'G0001',
      'is_primary': 1,
      'effective_date': '2026-09-01',
      'end_date': '2026-09-17',
      'status': 'active',
    });
    expect(assignment.validOn('2026-09-17'), isTrue);
    expect(assignment.validOn('2026-09-18'), isFalse);
    expect(assignment.validOn('2026-08-31'), isFalse);
    expect(
      DepartmentArea.fromJson({
        ...assignment.toJson(),
        'status': 'inactive',
      }).validOn('2026-09-17'),
      isFalse,
    );
  });
  test('AT keeps string IDs and pairs events only in display model', () {
    final row = {
      'attendance_id': 'AT0001',
      'user_id': 'E0001',
      'area_id': 'G0001',
      'check_type': 'เข้างาน',
      'check_datetime': '2026-09-17 08:00:00',
      'latitude': '13.756300',
      'longitude': '100.501800',
      'verification_method': 'face_recognition',
      'zone_status': 'inside',
      'device_info': 'Android',
      'is_late': 0,
      'evidence_photo': 'storage/a.jpg',
      'reason': null,
      'approval_status': 'อนุมัติ',
      'approved_by': null,
      'approved_date': null,
      'offsite_request_id': null,
    };
    final first = AttendanceEvent.fromJson(row);
    final second = AttendanceEvent.fromJson({
      ...row,
      'attendance_id': 'AT0002',
      'check_type': 'ออกงาน',
      'check_datetime': '2026-09-17 17:00:00',
    });
    expect(first.id, 'AT0001');
    expect(first.toJson().containsKey('check_in_time'), isFalse);
    final paired = Attendance.pair([second, first]).single;
    expect(paired.checkIn, '2026-09-17 08:00:00');
    expect(paired.checkOut, '2026-09-17 17:00:00');
    expect(paired.events.length, 2);
  });
  test('OS preserves approved Thai status and date range', () {
    final row = {
      'offsite_request_id': 'OS0001',
      'employee_id': 'E0001',
      'request_date': '2026-09-17 08:00:00',
      'work_date_start': '2026-09-17',
      'work_date_end': '2026-09-19',
      'location_description': 'สำนักงานลูกค้า',
      'reason': 'ประชุม',
      'approval_status': 'อนุมัติ',
      'approved_by': 'S0001',
      'approved_date': '2026-09-17 08:01:00',
    };
    expect(OutsideRequest.fromJson(row).toJson(), row);
  });
}
