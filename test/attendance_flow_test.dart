import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp/models/models.dart';
import 'package:projectapp/screens/attendance_screen.dart';
import 'package:projectapp/services/api_service.dart';
import 'package:projectapp/services/timeguard_service.dart';

class MockApiService extends ApiService {
  MockApiService() : super();

  @override
  String? get token => 'MOCK_TOKEN';

  @override
  Future<dynamic> get(String path, [Map<String, String>? query]) async {
    if (path.contains('areas.php')) {
      return [
        {
          'area_id': 'AREA_01',
          'area_name': 'ตึกสารสนเทศ อาคาร 11',
          'department_id': 'DEP_01',
          'center_latitude': 13.7563,
          'center_longitude': 100.5018,
          'polygon_coordinates': [
            {'lat': 13.755, 'lng': 100.501},
            {'lat': 13.757, 'lng': 100.501},
            {'lat': 13.757, 'lng': 100.503},
            {'lat': 13.755, 'lng': 100.503},
          ],
          'status': 'active',
          'created_date': '2026-01-01',
        }
      ];
    }
    if (path.contains('enrollment.php')) {
      return {
        'status': 'approved',
        'enrollment_id': 'ENR_01',
        'created_date': '2026-01-01',
      };
    }
    return [];
  }

  @override
  Future<dynamic> post(String path, [Json body = const {}]) async {
    return {
      'attendance_id': 'ATT_999',
      'user_id': 'U01',
      'check_type': 'เข้างาน',
      'check_datetime': '2026-10-13T09:18:00',
      'latitude': 13.7563,
      'longitude': 100.5018,
      'verification_method': 'face_scan',
      'zone_status': 'inside',
      'approval_status': 'pending',
      'is_late': true,
      'reason': body['reason'] ?? '',
    };
  }
}

Future<void> pumpUntilLoaded(WidgetTester tester) async {
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
}

