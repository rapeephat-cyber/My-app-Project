<<<<<<< HEAD
# TimeGuard — Approved Data Dictionary

## เว็บ Back Office (เพิ่ม 1 ตุลาคม 2026)

ซอร์สอยู่ใน `backend/timeguard_admin/` สำหรับ Admin, HR และ Supervisor ใช้ฐานข้อมูล/connection ของ PHP API เดิม มี session/RBAC, Dashboard, พนักงาน/แผนก/เจ้าหน้าที่, Leaflet Polygon, มอบหมายพื้นที่, อนุมัติใบหน้า/นอกสถานที่/ลงเวลา, รายงาน/CSV และตั้งค่าเวลา ดู [คู่มือติดตั้งและสิทธิ์](backend/timeguard_admin/README.md) และ [ผลแต่ละ Phase](backend/timeguard_admin/PHASES.md)

เพิ่มเฉพาะตารางเทคนิค `tech_web_audit_logs` ไม่เปลี่ยน 11 ตารางหลัก, Flutter, Google UID หรือ API มือถือ ติดตั้งผ่าน `backend/install-backoffice.php` และ `backend/deploy-backoffice.ps1` แล้วเปิด `http://localhost/timeguard_admin/`.

ติดตั้งลง XAMPP ที่ `C:/xampp/htdocs/timeguard_admin` และเพิ่มตาราง audit ใน `timeguard_db` เรียบร้อยแล้วตามคำสั่งให้ทำให้เสร็จโดยไม่ทดสอบเพิ่มเติม เข้าใช้ด้วยบัญชี Admin/HR/Supervisor เดิม

## เว็บ Back Office (เพิ่ม 1 ตุลาคม 2026)

ซอร์สอยู่ใน `backend/timeguard_admin/` สำหรับ Admin, HR และ Supervisor ใช้ฐานข้อมูล/connection ของ PHP API เดิม มี session/RBAC, Dashboard, พนักงาน/แผนก/เจ้าหน้าที่, Leaflet Polygon, มอบหมายพื้นที่, อนุมัติใบหน้า/นอกสถานที่/ลงเวลา, รายงาน/CSV และตั้งค่าเวลา ดู [คู่มือติดตั้งและสิทธิ์](backend/timeguard_admin/README.md) และ [ผลแต่ละ Phase](backend/timeguard_admin/PHASES.md)

เพิ่มเฉพาะตารางเทคนิค `tech_web_audit_logs` ไม่เปลี่ยน 11 ตารางหลัก, Flutter, Google UID หรือ API มือถือ ติดตั้งผ่าน `backend/install-backoffice.php` และ `backend/deploy-backoffice.ps1` แล้วเปิด `http://localhost/timeguard_admin/`.

## ชื่อตารางเต็ม (แก้ไขตามคำสั่งวันที่ 24 กันยายน 2026)

| ชื่อเดิม | ชื่อในฐานข้อมูล |
|---|---|
| E | employees |
| A | admins |
| H | human_resources |
| S | supervisors |
| D | departments |
| CFG | system_configurations |
| F | face_biometrics |
| G | geofence_areas |
| EA | employee_work_areas |
| OS | offsite_work_requests |
| AT | attendance_logs |

ชื่อฟิลด์, PK/FK, ข้อมูล และรหัส เช่น `E0001` ยังคงเดิม ไฟล์ `docs/approved-data-dictionary.txt` เก็บเอกสารต้นฉบับไว้ และ `config/table_names.php` ระบุชื่อจริงที่ใช้แทนตัวย่อ การเปลี่ยนชื่อครั้งนี้มีผลเหนือชื่อตารางในเอกสารต้นฉบับ

สำหรับฐานข้อมูลที่นำเข้า schema ตัวย่อไว้แล้ว ให้ใช้ `backend/rename-core-tables.php` แทนการ Import SQL ใหม่ซ้ำ สคริปต์ตรวจชื่อตารางชนกันก่อนและไม่ลบข้อมูล:

```powershell
C:\xampp\php\php.exe backend/backup-database.php --config=C:/xampp/htdocs/timeguard_api/config/database.php
C:\xampp\php\php.exe backend/rename-core-tables.php --config=C:/xampp/htdocs/timeguard_api/config/database.php
# หลังตรวจรายการและสำรองข้อมูลแล้ว:
C:\xampp\php\php.exe backend/rename-core-tables.php --config=C:/xampp/htdocs/timeguard_api/config/database.php --apply
```

