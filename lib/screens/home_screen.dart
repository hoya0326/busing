import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:permission_handler/permission_handler.dart';

// 버씽 앱의 중심이 되는 홈 화면입니다. 상단 지도와 하단 경로 정보를 결합한 구조입니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 카카오 지도를 제어하기 위한 컨트롤러입니다.
  late KakaoMapController mapController;
  
  // 지도에 표시될 마커와 경로선 목록입니다.
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];

  // 현재 지도의 확대 수준을 관리합니다. (숫자가 작을수록 더 많이 확대됨)
  int _currentZoomLevel = 3;
  int _selectedPlaceIndex = 0;

  // ── 지리적 위치 데이터 ──
  final LatLng _centerPoint = LatLng(35.1432, 126.9321); // 조선대
  final LatLng _startPosition = LatLng(35.1450, 126.9300); // 사용자 위치 가상
  final LatLng _targetBusStop = LatLng(35.1410, 126.9350); // 정류장 가상

  @override
  void initState() {
    super.initState();
    _initializePermissions();
    // 지도가 안 뜰 경우 터미널에서 키 해시를 수동으로 확인해야 합니다.
  }

  Future<void> _initializePermissions() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      debugPrint("위치 권한 승인됨");
    }
  }

  void _onMapCreated(KakaoMapController controller) {
    mapController = controller;

    // 지도의 확대/축소 기능을 프로그래밍적으로 활성화합니다.
    mapController.setZoomable(true);
    // 마우스 휠을 이용한 줌 기능을 명시적으로 활성화합니다. (일부 버전 대응)
    // mapController.setZoomable(true) 내부에 포함되어 있을 수 있으나 재확인 차원에서 강조합니다.

    setState(() {
      _markers.add(Marker(
        markerId: '시작_마커',
        latLng: _startPosition,
      ));
      
      _markers.add(Marker(
        markerId: '정류장_마커',
        latLng: _targetBusStop,
      ));

      _polylines.add(Polyline(
        polylineId: '도보_경로',
        points: [_startPosition, _targetBusStop],
        strokeColor: Colors.blue,
        strokeWidth: 5,
      ));
    });
  }

  // 지도를 한 단계 확대하는 기능입니다.
  void _zoomIn() {
    if (_currentZoomLevel > 1) {
      setState(() {
        _currentZoomLevel--;
        mapController.setLevel(_currentZoomLevel);
      });
    }
  }

  // 지도를 한 단계 축소하는 기능입니다.
  void _zoomOut() {
    if (_currentZoomLevel < 14) {
      setState(() {
        _currentZoomLevel++;
        mapController.setLevel(_currentZoomLevel);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Stack(
        children: [
          // ── 상단 60%: 카카오 지도 영역 ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Stack(
              children: [
                KakaoMap(
                  onMapCreated: _onMapCreated,
                  center: _centerPoint,
                  markers: _markers,
                  polylines: _polylines,
                  currentLevel: _currentZoomLevel,
                  // 사용자의 수동 확대/축소 시 현재 레벨 상태를 동기화합니다.
                  onZoomChangeCallback: (int level, ZoomType type) {
                    setState(() {
                      _currentZoomLevel = level;
                    });
                  },
                  // 플러터 위젯 계층이 지도의 터치 이벤트를 가로채지 않도록 적극적으로 인식기를 설정합니다.
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                  },
                ),
                
                // ── 지도 위 확대/축소 조작 버튼 ──
                Positioned(
                  right: 16,
                  bottom: 110,
                  child: Column(
                    children: [
                      _buildZoomButton(Icons.add, _zoomIn),
                      const SizedBox(height: 8),
                      _buildZoomButton(Icons.remove, _zoomOut),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 하단 바텀 시트 ──
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.4,
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
                    Center(child: Container(width: 45, height: 6, margin: const EdgeInsets.only(bottom: 25), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
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
        ],
      ),
    );
  }

  // 확대/축소 버튼 위젯을 만드는 헬퍼 함수입니다.
  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
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
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(30)), child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
