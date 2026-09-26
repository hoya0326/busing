import 'dart:async'; // 💡 unawaited 사용을 위해 추가
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
import 'services/notification_service.dart'; // 💡 추가

void main() async {
  debugPrint('🚀 [System] 앱 시작 프로세스 가동');
  WidgetsFlutterBinding.ensureInitialized();
  
  // 알림 서비스 초기화
  await NotificationService().init();

  try {
    // 1. .env 파일 로드
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}

    // 2. 환경 변수에서 키를 가져오고 Fallback 기본값 제공
    String kakaoKey = (dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? 'e3f075dc45e22ade7b22b71efdc4964a').trim();
    if (kakaoKey.isEmpty) {
      kakaoKey = 'e3f075dc45e22ade7b22b71efdc4964a';
    }

    debugPrint('🔑 [Debug] 카카오 키 초기화 완료');

    // 3. 카카오 지도 초기화
    AuthRepository.initialize(appKey: kakaoKey);
  } catch (e) {
    debugPrint('❌ [Error] 카카오 지도 초기화 중 에러 발생: $e');
    AuthRepository.initialize(appKey: 'e3f075dc45e22ade7b22b71efdc4964a');
  }

  final storageService = StorageService();
  await storageService.init();

  final appProvider = AppProvider(storageService);
  
  // 💡 [수석 개발자] 앱 부팅 속도 개선: 데이터 로딩을 비동기로 전환하여 첫 화면 진입 차단 방지
  unawaited(appProvider.loadRoutines());
  unawaited(appProvider.loadProfile());
  unawaited(appProvider.loadFavoritePlaces());

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
    final appProvider = context.watch<AppProvider>();
    
    return MaterialApp.router(
      title: 'Routine Bus',
      debugShowCheckedModeBanner: false,
      themeMode: appProvider.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFFDFBF7), // 💡 좀 더 편안한 아이보리 배경
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF0F1117),
      ),
      builder: (context, child) {
        // 💡 [Figma] 전역 폰트 크기 변환 규칙 적용
        final mediaQueryData = MediaQuery.of(context);
        final scaleFactor = mediaQueryData.textScaler.scale(1.0);
        
        // fontScaleDelta가 -5, 0, 5 일 때 적절한 배율로 환산 (약 0.8, 1.0, 1.2)
        double customScale = 1.0 + (appProvider.state.fontScaleDelta / 25.0);

        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(scaleFactor * customScale),
          ),
          child: child!,
        );
      },
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
        GoRoute(path: '/profile', builder: (context, state) => const SettingsScreen()),
      ],
    ),
  ],
);