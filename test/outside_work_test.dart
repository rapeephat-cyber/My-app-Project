import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp/models/models.dart';
import 'package:projectapp/screens/outside_work_screen.dart';
import 'package:projectapp/services/api_service.dart';
import 'package:projectapp/services/timeguard_service.dart';

class MockApiService extends ApiService {
  MockApiService() : super();

  @override
  String? get token => 'MOCK_TOKEN';

  @override
  Future<dynamic> get(String path, [Map<String, String>? query]) async {
    if (path.contains('outside_work/list.php')) {
      return [
        {
          'offsite_request_id': 'REQ_01',
          'employee_id': 'EMP_01',
          'request_date': '2026-10-13',
          'work_date_start': '2026-10-13 13:00',
          'work_date_end': '2026-10-13 16:30',
          'location_description': 'บริษัท เอบีซี จำกัด',
          'reason': 'ไปพบลูกค้าเพื่อนำเสนอสินค้า',
          'approval_status': 'รออนุมัติ',
          'approved_by': null,
          'approved_date': null,
        }
      ];
    }
    return [];
  }

  @override
  Future<dynamic> post(String path, [Json body = const {}]) async {
    return {
      'status': 'success',
      'message': 'คำขอถูกบันทึกแล้ว',
    };
  }
}

void main() {
  testWidgets('OutsideWorkScreen renders Form matching Mockup 1', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final service = TimeGuardService(MockApiService());

    await tester.pumpWidget(
      MaterialApp(
        home: OutsideWorkScreen(data: service),
      ),
    );
    await tester.pump();

    // Check title & subtitle
    expect(find.text('ขอปฏิบัติงานนอกสถานที่'), findsOneWidget);
    expect(find.textContaining('กรอกรายละเอียดการออกปฏิบัติงานนอกพื้นที่'), findsOneWidget);

    // Check form labels & fields
    expect(find.text('สถานที่ / บริษัทที่ไปติดต่อ'), findsOneWidget);
    expect(find.text('เช่น บริษัท เอบีซี จำกัด'), findsOneWidget);

    expect(find.text('เหตุผลในการออกปฏิบัติงาน'), findsOneWidget);
    expect(find.textContaining('เช่น ไปพบลูกค้าเพื่อนำเสนอสินค้า'), findsOneWidget);

    expect(find.text('เวลาที่ออก'), findsOneWidget);
    expect(find.text('เวลาที่คาดว่าจะกลับ'), findsOneWidget);
    expect(find.text('13:00 น.'), findsOneWidget);
    expect(find.text('16:30 น.'), findsOneWidget);

    // Check photo section
    expect(find.text('รูปภาพประกอบ (หน้างาน / ใบสั่งงาน)'), findsOneWidget);
    expect(find.text('ถ่ายภาพหรือแนบไฟล์ประกอบคำขอ'), findsOneWidget);
    expect(find.text('เปิดกล้อง'), findsOneWidget);

    // Check warning message
    expect(find.textContaining('คำขอจะถูกส่งไปยังหัวหน้างานของคุณเพื่อพิจารณาอนุมัติ'), findsOneWidget);

    // Check buttons
    expect(find.text('ส่งคำขอ'), findsOneWidget);
    expect(find.text('ยกเลิก'), findsOneWidget);
  });

  testWidgets('OutsideWorkScreen photo capture simulation works', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final service = TimeGuardService(MockApiService());

    await tester.pumpWidget(
      MaterialApp(
        home: OutsideWorkScreen(data: service),
      ),
    );
    await tester.pump();

    // Tap เปิดกล้อง
    await tester.tap(find.text('เปิดกล้อง'));
    await tester.pump();

    // After photo capture, should show "ถ่ายใหม่" and "ลบรูป"
    expect(find.text('ถ่ายใหม่'), findsOneWidget);
    expect(find.text('ลบรูป'), findsOneWidget);

    // Tap ลบรูป
    await tester.tap(find.text('ลบรูป'));
    await tester.pump();

    // Should return to initial camera button
    expect(find.text('เปิดกล้อง'), findsOneWidget);
  });

  testWidgets('OutsideWorkScreen validates and submits to Success View matching Mockup 2', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final service = TimeGuardService(MockApiService());

    await tester.pumpWidget(
      MaterialApp(
        home: OutsideWorkScreen(data: service),
      ),
    );
    await tester.pump();

    // 1. Submit empty -> should show validation errors
    await tester.tap(find.text('ส่งคำขอ'));
    await tester.pump();

    expect(find.text('กรุณากรอกสถานที่หรือบริษัทที่ไปติดต่อ'), findsOneWidget);
    expect(find.text('กรุณากรอกเหตุผลในการออกปฏิบัติงาน'), findsOneWidget);

    // 2. Fill form
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'บริษัท เอบีซี จำกัด');
    await tester.enterText(textFields.at(1), 'ไปพบลูกค้าเพื่อนำเสนอสินค้า');
    await tester.pump();

    // 3. Submit
    await tester.tap(find.text('ส่งคำขอ'));
    await tester.pumpAndSettle();

    // 4. Verify Success View (Mockup 2)
    expect(find.text('สถานะการยืนยันตัวตน'), findsOneWidget);
    expect(find.text('ส่งคำขอสำเร็จ'), findsOneWidget);
    expect(find.textContaining('คำขอปฏิบัติงานนอกสถานที่ถูกส่งไปยัง'), findsOneWidget);
    expect(find.text('สถานที่'), findsOneWidget);
    expect(find.text('บริษัท เอบีซี จำกัด'), findsOneWidget);
    expect(find.text('เวลาที่ขอออก'), findsOneWidget);
    expect(find.text('13:00 – 16:30 น.'), findsOneWidget);
    expect(find.text('สถานะ'), findsOneWidget);
    expect(find.text('รออนุมัติ'), findsOneWidget);
    expect(find.text('กลับไปที่หน้าหลัก'), findsOneWidget);
  });
}

