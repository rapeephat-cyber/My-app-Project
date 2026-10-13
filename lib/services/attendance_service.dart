import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';
import 'timeguard_service.dart';
import 'location_service.dart';
import 'face_service.dart';
import 'location_tracking_service.dart';

class AttendanceService {
  final TimeGuardService data;
  AttendanceService(this.data);
  Future<AttendanceEvent> submit(
    bool checkOut,
    void Function(String) progress, {
    String? faceImageBase64,
    String? evidencePhotoBase64,
    String? reason,
    double? latitude,
    double? longitude,
    double? accuracy,
  }) async {
    if (data.api.token == null) {
      throw const ApiException('กรุณาเข้าสู่ระบบ');
    }
    progress('กำลังตรวจสอบ GPS และ Geofence Validation');
    double lat = latitude ?? 0;
    double lng = longitude ?? 0;
    double acc = accuracy ?? 10;
    if (latitude == null || longitude == null) {
      final p = await LocationService().current();
      lat = p.latitude;
      lng = p.longitude;
      acc = p.accuracy;
    }
    final areas = await data.areas();
    final requests = await data.requests(active: true);

    // Geofence Validation & Location-based Decision
    final geofence = LocationTrackingService.validateGeofence(
      lat: lat,
      lng: lng,
      accuracy: acc,
      areas: areas,
    );
    final decision = LocationTrackingService.makeLocationDecision(
      geofence: geofence,
      offsiteRequests: requests,
      accuracy: acc,
    );

    if (!decision.canCheckIn) {
      throw ApiException(decision.description);
    }
    if ((await data.enrollment()).status != 'approved') {
      throw const ApiException('กรุณาลงทะเบียนใบหน้าและรอ HR อนุมัติก่อน');
    }
    String image = faceImageBase64 ?? '';
    if (image.isEmpty) {
      progress('ถ่ายภาพใบหน้าเพื่อเปรียบเทียบ');
      image = await FaceService().capture();
    }
    progress('กำลังเปรียบเทียบใบหน้าและบันทึกเวลากับเซิร์ฟเวอร์');
    final payload = <String, dynamic>{
      'latitude': lat,
      'longitude': lng,
      'accuracy': acc,
      'device_info': 'TimeGuard/${defaultTargetPlatform.name}',
      'image_base64': image,
    };
    if (reason != null && reason.isNotEmpty) {
      payload['reason'] = reason;
    }
    if (evidencePhotoBase64 != null && evidencePhotoBase64.isNotEmpty) {
      payload['evidence_photo'] = evidencePhotoBase64;
    }
    return AttendanceEvent.fromJson(
      await data.api.post(
        'attendance/${checkOut ? 'check_out' : 'check_in'}.php',
        payload,
      ),
    );
  }
}
