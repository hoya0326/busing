import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  KakaoMapController? mapController;

  final List<CustomOverlay> _customOverlays = [];

  int _currentZoomLevel = 3;
  int _selectedPlaceIndex = 0;

  LatLng? _currentPosition;
  double _currentHeading = 0.0;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;

  // 💡 위젯바의 실시간 높이(비율)를 저장하고 버튼에만 부드럽게 전달하는 변수
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
    _sheetExtent.dispose(); // 메모리 누수 방지
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

    // 💡 [핵심 개선 1] 스마트폰에 저장된 '최근 위치'를 0.1초 만에 불러와서 지도부터 확 켭니다.
    Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition != null) {
      _updateCurrentLocation(lastKnownPosition.latitude, lastKnownPosition.longitude);
    }

    // 💡 [핵심 개선 2] 정확한 GPS를 찾는 작업은 await로 기다리지 않고 백그라운드(.then)로 던집니다.
    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5), // 무한정 기다리지 않도록 5초 타임아웃 설정
    ).then((Position position) {
      // 5초 안에 정확한 위치를 찾으면 스르륵 업데이트 해줍니다.
      _updateCurrentLocation(position.latitude, position.longitude);
    }).catchError((e) {
      debugPrint("정확한 위치 초기화 타임아웃 (스트림이 이어서 처리할 예정입니다)");
    });

    // 💡 [핵심 개선 3] 이후 사용자가 걸어 다닐 때의 실시간 위치 추적
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
            _drawDirectionMarker();
          });
        }
      }
    });
  }

  void _updateCurrentLocation(double lat, double lng, {bool moveCamera = true}) {
    LatLng newLatLng = LatLng(lat, lng);

    setState(() {
      _currentPosition = newLatLng;
      _drawDirectionMarker();
    });

    if (moveCamera && mapController != null) {
      mapController!.setCenter(newLatLng);
    }
  }

  void _drawDirectionMarker() {
    if (_currentPosition == null) return;

    final String markerHtml = '''
      <div style="transform: rotate(${_currentHeading}deg); transform-origin: 50% 50%; width: 80px; height: 80px; display: flex; justify-content: center; align-items: center;">
        <svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
          <path d="M 40 40 L 20 15 A 35 35 0 0 1 60 15 Z" fill="rgba(37, 99, 235, 0.3)" />
          <circle cx="40" cy="40" r="9" fill="#FFFFFF" stroke="#2563EB" stroke-width="3" />
          <circle cx="40" cy="40" r="5" fill="#2563EB" />
        </svg>
      </div>
    ''';

    _customOverlays.clear();
    _customOverlays.add(
        CustomOverlay(
          customOverlayId: '방향_마커',
          latLng: _currentPosition!,
          content: markerHtml,
          xAnchor: 0.5,
          yAnchor: 0.5,
        )
    );
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

  @override
  Widget build(BuildContext context) {
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
                      customOverlays: _customOverlays,
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

                // 💡 수정 포인트: 위젯바 높이에 따라 실시간으로 버튼들의 위치와 투명도를 바꿔줍니다.
                ValueListenableBuilder<double>(
                  valueListenable: _sheetExtent,
                  builder: (context, extent, child) {
                    // 위젯바가 화면의 75% 이상 올라가면 버튼을 서서히 숨깁니다.
                    final bool isVisible = extent < 0.75;
                    // 위젯바의 실시간 픽셀 높이 계산
                    final double bottomPadding = extent * MediaQuery.of(context).size.height;

                    return Positioned(
                      right: 16,
                      bottom: bottomPadding + 20, // 위젯바 바로 위(20px 띄움)에 밀착
                      child: IgnorePointer( // 안 보일 때는 터치도 막아줍니다.
                        ignoring: !isVisible,
                        child: AnimatedOpacity(
                          opacity: isVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250), // 0.25초 동안 스르륵
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

          // 💡 수정 포인트: 위젯바의 스크롤(드래그) 이벤트를 실시간으로 감지합니다.
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
                                  borderRadius: BorderRadius.circular(10)
                              )
                          )
                      ),
                      const Text('자주 가는 목적지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      _buildPlacePresets(),
                      const SizedBox(height: 30),
                      const Text('지금 가장 빠른 노선', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
                      const SizedBox(height: 15),
                      _buildBusCard('수완03', '7분 남음', '🟢 안정', const Color(0xFF10B981)),
                      _buildBusCard('지원151', '4분 남음', '🟡 촉박', const Color(0xFFF59E0B)),
                      _buildBusCard('풍암16', '2분 남음', '🔴 위험', const Color(0xFFDC2626)),
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

  Widget _buildPlacePresets() {
    final labels = ['우리집', '학교', '학원', '헬스장'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(labels[i]),
            selected: _selectedPlaceIndex == i,
            onSelected: (val) => setState(() => _selectedPlaceIndex = i),
            selectedColor: const Color(0xFF2563EB),
            labelStyle: TextStyle(color: _selectedPlaceIndex == i ? Colors.white : Colors.black),
          ),
        )),
      ),
    );
  }

  Widget _buildBusCard(String no, String time, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width: 70, padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(no, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const Text('정류장까지 도보 3분', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))]),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}