ต้องใช้ PHP API รุ่นชื่อเต็มร่วมกันด้วย สำรอง API เดิมและคง local.php/integrations.local.php/ภาพเดิมได้ด้วย `powershell -File backend/deploy-current-api.ps1` ไฟล์สำรองอยู่ใน `build/backups` และมีข้อมูลส่วนบุคคล/การตั้งค่า ไม่ควรเผยแพร่

แอปลงเวลางานภาษาไทย Flutter + PHP/PDO + MySQL/MariaDB โดยใช้ **Google OAuth, Face Recognition และ Polygon Geofence**

สัญญาหลักคือ [Data Dictionary ที่ได้รับอนุมัติ](docs/approved-data-dictionary.txt) และ [รายละเอียดการนำไปใช้/การย้ายข้อมูล](backend/timeguard_api/database/CONTRACT.md) ซึ่งมีลำดับความสำคัญเหนือสเปกต้นแบบเดิม

## สิ่งที่เปลี่ยนจากต้นแบบเดิม

- แยก employees (พนักงาน), admins (Admin), human_resources (HR), supervisors (หัวหน้างาน) เป็นคนละตาราง ใช้รหัส varchar(10)
- พนักงานเข้าสู่ระบบด้วย Google เท่านั้น ไม่มีรหัสผ่านใน employees; admins/human_resources/supervisors ใช้ username/password ผ่าน Backoffice
- face_biometrics เก็บ face_image และ face_encoding พร้อม HR approval; ไม่ใช้ local_auth/fingerprint แทนการรู้จำใบหน้า
- geofence_areas เก็บ polygon_coordinates JSON; employee_work_areas เก็บพื้นที่หลัก/รองและช่วงวันใช้งาน
- offsite_work_requests ใช้ช่วงวันและสถานะ รออนุมัติ/อนุมัติ/ปฏิเสธ; หัวหน้าพิจารณาเฉพาะแผนกตนเอง
- attendance_logs เก็บหนึ่งแถวต่อเหตุการณ์เข้างานหรือออกงาน UI จับคู่เพื่อแสดงผลเท่านั้น
- ตารางเทคนิคขึ้นต้น `tech_` แยกจาก 11 ตารางหลัก

## สถานะการใช้งาน

โค้ดนี้ต้องตั้งค่า Google OAuth และบริการ Face Recognition ก่อนลงเวลาจริงได้ ทั้งสองส่วนยังไม่มีค่าบริการจริงของโครงการ หากยังไม่ตั้งค่า ระบบแจ้งข้อผิดพลาดและไม่ข้ามการยืนยัน

**วันที่ 24 กันยายน 2026 เปลี่ยนชื่อตารางในฐานข้อมูลจริง `timeguard_db` เป็นชื่อเต็มแล้ว และอัปเดต PHP ใน XAMPP ให้ตรงกัน** สำรองฐานข้อมูลและ API เดิมไว้ใน `build/backups` ข้อมูลเดิม 8 แถวยังอยู่ครบ และตรวจ 100 ฟิลด์พร้อม PK/FK ผ่าน ไม่ต้อง Import SQL ซ้ำเพื่อเปลี่ยนชื่อ การแก้ซอร์สในอนาคตยังต้อง deploy สำเนา XAMPP ให้ตรงกัน

## 1. ฐานข้อมูลและ PHP

1. สำรองฐานข้อมูลเก่าผ่าน phpMyAdmin ก่อนหากมีข้อมูลแล้ว
2. แนะนำทดสอบในฐานข้อมูลใหม่ เช่น `timeguard_dd` โดยแก้เฉพาะ `CREATE DATABASE` และ `USE` สองบรรทัดแรกของสำเนา `backend/timeguard_api/database/timeguard.sql` จาก `timeguard_db` เป็น `timeguard_dd` แล้ว Import สำเนานั้น
3. SQL ไม่มี DROP/ALTER ตารางเก่า แต่ไม่ใช่ migration ข้อมูลเดิม อ้างอิง CONTRACT.md ก่อนย้ายข้อมูล ห้ามแปลง radius เป็น polygon หรืออนุมัติ local_auth เป็น face_biometrics โดยอัตโนมัติ
4. ติดตั้ง PHP ฉบับใหม่ใน XAMPP พร้อมกับแอปฉบับใหม่ เก็บสำเนา API เดิมและไฟล์ตั้งค่าก่อนคัดลอก ห้ามคัดลอก backend/tests หรือ face_service เข้า public htdocs
5. ใน API ที่ติดตั้ง คัดลอก `config/local.example.php` เป็น `config/local.php` แล้วกำหนดฐานข้อมูลเป้าหมายและบัญชีจริง เครื่องนี้ XAMPP MySQL ใช้พอร์ต **3307**; พอร์ต Apache คือ **80**
6. PHP 8.1+ ต้องมี `pdo_mysql`, `mbstring`, `curl`, `openssl`, `fileinfo` และ `zlib` สำหรับชุดทดสอบ ตั้ง `post_max_size` อย่างน้อย 8M
7. Apache ต้องใช้ `.htaccess` ที่ให้มาปิดการเข้าถึง config/database/storage ถ้าตั้ง server เองต้องป้องกัน directory เหล่านี้ด้วย

