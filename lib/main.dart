import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_provider.dart';
import 'storage_service.dart';
import 'widgets/root_layout.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. .env 파일 로드
    await dotenv.load(fileName: ".env");

    // 2. 환경 변수에서 키를 가져오고 .trim()으로 보이지 않는 공백/줄바꿈 제거
    String kakaoKey = (dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '').trim();

    // 디버깅용: 콘솔에 키가 정상적으로 찍히는지 확인
    debugPrint('🔑 [Debug] 불러온 카카오 키 확인: ${kakaoKey.isNotEmpty ? "성공 (글자수: ${kakaoKey.length})" : "실패(비어있음)"}');

    // 3. 카카오 지도 초기화
    AuthRepository.initialize(appKey: kakaoKey);
  } catch (e) {
    debugPrint('❌ [Error] .env 파일을 읽어오지 못했거나 초기화 중 에러 발생: $e');
  }

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