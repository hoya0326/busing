import 'dart:async';
import 'dart:math' as Math; // 💡 추가
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../models.dart';
import '../data/bus_schedules.dart'; // 💡 추가
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart'; // 💡 추가

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  KakaoMapController? mapController;

  int _currentZoomLevel = 3;
  int _selectedPlaceIndex = -1;

  LatLng? _currentPosition;
  double _currentHeading = 0.0;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;

  bool _isFirstLocationSync = true;
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.4);
  
  // 💡 [수석 개발자] 시트 내 내용물 스크롤을 위한 독립적인 컨트롤러 추가
  final ScrollController _internalSheetScrollController = ScrollController();

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
    _internalSheetScrollController.dispose(); // 💡 해제 추가
    super.dispose();
  }

  Future<void> _initializeLocationAndCompass() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
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

    context.read<AppProvider>().updateDepartLocation(lat, lng);

    if (_isFirstLocationSync && mounted) {
      _isFirstLocationSync = false;
      context.read<AppProvider>().updateDefaultPlacesWithLocation(lat, lng);
    }

    // 💡 지도 자동 이동 제거
  }

  List<CustomOverlay> _generateOverlays(AppProvider appProvider) {
    List<CustomOverlay> overlays = [];

    // 1. 현재 위치/방향 마커 (항상 표시)
    if (_currentPosition != null) {
      overlays.add(CustomOverlay(
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
        xAnchor: 0.5, yAnchor: 0.5,
      ));
    }

    // 2. 목적지 및 출발지 마커 (항상 표시)
    for (var pin in appProvider.pins) {
      if (pin.type == PinType.arrive) {
        overlays.add(CustomOverlay(
          customOverlayId: 'arrive_${pin.x}_${pin.y}',
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
          xAnchor: 0.5, yAnchor: 1.0,
        ));
      }
      
      if (pin.type == PinType.depart && appProvider.departLabel != '현재 위치') {
        overlays.add(CustomOverlay(
          customOverlayId: 'depart_${pin.x}_${pin.y}',
          latLng: LatLng(pin.x, pin.y),
          content: '''
            <div style="display: flex; flex-direction: column; align-items: center;">
              <div style="background: #2563EB; color: white; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: bold; margin-bottom: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.2);">출발</div>
              <svg width="30" height="30" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 21C16 17.5 19 14.4183 19 10C19 6.13401 15.866 3 12 3C8.13401 3 5 6.13401 5 10C5 14.4183 8 17.5 12 21Z" fill="#2563EB" stroke="white" stroke-width="2"/>
                <circle cx="12" cy="10" r="3" fill="white"/>
              </svg>
            </div>
          ''',
          xAnchor: 0.5, yAnchor: 1.0,
        ));
      }
    }

    // 4. 주요 정류장 (승차/하차/환승 - 항상 표시)
    final busStops = appProvider.pins.where((p) => p.type == PinType.busStop).toList();
    for (var pin in busStops) {
      final type = pin.address; 
      String actionLabel = '정류장';
      Color color = const Color(0xFF4B5563);
      if (type == 'boarding') { actionLabel = '승차'; color = const Color(0xFF10B981); }
      else if (type == 'alighting') { actionLabel = '하차'; color = const Color(0xFF2563EB); }
      else if (type == 'transfer') { actionLabel = '환승'; color = const Color(0xFFF59E0B); }
      
      // 💡 [Request] 액션 라벨(승차/하차)과 정류장 이름을 함께 표시
      overlays.add(_buildStopOverlay(
        pin, 
        actionLabel, 
        color, 
        showLabel: true,
        subLabel: pin.label, // 💡 정류장 이름 전달
      ));
    }

    // 5. 일반 경유 정류장 (줌 레벨에 따라 표시)
    // 💡 [Request] 지도 5레벨 이하(더 확대된 상태)에서만 경유 정류장 이름이 보이도록 조정
    if (_currentZoomLevel <= 5) { 
      final passStops = appProvider.pins.where((p) => p.type == PinType.passStop).toList();
      for (var pin in passStops) {
        overlays.add(_buildStopOverlay(
          pin, 
          pin.label ?? '정류장', 
          const Color(0xFF6B7280), 
          showLabel: true,
          mini: false, 
        ));
      }
    }

    return overlays;
  }

  CustomOverlay _buildStopOverlay(MapPin pin, String label, Color color, {bool showLabel = true, bool mini = false, String? subLabel}) {
    return CustomOverlay(
      customOverlayId: 'stop_${pin.x}_${pin.y}_${label}_${subLabel ?? ""}',
      latLng: LatLng(pin.x, pin.y),
      content: '''
        <div style="display: flex; flex-direction: column; align-items: center; cursor: pointer;">
          ${showLabel ? '''
            <div style="display: flex; flex-direction: column; align-items: center;">
              ${subLabel != null ? '''
                <div style="background: white; color: ${colorToHex(color)}; 
                  padding: 2px 6px; border-radius: 4px; font-size: 10px; 
                  font-weight: bold; margin-bottom: 2px; box-shadow: 0 1px 3px rgba(0,0,0,0.2);
                  border: 1px solid ${colorToHex(color)}; white-space: nowrap;">
                  $subLabel
                </div>''' : ''}
              <div style="background: ${colorToHex(color)}; color: white; 
                padding: ${mini ? '2px 6px' : '3px 9px'}; 
                border-radius: 12px; 
                font-size: ${mini ? '9px' : '11px'}; 
                font-weight: bold; margin-bottom: 2px; 
                box-shadow: 0 2px 4px rgba(0,0,0,0.2); white-space: nowrap; 
                border: 1px solid rgba(255,255,255,0.3);
                opacity: ${mini ? '0.8' : '1.0'};">
                $label
              </div>
            </div>''' : ''}
          <div style="width: ${mini ? '8px' : '14px'}; height: ${mini ? '8px' : '14px'}; 
            background: white; border-radius: 50%; 
            border: ${mini ? '2px' : '3px'} solid ${colorToHex(color)}; 
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);"></div>
        </div>
      ''',
      xAnchor: 0.5, yAnchor: 0.8,
    );
  }

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  void _onMapCreated(KakaoMapController controller) {
    mapController = controller;
    mapController?.setZoomable(true);
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

  void _moveToMyLocation() async {
    // 💡 지도 이동 제거
  }

  void _fitRouteBounds(LatLng p1, LatLng p2) {
    // 💡 지도 이동 제거
  }

  Widget _buildServiceEndedWidget(String? customMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.blue[200]),
          const SizedBox(height: 16),
          Text(
            customMessage ?? '현재 버스 운행 정보가 없습니다',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text('내일 새벽 5시부터 다시 운행합니다.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildArrivalListTile(BusRouteInfo bus) {
    final appProvider = context.read<AppProvider>();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(8)),
        child: Text(bus.busName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(
        bus.busArrivalRemaining == -2 ? '운행 종료' : 
        (bus.busArrivalRemaining == -1 ? '실시간 정보 없음' : '${bus.busArrivalRemaining}분 뒤 도착'), 
        style: const TextStyle(fontWeight: FontWeight.bold)
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 💡 [Request] "시간표" -> "정보" 버튼으로 변경 및 하단 시트 전환
          TextButton(
            onPressed: () {
              appProvider.openBusLineInfo(bus.busName);
            },
            child: const Text('정보', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
          ),
          Text(bus.statusText, style: TextStyle(color: bus.statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  /// 💡 [New Request] 버스 정류장 목록 뷰 (2번 사진)
  Widget _buildBusStopListView(AppProvider appProvider) {
    final stations = appProvider.state.activeLineStations;
    final busName = appProvider.state.activeBusName ?? '';
    final details = appProvider.state.activeBusDetails;
    final direction = appProvider.state.activeDirection;
    final dirTitle = direction == 'UP' 
        ? (details?['DIR_UP_NAME'] ?? '상행') 
        : (details?['DIR_DOWN_NAME'] ?? '하행');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 헤더 (이미지 재현)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4)),
              child: const Text('간선', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Text(busName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 24, color: Colors.black54),
              onPressed: () => appProvider.setBarMode(WidgetBarMode.main),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // 방향 전환 버튼 및 현재 방향 표시
        GestureDetector(
          onTap: () => appProvider.switchBusDirection(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$dirTitle 방면', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                const SizedBox(width: 6),
                const Icon(Icons.swap_vert, size: 16, color: Color(0xFF6B7280)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        
        if (stations.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else
          ...List.generate(stations.length, (index) {
            final s = stations[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타임라인 선 (이미지 스타일 재현)
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      Container(width: 4, height: 20, color: index == 0 ? Colors.transparent : const Color(0xFFFBBF24)),
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFBBF24), width: 3),
                        ),
                      ),
                      Container(width: 4, height: 20, color: index == stations.length - 1 ? Colors.transparent : const Color(0xFFFBBF24)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      Text(s.stationName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      const SizedBox(height: 2),
                      Text('${s.firstBusTime} - ${s.lastBusTime}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 14),
                      if (index != stations.length - 1) const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ],
                  ),
                ),
              ],
            );
          }),
          
        const SizedBox(height: 30),
        // 하단 고정 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModeActionBtn(Icons.access_time, '시간표', () => appProvider.setBarMode(WidgetBarMode.lineSchedule)),
            _buildModeActionBtn(Icons.info_outline, '노선정보', () => appProvider.setBarMode(WidgetBarMode.lineDetails)),
          ],
        ),
      ],
    );
  }

  /// 💡 [New Request] 두 종점 방향 통합 시간표 뷰 (3번 사진 스타일)
  Widget _buildDualScheduleView(AppProvider appProvider) {
    final busName = appProvider.state.activeBusName ?? '';
    final schedules = appProvider.getBusSchedules(busName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => appProvider.setBarMode(WidgetBarMode.lineInfo),
            ),
            Text('$busName 배차시간표', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [Tab(text: '평일'), Tab(text: '주말')],
                labelColor: Color(0xFF2563EB),
                indicatorColor: Color(0xFF2563EB),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    _buildDirectionalScheduleGrid(schedules, 'weekday'),
                    _buildDirectionalScheduleGrid(schedules, 'weekend'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionalScheduleGrid(List<BusSchedule> schedules, String type) {
    if (schedules.isEmpty) return const Center(child: Text('데이터가 없습니다.'));
    
    return Column(
      children: [
        // 종점 헤더
        Row(
          children: schedules.map((s) => Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(color: Color(0xFF00C7FF)), // 이미지의 하늘색
              child: Text(s.startStation, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
            ),
          )).toList(),
        ),
        Expanded(
          child: Row(
            children: schedules.map((s) {
              final times = type == 'weekday' ? s.weekday : s.saturday;
              return Expanded(
                child: ListView.builder(
                  itemCount: times.length,
                  itemBuilder: (context, i) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                    child: Text(times[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 💡 [New Request] 노선 상세 정보 뷰 (4번 사진 스타일)
  Widget _buildLineDetailInfoView(AppProvider appProvider) {
    final details = appProvider.state.activeBusDetails;
    final busName = appProvider.state.activeBusName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => appProvider.setBarMode(WidgetBarMode.lineInfo),
            ),
            const Text('노선정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),
        
        // 초정밀 안내 박스
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('초정밀 버스 위치정보 제공 노선', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 6),
              Text('10cm 단위의 버스 위치정보를 1초 간격으로 갱신하는 리얼타임 서비스입니다.', 
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.5)),
            ],
          ),
        ),
        
        const SizedBox(height: 10),
        _buildInfoRow('운행지역', '${details?['DIR_UP_NAME'] ?? "광주"} ↔ ${details?['DIR_DOWN_NAME'] ?? "광주"}\n전남광주'),
        _buildInfoRow('운행시간', '기점 ${details?['FIRST_RUN'] ?? "05:40"} ~ ${details?['LAST_RUN'] ?? "22:30"}'),
        _buildInfoRow('배차간격', '${details?['INTERVAL'] ?? "13"}분'),
        _buildInfoRow('주요경유지', '${details?['DIR_UP_NAME']} - ... - ${details?['DIR_DOWN_NAME']}'),
        
        const SizedBox(height: 40),
        const Center(child: Text('정보 수정 제안 >', style: TextStyle(color: Colors.grey, fontSize: 13))),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildModeActionBtn(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFFEFF6FF),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBusRouteCard(BusRouteInfo route, int index, bool isSelected, AppProvider appProvider) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      borderColor: isSelected ? route.statusColor : const Color(0xFFE5E7EB),
      backgroundColor: isSelected ? route.statusColor.withOpacity(0.05) : Colors.white,
      onTap: () {
        appProvider.selectRoute(index);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                route.busName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: route.statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  route.statusText,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => appProvider.registerDepartureAlarm(context, route),
                icon: Icon(Icons.notifications_active_outlined, color: route.statusColor),
                tooltip: '알림 예약',
              ),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: route.statusColor),
                  const SizedBox(width: 4),
                  Text(
                    '${route.totalDuration}분',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: route.statusColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                route.busArrivalRemaining == -2
                    ? '운행 종료'
                    : (route.busArrivalRemaining == -1 ? '실시간 정보 없음' : '${route.busArrivalRemaining}분 남음'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: route.statusColor),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () {
                  // 💡 [Request] "시간표 보기" -> "정보" 버튼으로 변경 및 하단 시트 전환
                  appProvider.openBusLineInfo(route.busName);
                },
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('정보', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '정류장까지 도보 ${route.walkTimeRemaining}분',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
          ),
          if (route.routeDescription.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                route.routeDescription,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4, fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchHeader(AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openSearchLayer(context, appProvider, isDepart: true),
              child: _buildSearchField(appProvider.departLabel, Colors.green),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, color: Colors.white70, size: 16)),
          Expanded(
            child: GestureDetector(
              onTap: () => _openSearchLayer(context, appProvider, isDepart: false),
              child: _buildSearchField(appProvider.arriveLabel.isEmpty ? '도착지' : appProvider.arriveLabel, Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(String text, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _openSearchLayer(BuildContext context, AppProvider appProvider, {required bool isDepart}) {
    appProvider.searchPlaces(''); // 💡 검색창 열 때 이전 검색 결과 초기화
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(0))),
      builder: (context) => _SearchLayer(isDepart: isDepart),
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
              // 💡 지도 자동 이동 제거
            },
            selectedColor: const Color(0xFF2563EB),
            labelStyle: TextStyle(color: _selectedPlaceIndex == i ? Colors.white : Colors.black),
          ),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    if (appProvider.shouldFitBounds) {
      final departPin = appProvider.pins.firstWhere((p) => p.type == PinType.depart, orElse: () => MapPin(x: 0, y: 0, type: PinType.depart));
      final arrivePin = appProvider.pins.firstWhere((p) => p.type == PinType.arrive, orElse: () => MapPin(x: 0, y: 0, type: PinType.arrive));
      
      if (departPin.x != 0 && arrivePin.x != 0) {
        Future.microtask(() {
          _fitRouteBounds(LatLng(departPin.x, departPin.y), LatLng(arrivePin.x, arrivePin.y));
          context.read<AppProvider>().resetFitBounds();
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
                  const Center(child: CircularProgressIndicator(color: Colors.white))
                else
                  SizedBox.expand(
                    child: KakaoMap(
                      // 💡 [수석 개발자] 경로선 실종 방지용 강력한 리빌드 키
                      // 세션 번호와 경로 세그먼트 개수를 조합하여 데이터 변경 시 지도를 강제로 다시 그리게 함
                      key: ValueKey('map_v2_${appProvider.analysisCount}_${appProvider.state.routeSegments.length}'),
                      onMapCreated: _onMapCreated,
                      center: _currentPosition!,
                      customOverlays: _generateOverlays(appProvider),
                      markers: const [], // 💡 중복 표시되는 기본 마커 제거 (CustomOverlay로 대체됨)
                      onMarkerTap: (markerId, latLng, zoomLevel) async {
                        debugPrint('📌 [Map] 마커 클릭됨: $markerId at $latLng');
                        await context.read<AppProvider>().fetchStopArrivalInfo(latLng.latitude, latLng.longitude);
                      },
                      onCustomOverlayTap: (overlayId, latLng) async {
                        debugPrint('📌 [Map] 오버레이 클릭됨: $overlayId at $latLng');
                        // 💡 정류장 오버레이(stop_...) 클릭 시에만 정보 조회
                        if (overlayId.startsWith('stop_')) {
                          await context.read<AppProvider>().fetchStopArrivalInfo(latLng.latitude, latLng.longitude);
                        }
                      },
                      polylines: appProvider.routeSegments.map((segment) => Polyline(
                        polylineId: segment.id,
                        points: segment.points,
                        strokeColor: segment.color,
                        strokeWidth: segment.width.toInt(),
                        strokeStyle: segment.strokeStyle, // 💡 점선/실선 적용
                      )).toList(),
                      currentLevel: _currentZoomLevel,
                      onZoomChangeCallback: (int level, ZoomType type) {
                        setState(() { _currentZoomLevel = level; });
                      },
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                    ),
                  ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _buildSearchHeader(appProvider),
                      if (appProvider.isNearDestination) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.notification_important, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '곧 목적지입니다! 하차를 준비하세요.',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
                  child: Column(
                    children: [
                      // 💡 [빨간색 동그라미] 위젯 크기 조절 전용 핸들 영역
                      // SingleChildScrollView와 제공된 scrollController를 사용하여 '드래그 핸들' 기능 구현
                      SingleChildScrollView(
                        controller: scrollController,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          color: Colors.transparent, // 터치 영역 확보
                          child: Center(
                            child: Container(
                              width: 45, 
                              height: 6, 
                              decoration: BoxDecoration(
                                color: Colors.grey[300], 
                                borderRadius: BorderRadius.circular(10)
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // 💡 [파란색 동그라미] 내용물 스크롤 전용 영역
                      // 독립된 _internalSheetScrollController를 사용하여 시트 이동 없이 내부만 움직이게 함
                      Expanded(
                        child: ListView(
                          controller: _internalSheetScrollController,
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
                          children: [
                            if (appProvider.state.barMode == WidgetBarMode.lineInfo) ...[
                              _buildBusStopListView(appProvider),
                            ] else if (appProvider.state.barMode == WidgetBarMode.lineSchedule) ...[
                              _buildDualScheduleView(appProvider),
                            ] else if (appProvider.state.barMode == WidgetBarMode.lineDetails) ...[
                              _buildLineDetailInfoView(appProvider),
                            ] else if (appProvider.barMode == WidgetBarMode.main) ...[
                              const Text('자주 가는 목적지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 15),
                              _buildPlacePresets(appProvider),
                              const SizedBox(height: 30),
                              Row(
                                children: [
                                  const Text('지금 가장 빠른 노선', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
                                  const SizedBox(width: 8),
                                  if (appProvider.isAnalyzing)
                                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF2563EB)),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => appProvider.refreshCurrentView(),
                                    ),
                                  const Spacer(),
                                  if (appProvider.recommendedRoutes.isNotEmpty || appProvider.isAnalyzing)
                                    TextButton.icon(
                                      onPressed: () => appProvider.clearCurrentRoute(),
                                      icon: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                                      label: const Text('경로 취소', style: TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.bold)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              if (appProvider.errorMessage != null)
                                AppEmptyState(
                                  icon: Icons.error_outline,
                                  title: '경로를 찾을 수 없습니다.',
                                  message: appProvider.errorMessage,
                                  actionTitle: '다시 시도',
                                  onAction: () => appProvider.setArriveLabel(appProvider.arriveLabel),
                                )
                              else if (appProvider.recommendedRoutes.isEmpty && !appProvider.isAnalyzing)
                                const AppEmptyState(
                                  icon: Icons.search,
                                  title: '어디로 가시나요?',
                                  message: '목적지를 선택하면 최적의 경로를 분석합니다.',
                                )
                              else
                                ...List.generate(appProvider.recommendedRoutes.length, (index) {
                                  final route = appProvider.recommendedRoutes[index];
                                  return _buildBusRouteCard(route, index, appProvider.selectedRouteIndex == index, appProvider);
                                }),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                                    onPressed: () => appProvider.setBarMode(WidgetBarMode.main),
                                  ),
                                  Expanded(
                                    child: Text(
                                      appProvider.selectedStopName ?? '정류장 정보',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!appProvider.isLoadingArrivals)
                                    IconButton(
                                      icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF2563EB)),
                                      onPressed: () => appProvider.refreshCurrentView(),
                                    ),
                                ],
                              ),
                              const Divider(height: 30),
                              if (appProvider.isLoadingArrivals)
                                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                              else if (appProvider.stopArrivals.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(child: Text('도착 예정 정보가 없습니다.', style: TextStyle(color: Colors.grey))),
                                )
                              else
                                ...appProvider.stopArrivals.map((bus) => _buildArrivalListTile(bus)),
                            ],
                          ],
                        ),
                      ),
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
      width: 40, height: 40,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: IconButton(padding: EdgeInsets.zero, icon: Icon(icon, size: 24, color: const Color(0xFF111827)), onPressed: onPressed),
    );
  }
}

class _SearchLayer extends StatefulWidget {
  final bool isDepart;
  const _SearchLayer({required this.isDepart});

  @override
  State<_SearchLayer> createState() => _SearchLayerState();
}

class _SearchLayerState extends State<_SearchLayer> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
              Text(widget.isDepart ? '출발지 설정' : '도착지 설정', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search, // 💡 키보드 엔터키를 검색 아이콘으로 변경
            decoration: InputDecoration(
              hintText: widget.isDepart ? '출발지 입력...' : '도착지 입력...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.circle, color: widget.isDepart ? Colors.blue : Colors.grey, size: 12),
              // 💡 검색 버튼 추가
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.white70),
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    appProvider.searchPlaces(_controller.text.trim());
                    FocusScope.of(context).unfocus(); // 검색 시 키보드 닫기
                  }
                },
              ),
              filled: true,
              fillColor: const Color(0xFF1F2937),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSubmitted: (val) {
              // 💡 엔터키(검색 버튼)를 눌렀을 때 실행
              if (val.trim().isNotEmpty) {
                appProvider.searchPlaces(val.trim());
                FocusScope.of(context).unfocus(); // 검색 후 키보드 닫기
              }
            },
            onChanged: (val) {
              if (val.isEmpty) appProvider.searchPlaces(''); 
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFF374151)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.location_on_outlined, color: Colors.blue, size: 18),
              label: const Text('지도에서 직접 선택하기', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 30),
          const Text('즐겨찾는 장소', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 10),
          Expanded(
            child: appProvider.isSearching 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: appProvider.searchResults.isNotEmpty ? appProvider.searchResults.length : appProvider.favoritePlaces.length,
                  itemBuilder: (context, index) {
                    if (appProvider.searchResults.isNotEmpty) {
                      final res = appProvider.searchResults[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.grey),
                        title: Text(res['name'], style: const TextStyle(color: Colors.white)),
                        subtitle: Text(res['address'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        onTap: () {
                          if (widget.isDepart) {
                            appProvider.setDepartLabel(res['name'], lat: res['lat'], lng: res['lng']);
                          } else {
                            appProvider.setArriveLabel(res['name'], lat: res['lat'], lng: res['lng']);
                          }
                          Navigator.pop(context);
                        },
                      );
                    } else {
                      final place = appProvider.favoritePlaces[index];
                      return ListTile(
                        leading: const Icon(Icons.home_outlined, color: Colors.grey),
                        title: Text(place.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(place.address, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        onTap: () {
                          if (widget.isDepart) {
                            appProvider.setDepartLabel(place.name, lat: place.lat, lng: place.lng);
                          } else {
                            appProvider.setArriveLabel(place.name, lat: place.lat, lng: place.lng);
                          }
                          Navigator.pop(context);
                        },
                      );
                    }
                  },
                ),
          ),
        ],
      ),
    );
  }
}
