import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../models.dart';
import '../widgets/app_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  KakaoMapController? mapController;
  final List<CustomOverlay> _customOverlays = [];

  int _currentZoomLevel = 3;
  int _selectedPlaceIndex = -1;

  LatLng? _currentPosition;
  double _currentHeading = 0.0;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;

  bool _isFirstLocationSync = true; // 💡 수석 개발자: 첫 위치 동기화 여부 플래그

  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.4);

  @override
  void initState() {
    super.initState();
    _initializeLocationAndCompass();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    _sheetExtent.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationAndCompass() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition != null) {
      _updateCurrentLocation(lastKnownPosition.latitude, lastKnownPosition.longitude);
    }

    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    ).then((Position position) {
      _updateCurrentLocation(position.latitude, position.longitude);
    }).catchError((e) {
      debugPrint("정확한 위치 초기화 타임아웃");
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _updateCurrentLocation(position.latitude, position.longitude, moveCamera: false);
    });

    _compassStream = FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading != null) {
        if ((_currentHeading - event.heading!).abs() > 3) {
          setState(() {
            _currentHeading = event.heading!;
          });
        }
      }
    });
  }

  void _updateCurrentLocation(double lat, double lng, {bool moveCamera = true}) {
    LatLng newLatLng = LatLng(lat, lng);

    setState(() {
      _currentPosition = newLatLng;
    });

    // 💡 수석 개발자: AppProvider의 출발지 좌표도 실시간으로 업데이트합니다.
    context.read<AppProvider>().updateDepartLocation(lat, lng);

    if (_isFirstLocationSync && mounted) {
      _isFirstLocationSync = false;
      context.read<AppProvider>().updateDefaultPlacesWithLocation(lat, lng);
    }

    if (moveCamera && mapController != null) {
      mapController!.setCenter(newLatLng);
    }
  }

  // 💡 수석 개발자: 마커를 생성하는 로직을 분리하여 build에서 호출 가능하게 변경
  List<CustomOverlay> _generateOverlays(AppProvider appProvider) {
    List<CustomOverlay> overlays = [];

    // 1. 현재 위치/방향 마커
    if (_currentPosition != null) {
      overlays.add(
        CustomOverlay(
          customOverlayId: '방향_마커',
          latLng: _currentPosition!,
          content: '''
            <div style="transform: rotate(${_currentHeading}deg); transform-origin: 50% 50%; width: 80px; height: 80px; display: flex; justify-content: center; align-items: center;">
              <svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
                <path d="M 40 40 L 20 15 A 35 35 0 0 1 60 15 Z" fill="rgba(37, 99, 235, 0.3)" />
                <circle cx="40" cy="40" r="9" fill="#FFFFFF" stroke="#2563EB" stroke-width="3" />
                <circle cx="40" cy="40" r="5" fill="#2563EB" />
              </svg>
            </div>
          ''',
          xAnchor: 0.5,
          yAnchor: 0.5,
        ),
      );
    }

    // 2. 목적지 마커
    for (var pin in appProvider.pins) {
      if (pin.type == PinType.arrive) {
        overlays.add(
          CustomOverlay(
            customOverlayId: '목적지_마커',
            latLng: LatLng(pin.x, pin.y),
            content: '''
              <div style="display: flex; flex-direction: column; align-items: center;">
                <div style="background: #DC2626; color: white; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: bold; margin-bottom: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.2);">목적지</div>
                <svg width="30" height="30" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M12 21C16 17.5 19 14.4183 19 10C19 6.13401 15.866 3 12 3C8.13401 3 5 6.13401 5 10C5 14.4183 8 17.5 12 21Z" fill="#DC2626" stroke="white" stroke-width="2"/>
                  <circle cx="12" cy="10" r="3" fill="white"/>
                </svg>
              </div>
            ''',
            xAnchor: 0.5,
            yAnchor: 1.0,
          ),
        );
      }
      
      // 3. 💡 수석 개발자 추가: 카카오 스타일 버스 정류장 마커
      if (pin.type == PinType.busStop) {
        overlays.add(
          CustomOverlay(
            customOverlayId: '정류장_마커_${appProvider.pins.indexOf(pin)}',
            latLng: LatLng(pin.x, pin.y),
            content: '''
              <div style="display: flex; flex-direction: column; align-items: center; pointer-events: none;">
                <!-- 카카오 스타일 정류장 라벨 -->
                <div style="background: #2563EB; color: white; padding: 3px 9px; border-radius: 12px; font-size: 11px; font-weight: bold; margin-bottom: 2px; box-shadow: 0 2px 4px rgba(0,0,0,0.2); white-space: nowrap; border: 1px solid rgba(255,255,255,0.3);">
                  정류장
                </div>
                <!-- 2번째 사진과 유사한 카카오 버스 아이콘 -->
                <div style="width: 24px; height: 24px; background: #3B82F6; border-radius: 6px; border: 2px solid white; display: flex; justify-content: center; align-items: center; box-shadow: 0 2px 6px rgba(0,0,0,0.3);">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="white">
                    <path d="M18 11V7c0-2.209-1.791-4-4-4h-4c-2.209 0-4 1.791-4 4v4H5v7c0 1.105.895 2 2 2v1c0 .552.448 1 1 1h1c.552 0 1-.448 1-1v-1h4v1c0 .552.448 1 1 1h1c.552 0 1-.448 1-1v-1c1.105 0 2-.895 2-2v-7h-1zM8 7c0-1.105.895-2 2-2h4c1.105 0 2 .895 2 2v4H8V7zm2 11c-.552 0-1-.448-1-1s.448-1 1-1 1 .448 1 1-.448 1-1 1zm4 0c-.552 0-1-.448-1-1s.448-1 1-1 1 .448 1 1-.448 1-1 1z"/>
                  </svg>
                </div>
              </div>
            ''',
            xAnchor: 0.5,
            yAnchor: 0.88, // 아이콘의 버스 부분이 좌표 정중앙에 오도록 보정
          ),
        );
      }
    }
    return overlays;
  }

  void _moveToMyLocation() async {
    if (_currentPosition != null && mapController != null) {
      mapController!.setCenter(_currentPosition!);
    }
  }

  void _onMapCreated(KakaoMapController controller) {
    mapController = controller;
    mapController?.setZoomable(true);
    if (_currentPosition != null) {
      mapController?.setCenter(_currentPosition!);
    }
  }

  void _zoomIn() {
    if (_currentZoomLevel > 1) {
      setState(() {
        _currentZoomLevel--;
        mapController?.setLevel(_currentZoomLevel);
      });
    }
  }

  void _zoomOut() {
    if (_currentZoomLevel < 14) {
      setState(() {
        _currentZoomLevel++;
        mapController?.setLevel(_currentZoomLevel);
      });
    }
  }

  // 💡 수석 개발자 추가: 두 지점이 한눈에 보이도록 지도 시야 자동 조정
  void _fitRouteBounds(LatLng p1, LatLng p2) {
    if (mapController == null) return;

    // 1. 중심점 계산
    final centerLat = (p1.latitude + p2.latitude) / 2;
    final centerLng = (p1.longitude + p2.longitude) / 2;

    // 2. 거리 기반 최적 줌 레벨 계산 (카카오 맵 기준 1~14)
    final latDiff = (p1.latitude - p2.latitude).abs();
    final lngDiff = (p1.longitude - p2.longitude).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    int optimalLevel = 3;
    if (maxDiff > 0.1) optimalLevel = 8;
    else if (maxDiff > 0.05) optimalLevel = 7;
    else if (maxDiff > 0.02) optimalLevel = 6;
    else if (maxDiff > 0.01) optimalLevel = 5;
    else if (maxDiff > 0.005) optimalLevel = 4;
    else optimalLevel = 3;

    setState(() {
      _currentZoomLevel = optimalLevel;
    });

    // 💡 부드러운 카메라 이동
    mapController!.setCenter(LatLng(centerLat, centerLng));
    mapController!.setLevel(optimalLevel);
    
    print('🎬 [Map] 경로에 맞춰 시야를 조정했습니다. (줌 레벨: $optimalLevel)');
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    // 💡 [수정] AppProvider의 트리거를 감시하여 안전하게 줌 조절
    if (appProvider.shouldFitBounds && _currentPosition != null) {
      final arrivePin = appProvider.pins.firstWhere(
        (p) => p.type == PinType.arrive, 
        orElse: () => MapPin(x: 0, y: 0, type: PinType.arrive)
      );
      if (arrivePin.x != 0) {
        Future.microtask(() {
          _fitRouteBounds(_currentPosition!, LatLng(arrivePin.x, arrivePin.y));
          context.read<AppProvider>().resetFitBounds(); // 트리거 초기화
        });
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                if (_currentPosition == null)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else
                  SizedBox.expand(
                    child: KakaoMap(
                      onMapCreated: _onMapCreated,
                      center: _currentPosition!,
                      customOverlays: _generateOverlays(appProvider),
                      polylines: appProvider.routeSegments.map((segment) => Polyline(
                        polylineId: 'route_${appProvider.routeSegments.indexOf(segment)}',
                        points: segment.points,
                        strokeColor: segment.color,
                        strokeWidth: segment.width.toInt(),
                      )).toList(),
                      currentLevel: _currentZoomLevel,
                      onZoomChangeCallback: (int level, ZoomType type) {
                        setState(() {
                          _currentZoomLevel = level;
                        });
                      },
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                    ),
                  ),
                ValueListenableBuilder<double>(
                  valueListenable: _sheetExtent,
                  builder: (context, extent, child) {
                    final bool isVisible = extent < 0.75;
                    final double bottomPadding = extent * MediaQuery.of(context).size.height;

                    return Positioned(
                      right: 16,
                      bottom: bottomPadding + 20,
                      child: IgnorePointer(
                        ignoring: !isVisible,
                        child: AnimatedOpacity(
                          opacity: isVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      _buildFloatingButton(Icons.my_location, _moveToMyLocation),
                      const SizedBox(height: 16),
                      _buildFloatingButton(Icons.add, _zoomIn),
                      const SizedBox(height: 8),
                      _buildFloatingButton(Icons.remove, _zoomOut),
                    ],
                  ),
                ),
              ],
            ),
          ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _sheetExtent.value = notification.extent;
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.14,
              maxChildSize: 0.95,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 25),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const Text('자주 가는 목적지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      _buildPlacePresets(appProvider),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Text('지금 가장 빠른 노선', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
                          if (appProvider.isAnalyzing) ...[
                            const SizedBox(width: 8),
                            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 15),
                      if (appProvider.isServiceEnded)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Icon(Icons.nightlight_round, size: 48, color: Colors.blue[200]),
                              const SizedBox(height: 16),
                              const Text(
                                '현재 버스가 운행을 종료했습니다',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                              ),
                              const SizedBox(height: 8),
                              const Text('내일 새벽 5시부터 다시 운행합니다.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      else if (appProvider.recommendedRoutes.isEmpty && !appProvider.isAnalyzing)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('목적지를 선택하면 최적의 경로를 분석합니다.', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ...appProvider.recommendedRoutes.map((route) => _buildBusRouteCard(route)),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 24, color: const Color(0xFF111827)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildPlacePresets(AppProvider appProvider) {
    final places = appProvider.favoritePlaces;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(places.length, (i) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(places[i].name),
            selected: _selectedPlaceIndex == i,
            onSelected: (val) {
              setState(() => _selectedPlaceIndex = i);
              appProvider.setArriveLabel(places[i].name);
              
              // 💡 수석 개발자의 팁: 목적지 선택 시 지도를 해당 위치로 이동시킵니다.
              if (mapController != null) {
                mapController!.setCenter(LatLng(places[i].lat, places[i].lng));
              }
            },
            selectedColor: const Color(0xFF2563EB),
            labelStyle: TextStyle(color: _selectedPlaceIndex == i ? Colors.white : Colors.black),
          ),
        )),
      ),
    );
  }

  Widget _buildBusRouteCard(BusRouteInfo route) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: const Color(0xFFE5E7EB),
      onTap: () {
        // 경로 상세 보기 등 액션 추가 가능
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    route.busName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${route.busArrivalRemaining}분 남음',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    route.routeDescription,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: route.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              route.statusText,
              style: TextStyle(color: route.statusColor, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