void main() {
  setUp(() {});

  testWidgets('AttendanceFlow: Step 1 GPS check renders correctly with map and info', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockApi = MockApiService();
    final timeGuard = TimeGuardService(mockApi);

    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceScreen(
          data: timeGuard,
          checkOut: false,
        ),
      ),
    );
    await pumpUntilLoaded(tester);

    // Verify Step 1 GPS check content
    expect(find.text('กำลังตรวจสอบตำแหน่ง GPS'), findsOneWidget);
    expect(find.text('ระบบกำลังยืนยันว่าคุณอยู่ในพื้นที่ปฏิบัติงาน'), findsOneWidget);
    expect(find.text('พื้นที่ปฏิบัติงาน'), findsOneWidget);
    expect(find.text('ตึกสารสนเทศ อาคาร 11'), findsOneWidget);
    expect(find.text('ระยะห่างจากจุดศูนย์กลาง'), findsOneWidget);
    expect(find.text('รัศมีที่กำหนด'), findsOneWidget);
    expect(find.text('อยู่ในพื้นที่กำหนด'), findsOneWidget);
  });

  testWidgets('AttendanceFlow: Step 1.1 Outside Geofence renders warning and actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockApi = MockApiService();
    final timeGuard = TimeGuardService(mockApi);

    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceScreen(
          data: timeGuard,
          checkOut: false,
        ),
      ),
    );
    await pumpUntilLoaded(tester);

    // Tap simulator to go to 1.1 outside geofence
    final outsideSim = find.text('จำลอง: อยู่นอกพื้นที่ (ดู Mockup 1.1)');
    expect(outsideSim, findsOneWidget);
    await tester.ensureVisible(outsideSim);
    await tester.tap(outsideSim);
    await pumpUntilLoaded(tester);

    // Verify 1.1 content
    expect(find.text('อยู่นอกพื้นที่ที่กำหนด'), findsOneWidget);
    expect(find.text('OUTSIDE GEOFENCE'), findsOneWidget);
    expect(find.text('อยู่นอกพื้นที่ปฏิบัติงาน'), findsOneWidget);
    expect(find.text('อยู่ห่างจากพื้นที่ที่กำหนด 350 เมตร'), findsOneWidget);
    expect(
      find.text('การลงเวลาต้องอยู่ภายในรัศมี 100 เมตรของพื้นที่สำนักงานที่กำหนด'),
      findsOneWidget,
    );
    expect(find.text('ตรวจสอบตำแหน่งอีกครั้ง'), findsOneWidget);
    expect(find.text('ติดต่อหัวหน้างาน'), findsOneWidget);
  });

  testWidgets('AttendanceFlow: Step 2 Face Verification renders segmented ring and indicators', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockApi = MockApiService();
    final timeGuard = TimeGuardService(mockApi);

    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceScreen(
          data: timeGuard,
          checkOut: false,
        ),
      ),
    );
    await pumpUntilLoaded(tester);

    // Tap "อยู่ในพื้นที่กำหนด" to advance to Step 2
    final btn = find.text('อยู่ในพื้นที่กำหนด');
    await tester.ensureVisible(btn);
    await tester.tap(btn);
    await pumpUntilLoaded(tester);

    // Verify Step 2 Face Verification content
    expect(find.text('ยืนยันตัวตนด้วยใบหน้า'), findsOneWidget);
    expect(find.text('มองตรงเข้ากล้องและอยู่นิ่ง ๆ สักครู่'), findsOneWidget);
    expect(find.text('แสงสว่างเพียงพอ'), findsOneWidget);
    expect(find.text('ไม่สวมหน้ากาก'), findsOneWidget);
    expect(find.text('กำลังจับคู่ใบหน้า'), findsOneWidget);
    expect(find.text('กลับไปที่หน้าหลัก'), findsOneWidget);
  });

  testWidgets('AttendanceFlow: Step 2.1 Face Verification Failed screen renders correctly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockApi = MockApiService();
    final timeGuard = TimeGuardService(mockApi);

    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceScreen(
          data: timeGuard,
          checkOut: false,
        ),
      ),
    );
    await pumpUntilLoaded(tester);

    // Advance to Step 2
    final btn = find.text('อยู่ในพื้นที่กำหนด');
    await tester.ensureVisible(btn);
    await tester.tap(btn);
    await pumpUntilLoaded(tester);

    // Trigger fail simulation (2.1)
    final failSim = find.text('จำลอง: ไม่ผ่าน (2.1)');
    await tester.ensureVisible(failSim);
    await tester.tap(failSim);
    await pumpUntilLoaded(tester);

    // Verify 2.1 content
    expect(find.text('สถานะการยืนยันตัวตน'), findsOneWidget);
    expect(find.text('ไม่สามารถลงเวลาเข้าได้'), findsOneWidget);
    expect(find.text('ระบบไม่สามารถยืนยันตัวตนด้วยใบหน้าได้'), findsOneWidget);
    expect(find.text('ACCESS DENIED'), findsOneWidget);
    expect(
      find.text('โปรดตรวจสอบให้มีแสงสว่างเพียงพอ\nถอดสิ่งบดบังใบหน้า เช่น หมวกหรือแว่นกันแดด\nแล้วลองอีกครั้ง'),
      findsOneWidget,
    );
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
    expect(find.text('ติดต่อหัวหน้างาน'), findsOneWidget);
  });

  testWidgets('AttendanceFlow: Step 2.2 Late check-in submission renders all form fields', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockApi = MockApiService();
    final timeGuard = TimeGuardService(mockApi);

    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceScreen(
          data: timeGuard,
          checkOut: false,
        ),
      ),
    );
    await pumpUntilLoaded(tester);

    // Advance to Step 2
    final btn = find.text('อยู่ในพื้นที่กำหนด');
    await tester.ensureVisible(btn);
    await tester.tap(btn);
    await pumpUntilLoaded(tester);

    // Trigger late simulation (2.2)
    final lateSim = find.text('จำลอง: สาย (2.2)');
    await tester.ensureVisible(lateSim);
    await tester.tap(lateSim);
    await pumpUntilLoaded(tester);

    // Verify 2.2 content
    expect(find.text('ตรวจพบว่าคุณลงเวลาเข้างานสาย 18 นาที'), findsOneWidget);
    expect(find.text('แนบรูปภาพและเหตุผลประกอบ'), findsOneWidget);
    expect(find.text('ถ่ายภาพหน้างานประกอบ'), findsOneWidget);
    expect(find.text('เปิดกล้อง'), findsOneWidget);
    expect(find.text('เหตุผลที่มาสาย'), findsOneWidget);
    expect(find.text('เวลาที่ลงเวลาเข้างาน'), findsOneWidget);
    expect(find.text('สถานะคำขอ'), findsOneWidget);
    expect(find.text('ส่งให้หัวหน้างานตรวจสอบ'), findsOneWidget);
    expect(find.text('ส่งหลักฐานและลงเวลา'), findsOneWidget);

    // Tap submit button
    final submitBtn = find.text('ส่งหลักฐานและลงเวลา');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await pumpUntilLoaded(tester);

    // Verify Completed Success view matching new mockup 2
    expect(find.text('ลงเวลาเข้างานสำเร็จ!'), findsOneWidget);
    expect(find.text('บันทึกเวลาปฏิบัติงานของคุณเรียบร้อยแล้ว'), findsOneWidget);
    expect(find.text('เวลาที่บันทึก'), findsOneWidget);
    expect(find.text('วันที่'), findsOneWidget);
    expect(find.text('สถานที่ยืนยัน'), findsOneWidget);
    expect(find.text('วิธีการยืนยันตัวตน'), findsOneWidget);
    expect(find.text('Face ID + GPS'), findsOneWidget);
    expect(find.text('กลับไปที่หน้าหลัก'), findsOneWidget);
  });

  testWidgets('AttendanceFlow: Normal flow renders Verifying Identity and Check-in Success', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockApi = MockApiService();
    final timeGuard = TimeGuardService(mockApi);

    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceScreen(
          data: timeGuard,
          checkOut: false,
        ),
      ),
    );
    await pumpUntilLoaded(tester);

    // Advance to Step 2
    final btn = find.text('อยู่ในพื้นที่กำหนด');
    await tester.ensureVisible(btn);
    await tester.tap(btn);
    await pumpUntilLoaded(tester);

    // Tap "จำลอง: เช็คอินสำเร็จ"
    final successSim = find.text('จำลอง: เช็คอินสำเร็จ');
    await tester.ensureVisible(successSim);
    await tester.tap(successSim);
    await pumpUntilLoaded(tester);

    // Verify Check-in Success screen matching mockup 2
    expect(find.text('สถานะการยืนยันตัวตน'), findsOneWidget);
    expect(find.text('ลงเวลาเข้างานสำเร็จ!'), findsOneWidget);
    expect(find.text('บันทึกเวลาปฏิบัติงานของคุณเรียบร้อยแล้ว'), findsOneWidget);
    expect(find.text('เวลาที่บันทึก'), findsOneWidget);
    expect(find.text('วันที่'), findsOneWidget);
    expect(find.text('สถานที่ยืนยัน'), findsOneWidget);
    expect(find.text('วิธีการยืนยันตัวตน'), findsOneWidget);
    expect(find.text('Face ID + GPS'), findsOneWidget);
    expect(find.text('กลับไปที่หน้าหลัก'), findsOneWidget);
  });
}
