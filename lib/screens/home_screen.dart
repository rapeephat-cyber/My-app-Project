import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/timeguard_service.dart';
import '../services/location_tracking_service.dart';
import '../widgets/common.dart';
import '../widgets/work_area_map_card.dart';
import 'attendance_screen.dart';
import 'outside_work_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService auth;
  final TimeGuardService data;
  final VoidCallback onNotifications;
  const HomeScreen({
    super.key,
    required this.auth,
    required this.data,
    required this.onNotifications,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int revision = 0;
  final LocationTrackingService _tracking = LocationTrackingService();

  @override
  void initState() {
    super.initState();
    _tracking.addListener(_onTrackingUpdate);
  }

  @override
  void dispose() {
    _tracking.removeListener(_onTrackingUpdate);
    super.dispose();
  }

  void _onTrackingUpdate() {
    if (mounted) setState(() {});
  }

  Future<(Attendance?, Dashboard, List<WorkArea>, List<Attendance>, List<OutsideRequest>)>
  load() async {
    final results = await Future.wait<dynamic>([
      widget.data.today(),
      widget.data.summary(),
      widget.data.areas(),
      widget.data.recent(),
      widget.data.requests(active: true),
    ]);

    final areas = results[2] as List<WorkArea>;
    final requests = results[4] as List<OutsideRequest>;

    // Start or update continuous GPS Tracking, Periodic Updates, Geofence Validation
    _tracking.startTracking(
      areas: areas,
      requests: requests,
    );

    return (
      results[0] as Attendance?,
      results[1] as Dashboard,
      areas,
      results[3] as List<Attendance>,
      requests,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      // Top Greeting Header Bar
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
              child: Text(
                widget.auth.employee!.name.characters.first,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สวัสดี 👋 ${widget.auth.employee!.name.split(' ').first}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    widget.auth.employee!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    widget.auth.employee!.position,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                onPressed: widget.onNotifications,
                icon: const Icon(Icons.notifications_none, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: AsyncView(
          key: ValueKey(revision),
          load: load,
          builder: (result) {
            final (today, summary, areas, recent, _) = result;
            final decision = _tracking.decisionResult;
            final geofence = _tracking.geofenceResult;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Status Card (matching mockup: สถานะวันนี้ เข้างานเวลา 07:54 [สำเร็จ])
                _buildTodayStatusCard(today),
                const SizedBox(height: 14),

                // 2. Main Clock & Action Panel
                _buildClockActionPanel(context, today),
                const SizedBox(height: 14),

                // 3. Real-time GPS & Location-based Decision Banner
                _buildLocationDecisionBanner(context, decision, geofence),
                const SizedBox(height: 18),

                // 4. Statistics Row (21 มาทำงาน, 3 มาสาย, 1 ขาดงาน)
                Row(
                  children: [
                    stat('มาทำงาน', summary.present, const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    stat('มาสาย', summary.late, const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    stat('ขาดงาน', summary.absent, const Color(0xFFEF4444)),
                  ],
                ),
                const SizedBox(height: 22),

                // 5. Work Location Section with Interactive Map Card
                WorkAreaMapCard(
                  areas: areas,
                  dataService: widget.data,
                  onCheckInPressed: () => _openAttendance(today),
                ),
                const SizedBox(height: 24),

                // 6. Recent Activity Section
                const Text(
                  'กิจกรรมล่าสุด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                if (recent.isEmpty)
                  const Panel(child: Text('ยังไม่มีประวัติการลงเวลา')),
                for (final a in recent) AttendanceTile(a),
              ],
            );
          },
        ),
      ),
    ],
  );

  /// Status card right below greeting header (matching mockup)
  Widget _buildTodayStatusCard(Attendance? today) {
    final hasCheckedIn = today?.checkIn != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasCheckedIn
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasCheckedIn ? Icons.check : Icons.access_time_rounded,
              color: hasCheckedIn
                  ? const Color(0xFF059669)
                  : const Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สถานะวันนี้',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  hasCheckedIn
                      ? 'เข้างานเวลา ${timeText(today?.checkIn)}'
                      : 'ยังไม่ได้ลงเวลาเข้างาน',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: hasCheckedIn
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              hasCheckedIn ? 'สำเร็จ' : 'รอลงเวลา',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasCheckedIn
                    ? const Color(0xFF059669)
                    : const Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Main Clock and Action Buttons Panel (matching mockup)
  Widget _buildClockActionPanel(BuildContext context, Attendance? today) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const ClockWidget(),
          const SizedBox(height: 20),

          // Primary Blue Action Button (ลงเวลาเข้างาน / ออกงาน)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: today?.checkOut != null
                  ? null
                  : () => _openAttendance(today),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                today?.checkOut != null
                    ? 'ลงเวลาครบแล้ววันนี้'
                    : today?.checkIn != null
                        ? 'ลงเวลาออกงาน'
                        : 'ลงเวลาเข้างาน',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Action Button (ขอปฏิบัติงานนอกสถานที่)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => openPage(
                context,
                OutsideWorkScreen(data: widget.data),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                backgroundColor: Colors.white,
              ),
              child: const Text(
                'ขอปฏิบัติงานนอกสถานที่',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Real-time banner reflecting Location-based Decision & Geofence status
  Widget _buildLocationDecisionBanner(
    BuildContext context,
    LocationDecisionResult decision,
    GeofenceValidationResult geofence,
  ) {
    final isAllowed = decision.canCheckIn;
    final color = isAllowed ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAllowed
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAllowed
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAllowed ? Icons.verified_user_rounded : Icons.location_off_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  decision.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  geofence.isInside
                      ? 'GPS Tracking & Geofence ทำงานปกติ'
                      : geofence.message,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _tracking.refreshLocation(),
            icon: Icon(
              _tracking.isLocating ? Icons.hourglass_top : Icons.refresh,
              size: 18,
              color: color,
            ),
            tooltip: 'รีเฟรช GPS',
          ),
        ],
      ),
    );
  }

  Future<void> _openAttendance(Attendance? today) async {
    await openPage(
      context,
      AttendanceScreen(
        data: widget.data,
        checkOut: today?.checkIn != null,
      ),
    );
    if (mounted) {
      setState(() => revision++);
    }
  }

  Widget stat(String label, int? value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value?.toString() ?? '—',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    ),
  );
}

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});
  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Timer timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return Column(
      children: [
        Text(
          '${DateFormat('HH:mm').format(now)} น.',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('EEEE d MMMM yyyy', 'th').format(now),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