`http://localhost/timeguard_api/auth/me.php` คืน HTTP 401 เมื่อไม่มี bearer token ได้ตามปกติ ส่วน `/timeguard_api/` อาจแสดง Forbidden เพราะไม่มีหน้า index และปิด directory listing

## 2. Google OAuth สำหรับพนักงาน

แอปมี Web client ID ของโปรเจกต์เป็นค่าเริ่มต้นใน `lib/config/oauth_config.dart` แล้ว จึงกด Run ที่ `lib/main.dart` หรือใช้ `flutter run` ได้โดยไม่ต้องระบุ dart-define หากเปลี่ยน Google Cloud project ให้แก้ค่านี้ หรือใช้ `--dart-define=GOOGLE_WEB_CLIENT_ID=...` เพื่อ override ค่าเริ่มต้น และตั้ง audience ใน PHP ให้ตรงกัน Client ID เป็นตัวระบุสาธารณะ ไม่ใช่ client secret

1. สร้าง Google Cloud project และกำหนด OAuth consent screen/ผู้ใช้ทดสอบตามประเภทแอป
2. สร้าง OAuth client ชนิด Android ด้วย package `com.example.projectapp` และ SHA-1 ของ signing certificate ที่ใช้รันจริง (debug/release ใช้คนละ certificate)
3. สร้าง **Web application client ID** ใน project เดียวกัน ใช้เป็น server client ID/audience ไม่ต้องใส่ client secret ในแอป
4. คัดลอก `config/integrations.example.php` เป็น `config/integrations.local.php` ใน API แล้วตั้ง `google_client_id` เป็น Web client ID
5. รัน Flutter ด้วย `--dart-define=GOOGLE_WEB_CLIENT_ID=...apps.googleusercontent.com`
6. HR/Admin เพิ่มข้อมูล employees และผูก `google_uid` เป็น Google subject (`sub`) ของพนักงาน เมื่อ Google token ถูกต้องแต่ยังไม่พบการผูก API จะแจ้ง UID ของบัญชีนั้นให้แจ้ง HR ไม่มีการผูกอัตโนมัติจากอีเมลอย่างเดียว

PHP ตรวจ RS256 signature ด้วย certificate จาก Google HTTPS, issuer, audience, expiry, issued-at และ email_verified ก่อนค้นหา employees.google_uid ไม่เชื่อถือ UID ที่ client ส่งมาโดยตรง ใช้ HTTPS สำหรับการใช้งานนอก local debug

