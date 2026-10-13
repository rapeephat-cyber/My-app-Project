import 'package:flutter/material.dart';
import '../models/models.dart';

class Panel extends StatelessWidget {
  final Widget child;
  const Panel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final color =
        [
          'approved',
          'อนุมัติ',
          'present',
          'approved_outside_area',
        ].contains(status)
        ? const Color(0xFF12B981)
        : ['rejected', 'ปฏิเสธ', 'absent'].contains(status)
        ? const Color(0xFFEF4444)
        : const Color(0xFFFF922B);
    return Chip(
      label: Text(statusText(status), style: TextStyle(color: color)),
      backgroundColor: color.withValues(alpha: 0.09),
      side: BorderSide.none,
    );
  }
}

class ErrorPanel extends StatelessWidget {
  final Object error;
  final VoidCallback retry;
  const ErrorPanel(this.error, this.retry, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(error.toString(), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: retry, child: const Text('ลองใหม่')),
      ],
    ),
  );
}

class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(T data) builder;
  const AsyncView({super.key, required this.load, required this.builder});
  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> future;
  @override
  void initState() {
    super.initState();
    future = widget.load();
  }

  Future<void> reload() async {
    // Start the request outside setState. An assignment expression returns its
    // value, so `() => future = widget.load()` accidentally returns a Future.
    final reloadedFuture = widget.load();
    if (mounted) {
      setState(() {
        future = reloadedFuture;
      });
    }
    try {
      await reloadedFuture;
    } catch (_) {
      /* Displayed by FutureBuilder. */
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: ErrorPanel(snapshot.error!, reload));
      }
      return RefreshIndicator(
        onRefresh: reload,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: widget.builder(snapshot.data as T),
        ),
      );
    },
  );
}

class AttendanceTile extends StatelessWidget {
  final Attendance item;
  const AttendanceTile(this.item, {super.key});
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.date,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            StatusBadge(item.status),
          ],
        ),
        Text(
          'เข้างาน ${timeText(item.checkIn)}    •    ออกงาน ${timeText(item.checkOut)}',
        ),
      ],
    ),
  );
}

void showMessage(BuildContext context, Object message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message.toString())));
Future<T?> openPage<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));
