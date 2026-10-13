import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/app_theme.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/timeguard_service.dart';
import 'screens/login_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/common.dart';

class TimeGuardApp extends StatefulWidget {
  const TimeGuardApp({super.key});
  @override
  State<TimeGuardApp> createState() => _TimeGuardAppState();
}

class _TimeGuardAppState extends State<TimeGuardApp> {
  final api = ApiService();
  late final auth = AuthService(api);
  late final data = TimeGuardService(api);
  late Future<void> startup;
  final navigatorKey = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
    startup = auth.restore();
    auth.addListener(sessionChanged);
  }

  void sessionChanged() {
    if (auth.employee == null) {
      navigatorKey.currentState?.popUntil((r) => r.isFirst);
    }
  }

  @override
  void dispose() {
    auth.removeListener(sessionChanged);
    auth.dispose();
    api.client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigatorKey,
    title: 'TimeGuard',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('th'),
    supportedLocales: const [Locale('th'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: FutureBuilder<void>(
      future: startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.face_retouching_natural,
                    size: 80,
                    color: AppTheme.primary,
                  ),
                  Text(
                    'TimeGuard',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: ErrorPanel(
                snapshot.error!,
                () {
                  final restoredStartup = auth.restore();
                  setState(() {
                    startup = restoredStartup;
                  });
                },
              ),
            ),
          );
        }
        return ListenableBuilder(
          listenable: auth,
          builder: (context, _) => auth.employee == null
              ? LoginScreen(auth: auth)
              : EmployeeShell(
                  key: ValueKey(auth.employee!.id),
                  auth: auth,
                  data: data,
                ),
        );
      },
    ),
  );
}

class EmployeeShell extends StatefulWidget {
  final AuthService auth;
  final TimeGuardService data;
  const EmployeeShell({super.key, required this.auth, required this.data});
  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int index = 0;
  bool permissionsSeen = false;
  @override
  Widget build(BuildContext context) {
    if (!permissionsSeen) {
      return PermissionScreen(
        onContinue: () => setState(() => permissionsSeen = true),
      );
    }
    final pages = [
      HomeScreen(
        auth: widget.auth,
        data: widget.data,
        onNotifications: () => setState(() => index = 2),
      ),
      HistoryScreen(data: widget.data),
      NotificationsScreen(data: widget.data),
      ProfileScreen(auth: widget.auth, data: widget.data),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'ประวัติ'),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'การแจ้งเตือน',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
