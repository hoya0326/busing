import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'app_provider.dart';
import 'storage_service.dart';
import 'widgets/root_layout.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 중요 ──
  // 지도가 안 뜰 경우 아래 앱키를 카카오 콘솔의 'JavaScript 키'로 교체해 보세요.
  // 에뮬레이터 환경은 웹뷰를 사용하므로 자바스크립트 키가 필요할 수 있습니다.
  AuthRepository.initialize(appKey: '***REMOVED***');
  
  final storageService = StorageService();
  await storageService.init();
  
  final appProvider = AppProvider(storageService);
  await appProvider.loadRoutines();
  await appProvider.loadProfile();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: storageService),
        ChangeNotifierProvider.value(value: appProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Routine Bus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => RootLayout(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/schedule', builder: (context, state) => const ScheduleScreen()),
        GoRoute(path: '/notification', builder: (context, state) => const NotificationScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),
  ],
);