เอกสารหลัก: [Google backend authentication](https://developers.google.com/identity/sign-in/android/backend-auth), [google_sign_in](https://pub.dev/packages/google_sign_in)

## 3. บริการ Face Recognition

ดู [คู่มือบริการใบหน้า](backend/face_service/README.md) มี Python service แยกซึ่งสร้าง embedding และเปรียบเทียบใบหน้า ตั้ง `face_service_url` และ `face_service_key` ใน PHP integrations.local.php ให้ตรงกับบริการนี้

- กล้อง Flutter → PHP รับรูป → private recognition service ตรวจและสร้าง/เทียบ encoding
- ลงทะเบียน: บันทึก face_biometrics pending → HR เปิดดูภาพ → อนุมัติหรือปฏิเสธ
- ลงเวลา: PHP โหลด face_biometrics ที่ approved → ให้บริการเทียบภาพปัจจุบันกับ encoding → ตรวจ Polygon/offsite_work_requests/system_configurations → INSERT attendance_logs
- PHP ไม่รับ biometric_verified หรือคะแนนจาก Flutter เป็นหลักฐาน
- รูปถูกเก็บใน storage ที่ไม่เปิดเผยผ่าน HTTP โดยตรง HR ดูผ่าน endpoint ที่ตรวจ token และบทบาท
- ยังไม่มี liveness/PAD จึงไม่ป้องกันภาพถ่ายหรือ replay ได้สมบูรณ์ ยังไม่ได้ทดสอบโมเดลกับใบหน้าจริงหรือเกณฑ์ความแม่นยำของโครงการ

## 4. รันแอป Android

```powershell
flutter pub get
flutter analyze
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Emulator ใช้ `http://10.0.2.2/timeguard_api/` จาก `lib/config/api_config.dart` โทรศัพท์จริงใช้ LAN IP ของคอมพิวเตอร์:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10/timeguard_api/ --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

โทรศัพท์และคอมพิวเตอร์ต้องเข้าถึงกันได้ ใช้ HTTPS นอก local debug; HTTP เปิดเฉพาะ Android debug build กล้องจำเป็นสำหรับใบหน้า GPS ต้องมีสิทธิ์ตำแหน่งละเอียดและ accuracy ไม่เกิน 100 เมตร

Polygon ตัวอย่างเป็นสี่เหลี่ยมรอบ `13.7563,100.5018` กำหนดพิกัด Emulator ตรงกลางนี้เพื่อทดสอบพื้นที่ ไม่ใช้รัศมีเป็นเกณฑ์

## Backoffice และข้อมูลสาธิต

แอปมือถือรองรับเฉพาะพนักงานผ่าน Google Login แล้ว หน้าจัดการ อนุมัติ รายงาน และการเข้าสู่ระบบของ HR/Admin/หัวหน้างานถูกนำออกจาก Flutter เพื่อย้ายไปใช้บนเว็บภายหลัง **ยังไม่ได้สร้างหน้าเว็บ Backoffice ในขั้นตอนนี้**

PHP API และตาราง admins/human_resources/supervisors ยังเก็บไว้สำหรับเว็บ รวมถึงบัญชีทดสอบฝั่ง API:

| บทบาท | username | รหัสผ่านสาธิต |
|---|---|---|
| Admin | admin | 123456 |
| HR | hr | 123456 |
| หัวหน้างาน | supervisor | 123456 |

รหัสผ่านถูก hash ใน SQL บัญชีสาธิตใช้เพื่อพัฒนาเท่านั้น E0001 ไม่มีรหัสผ่านและไม่มี Google UID จำลอง ต้องผูกบัญชีจริงก่อน พื้นที่ G0001 และแผนก D0001 พร้อม assignment ตัวอย่างมีอยู่ แต่ไม่สร้างภาพใบหน้า/encoding/การลงเวลาปลอมให้

HR จัดการ employees/geofence_areas/employee_work_areas และอนุมัติ face_biometrics หัวหน้างานอนุมัติ offsite_work_requests ของพนักงานในแผนกเดียวกัน Admin จัดการ admins/human_resources/supervisors/departments/system_configurations ได้ Admin ไม่สามารถใช้รหัสตนแทน HR หรือ Supervisor ใน approved_by ที่อ้างอิงคนละตาราง

## API contract

ทุก endpoint ใช้ response `success,message,data`; authenticated endpoints ใช้ bearer token ตาราง tech_auth_tokens เก็บ hash และ FK แยกตามตัวตน

| Method | Endpoint | Payload/response สำคัญ |
|---|---|---|
| POST | auth/google.php | id_token → token + session envelope ของ employees |
| POST | auth/login.php | role=admin/hr/supervisor, username, password |
| GET | auth/me.php | `{id,role,profile}`; profile ใช้ชื่อฟิลด์ DD |
| POST | auth/logout.php | เพิกถอน session |
| GET/POST | employee/get_profile.php, employee/update_profile.php | full_name, phone; ไม่แก้ Google UID ผ่านโปรไฟล์ |
| GET | location/get_employee_area.php | geofence_areas ของ employee_work_areas active และช่วงวันถูกต้อง พร้อม metadata assignment |
| POST | biometric/register.php | image_base64 → face_biometrics pending |
| GET | biometric/get_status.php | face_biometrics ปัจจุบัน ไม่ส่ง face_encoding |
| GET | biometric/image.php | รูปของตัวเอง หรือ HR ระบุ biometric_id เพื่อตรวจภาพตรงกับรายการลงทะเบียน |
| POST | attendance/check_in.php, attendance/check_out.php | latitude, longitude, accuracy, device_info, image_base64 → attendance_logs หนึ่งแถว |
| GET | attendance/today.php | attendance_logs array; ไม่มีข้อมูลคืน [] |
| GET | attendance/history.php?month=YYYY-MM | attendance_logs events ของเดือน |
| GET | dashboard/recent_activity.php | 10 attendance_logs ล่าสุด |
| GET | dashboard/summary.php | จำนวนวันเข้า, สาย; absent=null |
| POST | outside_work/create.php | work_date_start, work_date_end, location_description, reason |
| GET | outside_work/list.php?active=1 | คำขออนุมัติที่ครอบคลุมวันปัจจุบัน; ไม่ส่ง active เพื่อดูประวัติ |
| GET | outside_work/detail.php?offsite_request_id=OS0001 | คำขอของตนเอง |
| GET/POST | notifications/list.php, notifications/mark_read.php | technical notifications; mark_read ใช้ id |
| GET | management/list.php?kind=... | requests/attendance/biometrics/employees/areas/assignments/departments/settings/admins/hrs/supervisors |
| POST | management/review.php | kind, คีย์ DD เช่น biometric_id/offsite_request_id, approval_status |
| POST | management/save.php | kind=employee/area/assignment/department/setting/admin/hr/supervisor + ฟิลด์ DD; ส่ง PK เพื่อแก้ไข |

ไม่มี endpoint เดิมที่ใช้ employee password, radius_meters หรือแถว check_in/check_out รวมกันแล้ว

## โครงสร้างและการทดสอบ

`lib/models` เก็บ typed core models และ session/display models แยกกัน; `AttendanceEvent` ตรง attendance_logs ส่วน `Attendance` เป็นการจับคู่เฉพาะหน้าจอ ไม่มีการบันทึก projection กลับฐานข้อมูล `lib/services/geofence_service.dart` และ PHP `config/rules.php` ตรวจ point-in-polygon ทั้งสองฝั่ง

```powershell
flutter analyze
flutter test
C:\xampp\php\php.exe backend/tests/rules_test.php
C:\xampp\php\php.exe backend/tests/google_rules_test.php
$env:TIMEGUARD_DB_PORT='3307'
C:\xampp\php\php.exe backend/tests/integration_test.php
```

Integration tests ต้องใช้บัญชีสร้าง/ลบฐานข้อมูลทดสอบได้ จะสร้างชื่อสุ่ม `timeguard_test_*`, เปิด PHP บน 127.0.0.1:18764 และ private stub ที่ 18765 แล้วปิดและลบเฉพาะข้อมูลทดสอบหลังจบ ไม่เปลี่ยน timeguard_db ใช้ token/image/face-service fixtures จึง **ไม่ใช่** การทดสอบ Google จริงหรือความแม่นยำใบหน้า

ผลตรวจ refactor วันที่ 17 กันยายน 2026:

อัปเดตวันที่ 24 กันยายน 2026: ทดสอบการ rename พร้อมรักษาข้อมูลทั้ง 11 ตารางและ API รวม 79 checks ผ่าน ตรวจ schema ฐานข้อมูลจริงและ PHP syntax ผ่าน การเปลี่ยนชื่อไม่เปลี่ยน JSON contract ของ Flutter

- ตรวจ schema กับไฟล์ Data Dictionary ต้นฉบับ: 100 ฟิลด์ใน 11 ตาราง ชนิดข้อมูล PK และ FK ตรงกัน
- PHP integration ผ่าน 68 checks, Polygon/assignment/ลำดับลงเวลาผ่าน 19 checks และกฎตรวจ Google token ด้วยคีย์ทดสอบผ่าน 9 checks
- `flutter analyze` ผ่านโดยไม่พบปัญหา และ Python face service ผ่านการตรวจ syntax เท่านั้น ยังไม่ได้ติดตั้งหรือรันโมเดลจริง
- เพิ่ม/ปรับ Flutter tests สำหรับ Google-only login (ไม่มีทางเข้า Backoffice), Polygon, employee_work_areas และ attendance_logs แล้ว แต่ยังไม่ได้รันชุดใหม่ เนื่องจากคำขออนุญาต `flutter test` ถูกปฏิเสธในรอบ refactor
- ยังไม่ได้สร้าง APK ใหม่หลัง refactor นี้ APK ที่สร้างในรอบต้นแบบเดิมไม่ใช่รุ่น Google/Face/Polygon

ข้อจำกัดที่ยังมี: หนึ่งคู่ต่อวันตาม Asia/Bangkok (ยังไม่มีกะข้ามเที่ยงคืน), ไม่มีปฏิทินคำนวณขาดงาน, ไม่มี push notification, ยังไม่ได้ทดสอบอุปกรณ์จริงหลังเปลี่ยน Google/กล้อง และไม่มี migration ข้อมูลเก่าแบบอัตโนมัติ
=======
# My-app-Project
>>>>>>> 0dd91b176af989024ef9e1ca1bb33a1f7a32ed7b
