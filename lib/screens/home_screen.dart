import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart'; 
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../models.dart';
import '../data/bus_schedules.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import 'route_preview_screen.dart'; 

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
  bool _stopsExpanded = false; 
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.4);
  
  final ScrollController _internalSheetScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentPosition = LatLng(37.5666, 126.9784); // 기본 위치(서울시청) 설정으로 즉시 지도 렌더링
    _initializeLocationAndCompass();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    _sheetExtent.dispose();
    _internalSheetScrollController.dispose();
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

    if (moveCamera && mapController != null) {
      mapController!.setCenter(newLatLng);
    }

    context.read<AppProvider>().updateDepartLocation(lat, lng);

    if (_isFirstLocationSync && mounted) {
      _isFirstLocationSync = false;
      context.read<AppProvider>().updateDefaultPlacesWithLocation(lat, lng);
      if (mapController != null) {
        mapController!.setCenter(newLatLng);
      }
    }
  }

  List<CustomOverlay> _generateOverlays(AppProvider appProvider) {
    List<CustomOverlay> overlays = [];

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

    for (var pin in appProvider.pins) {
      if (pin.type == PinType.arrive) {
        overlays.add(CustomOverlay(
          customOverlayId: 'arrive_${pin.x}_${pin.y}',
          latLng: LatLng(pin.x, pin.y),
          content: '''
            <div style="display: flex; flex-direction: column; align-items: center;">
              <div style="background: #DC2626; color: white; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: bold; margin-bottom: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.2);">${pin.label ?? '목적지'}</div>
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

    final busStops = appProvider.pins.where((p) => p.type == PinType.busStop).toList();
    for (var pin in busStops) {
      final type = pin.address; 
      String actionLabel = '정류장';
      Color color = const Color(0xFF4B5563);
      if (type == 'boarding') { actionLabel = '승차'; color = const Color(0xFF10B981); }
      else if (type == 'alighting') { actionLabel = '하차'; color = const Color(0xFF2563EB); }
      else if (type == 'transfer') { actionLabel = '환승'; color = const Color(0xFFF59E0B); }
      
      overlays.add(_buildStopOverlay(
        pin, 
        actionLabel, 
        color, 
        showLabel: true,
        // 💡 [수석 개발자] 지도 레벨 3 이하(더 가까운 줌)에서만 정류장 이름 노출
        subLabel: _currentZoomLevel <= 3 ? pin.label : null, 
      ));
    }

    if (_currentZoomLevel <= 5) { 
      final passStops = appProvider.pins.where((p) => p.type == PinType.passStop).toList();
      for (var pin in passStops) {
        overlays.add(_buildStopOverlay(
          pin, 
          pin.label ?? '정류장', 
          const Color(0xFF6B7280), 
          // 💡 [수석 개발자] 경로 탐색 직후 지도가 복잡해지지 않도록 경유 정류장 이름은 기본적으로 숨김
          // 지도 레벨 2 이하(매우 정밀)일 때만 노출
          showLabel: _currentZoomLevel <= 2,
          mini: true, 
        ));
      }
    }

    return overlays;
  }

  CustomOverlay _buildStopOverlay(MapPin pin, String label, Color color, {bool showLabel = true, bool mini = false, String? subLabel}) {
    final hexColor = colorToHex(color);
    return CustomOverlay(
      customOverlayId: 'stop_${pin.x}_${pin.y}_${label}_${subLabel ?? ""}',
      latLng: LatLng(pin.x, pin.y),
      content: '''
        <div style="display: flex; flex-direction: column; align-items: center; cursor: pointer; transform: scale(${mini ? 0.8 : 0.9});">
          ${showLabel ? '<div style="display: flex; flex-direction: column; align-items: center;">' + (subLabel != null ? '<div style="background: white; color: $hexColor; padding: 1px 4px; border-radius: 3px; font-size: 9px; font-weight: bold; margin-bottom: 1px; box-shadow: 0 1px 2px rgba(0,0,0,0.15); border: 1px solid $hexColor; white-space: nowrap;">$subLabel</div>' : '') + '<div style="background: $hexColor; color: white; padding: ${mini ? "1px 4px" : "2px 7px"}; border-radius: 10px; font-size: ${mini ? "8px" : "10px"}; font-weight: bold; margin-bottom: 1px; box-shadow: 0 1px 3px rgba(0,0,0,0.15); white-space: nowrap; border: 1px solid rgba(255,255,255,0.2); opacity: ${mini ? "0.75" : "1.0"};">$label</div></div>' : ''}
          <div style="width: ${mini ? '6px' : '10px'}; height: ${mini ? '6px' : '10px'}; background: white; border-radius: 50%; border: ${mini ? '1.5px' : '2.5px'} solid $hexColor; box-shadow: 0 1px 3px rgba(0,0,0,0.15);"></div>
        </div>
      ''',
      xAnchor: 0.5, yAnchor: 0.9,
    );
  }

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
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

  void _moveToMyLocation() async {
    if (_currentPosition != null && mapController != null) {
      mapController!.setCenter(_currentPosition!);
      mapController!.setLevel(3);
      setState(() {
        _currentZoomLevel = 3;
      });
    }
  }

  void _fitRouteBounds(LatLng p1, LatLng p2) {
    if (mapController == null) return;
    
    final centerLat = (p1.latitude + p2.latitude) / 2;
    final centerLng = (p1.longitude + p2.longitude) / 2;
    
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

    mapController!.setCenter(LatLng(centerLat, centerLng));
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && mapController != null) {
        mapController!.setLevel(optimalLevel);
        setState(() {
          _currentZoomLevel = optimalLevel;
        });
      }
    });
  }

  Widget _buildArrivalListTile(BusRouteInfo bus) {
    final appProvider = context.read<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 52,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF3D7EFF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3D7EFF).withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              bus.busName,
              style: const TextStyle(color: Color(0xFF3D7EFF), fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ),
        title: Text(
          bus.busArrivalRemaining == -2 ? '운행 종료' : 
          (bus.busArrivalRemaining == -1 ? '실시간 정보 없음' : '${bus.busArrivalRemaining}분 뒤 도착'), 
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 16)
        ),
        subtitle: Text(
          bus.stopsRemaining ?? (bus.busArrivalRemaining == -2 ? '운행 종료' : ''),
          style: TextStyle(
            color: bus.busArrivalRemaining == -2 ? Colors.red : const Color(0xFF3D7EFF), 
            fontWeight: FontWeight.bold, 
            fontSize: 12
          ),
        ),
        trailing: IconButton(
          onPressed: () => appProvider.openBusLineInfo(bus.busName),
          icon: Icon(Icons.info_outline, color: isDark ? const Color(0xFF555D7A) : Colors.black26, size: 20),
        ),
      ),
    );
  }

  Widget _buildBusStopListView(AppProvider appProvider) {
    final stations = appProvider.state.activeLineStations;
    final busName = appProvider.state.activeBusName ?? '';
    final details = appProvider.state.activeBusDetails;
    final direction = appProvider.state.activeDirection;
    final dirTitle = direction == 'UP' 
        ? (details?['DIR_UP_NAME'] ?? '상행') 
        : (details?['DIR_DOWN_NAME'] ?? '하행');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4)),
              child: const Text('간선', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Text(busName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close, size: 24, color: isDark ? Colors.white54 : Colors.black54),
              onPressed: () => appProvider.setBarMode(WidgetBarMode.main),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        GestureDetector(
          onTap: () => appProvider.switchBusDirection(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242836) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$dirTitle 방면', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
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
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      Container(width: 4, height: 20, color: index == 0 ? Colors.transparent : const Color(0xFFFBBF24)),
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1E2E) : Colors.white, shape: BoxShape.circle,
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
                      Text(s.stationName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 2),
                      Text('${s.firstBusTime} - ${s.lastBusTime}', style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF6B7280) : Colors.black45, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 14),
                      if (index != stations.length - 1) Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    ],
                  ),
                ),
              ],
            );
          }),
          
        const SizedBox(height: 30),
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
        Row(
          children: schedules.map((s) => Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(color: Color(0xFF00C7FF)), 
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = route.statusColor.withOpacity(isSelected ? 0.85 : 0.45);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => appProvider.selectRoute(index),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? route.statusColor.withOpacity(0.12) : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFFDFBF7)),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.5,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: route.statusColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    route.busName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5),
                  ),
                  const SizedBox(width: 12),
                  if (route.stopsRemaining != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D7EFF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        route.stopsRemaining!,
                        style: const TextStyle(color: Color(0xFF3D7EFF), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => appProvider.registerDepartureAlarm(context, route),
                    icon: Icon(Icons.notifications_active_outlined, color: route.statusColor, size: 20),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    route.busArrivalRemaining == -2
                        ? '운행 종료'
                        : (route.busArrivalRemaining == -1 ? '실시간 정보 없음' : '${route.busArrivalRemaining}분 남음'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: route.statusColor, letterSpacing: -0.5),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '· 도보 ${route.walkTimeRemaining}분',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withOpacity(0.4) : Colors.black38, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: isDark ? Colors.white70 : Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          '${route.totalDuration}분',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (route.routeDescription.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    route.routeDescription,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(AppProvider appProvider) {
    final bool isNavActive = appProvider.isGuidanceActive;
    final List<Place> extras = appProvider.state.extraDestinations;
    final bool isStopsExpanded = appProvider.state.isStopsExpanded;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: isDark ? const Color(0xFF1A1E2E).withOpacity(0.8) : Colors.white.withOpacity(0.9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => !isNavActive ? _openSearchLayer(context, appProvider, isDepart: true) : null,
                              child: _buildSearchField(
                                appProvider.departLabel,
                                const Color(0xFF3D7EFF),
                                glowColor: const Color(0xFF3D7EFF).withOpacity(0.6),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: extras.isNotEmpty
                              ? _buildStopsToggleButton(isStopsExpanded, () => appProvider.toggleStopsExpanded())
                              : IconButton(
                                  onPressed: () => !isNavActive ? _swapLocations(appProvider) : null,
                                  icon: Icon(Icons.swap_vert_rounded, color: isDark ? Colors.white.withOpacity(0.3) : Colors.black26, size: 20),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => !isNavActive ? _openSearchLayer(context, appProvider, isDepart: false) : null,
                              child: _buildSearchField(
                                appProvider.arriveLabel.isEmpty ? '어디로 가시나요?' : appProvider.arriveLabel,
                                const Color(0xFFFF6B6B),
                                glowColor: const Color(0xFFFF6B6B).withOpacity(0.6),
                                isDest: true,
                              ),
                            ),
                          ),
                          if ((appProvider.arriveLabel.isNotEmpty || appProvider.departLabel != '현재 위치') && !isNavActive)
                            IconButton(
                              onPressed: () => appProvider.clearCurrentRoute(),
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54, size: 14),
                              ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(left: 8),
                            ),
                        ],
                      ),
                    ),
                    if (extras.isNotEmpty && isStopsExpanded)
                      Container(
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                        ),
                        child: Column(
                          children: List.generate(extras.length, (index) => _buildStopRow(index, extras[index].name, !isNavActive, () {
                            appProvider.removeExtraDestination(index);
                          })),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isNavActive)
          _buildNavigatingBanner(appProvider),
      ],
    );
  }

  Widget _buildStopsToggleButton(bool expanded, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: expanded ? const Color(0xFF3D7EFF) : const Color(0xFF3D7EFF).withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF3D7EFF).withOpacity(expanded ? 1 : 0.3)),
        ),
        child: Icon(
          expanded ? Icons.remove : Icons.add,
          color: expanded ? Colors.white : const Color(0xFF3D7EFF),
          size: 14,
        ),
      ),
    );
  }

  Widget _buildStopRow(int index, String name, bool showDelete, VoidCallback onDelete) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFA78BFA).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.4)),
            ),
            child: Center(
              child: Text('${index + 1}', style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name, 
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87, 
                fontSize: 13, 
                fontWeight: FontWeight.w500
              ), 
              overflow: TextOverflow.ellipsis
            ),
          ),
          if (showDelete)
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close, color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2), size: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigatingBanner(AppProvider appProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3D7EFF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D7EFF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(color: Color(0xFF3D7EFF), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          const Text('안내 중', style: TextStyle(color: Color(0xFF3D7EFF), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(
            '· 예상 ${appProvider.totalGuidanceDuration == 0 ? "계산 중..." : "${appProvider.totalGuidanceDuration}분"}', 
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontSize: 13, 
              fontWeight: FontWeight.bold
            )
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => appProvider.stopGuidance(),
            child: const Text('종료', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _swapLocations(AppProvider appProvider) {
    final tempDepart = appProvider.departLabel;
    final tempArrive = appProvider.arriveLabel;
    appProvider.setDepartLabel(tempArrive);
    appProvider.setArriveLabel(tempDepart);
  }

  Widget _buildSearchField(String text, Color dotColor, {required Color glowColor, bool isDest = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // 💡 항상 왼쪽 정렬
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: glowColor, blurRadius: 6, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: (text == '어디로 가시나요?' || text == '도착지') 
                  ? (isDark ? Colors.white.withOpacity(0.4) : Colors.black38) 
                  : (isDark ? Colors.white : Colors.black),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left, // 💡 항상 왼쪽 정렬
            ),
          ),
        ],
      ),
    );
  }

  void _openSearchLayer(BuildContext context, AppProvider appProvider, {required bool isDepart}) {
    if (!isDepart) {
      appProvider.resetTempSettings();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => isDepart ? _DepartureModal() : _DestinationModal(),
    );
  }

  Widget _buildPlacePresets(AppProvider appProvider) {
    final List<Place> places = appProvider.favoritePlaces; // 💡 명시적 타입 지정 및 로컬 변수 활용
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 💡 [수석 개발자] 리스트가 비어있지 않은지 확인
    if (places.isEmpty) {
       return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: places.asMap().entries.map((entry) {
          final int i = entry.key;
          final Place p = entry.value;
          final bool isSelected = _selectedPlaceIndex == i;
          final String displayLabel = p.alias ?? p.name;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                debugPrint('🎯 [UI] Preset Clicked: $displayLabel (Coord: ${p.lat}, ${p.lng})');
                setState(() => _selectedPlaceIndex = i);
                
                // 💡 [수석 개발자] 프리셋 클릭 시 즉시 안내 모드 진입 (비동기 대기 없이 트리거)
                appProvider.setTempArriveLabel(displayLabel, lat: p.lat, lng: p.lng);
                appProvider.startGuidance(); // await 제거로 즉각적인 UI 반응성 확보
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3D7EFF) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? const Color(0xFF3D7EFF).withOpacity(0.4) : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? const Color(0xFFE8EAF2) : Colors.black87),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    if (appProvider.shouldMoveToArrival && mapController != null) {
      final arrivePin = appProvider.pins.firstWhere(
        (p) => p.type == PinType.arrive, 
        orElse: () => MapPin(x: 0, y: 0, type: PinType.arrive)
      );
      if (arrivePin.x != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mapController != null) {
            mapController!.setCenter(LatLng(arrivePin.x, arrivePin.y));
            mapController!.setLevel(3);
            context.read<AppProvider>().resetMoveToArrival();
          }
        });
      }
    }

    if (appProvider.shouldFitBounds && mapController != null) {
      final departPin = appProvider.pins.firstWhere((p) => p.type == PinType.depart, orElse: () => MapPin(x: 0, y: 0, type: PinType.depart));
      final arrivePin = appProvider.pins.firstWhere((p) => p.type == PinType.arrive, orElse: () => MapPin(x: 0, y: 0, type: PinType.arrive));
      
      if (departPin.x != 0 && arrivePin.x != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mapController != null) {
            _fitRouteBounds(LatLng(departPin.x, departPin.y), LatLng(arrivePin.x, arrivePin.y));
            context.read<AppProvider>().resetFitBounds();
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      key: ValueKey('map_session_${appProvider.analysisCount}'),
                      onMapCreated: _onMapCreated,
                      center: _currentPosition!,
                      customOverlays: _generateOverlays(appProvider),
                      markers: const [], 
                      onMarkerTap: (markerId, latLng, zoomLevel) async {
                        await context.read<AppProvider>().fetchStopArrivalInfo(latLng.latitude, latLng.longitude);
                      },
                      onCustomOverlayTap: (overlayId, latLng) async {
                        if (overlayId.startsWith('stop_')) {
                          await context.read<AppProvider>().fetchStopArrivalInfo(latLng.latitude, latLng.longitude);
                        }
                      },
                      polylines: appProvider.routeSegments.map((RouteSegment segment) => Polyline(
                        polylineId: segment.id,
                        points: segment.points,
                        strokeColor: segment.color,
                        strokeWidth: segment.width.toInt(),
                        strokeStyle: segment.strokeStyle, 
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
                      if (appProvider.state.alarmMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF3D7EFF), Color(0xFF6C5CE7)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: const Color(0xFF3D7EFF).withOpacity(0.4), blurRadius: 12)],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.alarm_on, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  appProvider.state.alarmMessage!,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1E2E).withOpacity(0.8) : Colors.white.withOpacity(0.9),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.1), blurRadius: 24)],
                      ),
                      child: Column(
                        children: [
                          SingleChildScrollView(
                            controller: scrollController,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              color: Colors.transparent, 
                              child: Center(
                                child: Container(
                                  width: 40, 
                                  height: 4, 
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1), 
                                    borderRadius: BorderRadius.circular(2)
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          Expanded(
                            child: ListView(
                              controller: _internalSheetScrollController,
                              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                              children: [
                                if (appProvider.state.barMode == WidgetBarMode.lineInfo) ...[
                                  _buildBusStopListView(appProvider),
                                ] else if (appProvider.state.barMode == WidgetBarMode.lineSchedule) ...[
                                  _buildDualScheduleView(appProvider),
                                ] else if (appProvider.state.barMode == WidgetBarMode.lineDetails) ...[
                                  _buildLineDetailInfoView(appProvider),
                                ] else if (appProvider.barMode == WidgetBarMode.main) ...[
                                  Text('자주 가는 목적지', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5)),
                                  const SizedBox(height: 16),
                                  _buildPlacePresets(appProvider),
                                  const SizedBox(height: 32),
                                  Row(
                                    children: [
                                      Text('지금 가장 빠른 노선', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.4)),
                                      const SizedBox(width: 10),
                                      if (appProvider.isAnalyzing)
                                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3D7EFF)))
                                      else
                                        IconButton(
                                          icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF3D7EFF)),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          onPressed: () => appProvider.refreshCurrentView(),
                                        ),
                                      const Spacer(),
                                      if (appProvider.recommendedRoutes.isNotEmpty || appProvider.isAnalyzing)
                                        GestureDetector(
                                          onTap: () => appProvider.clearCurrentRoute(),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: const Text('경로 취소', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
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
                                        icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : Colors.black87),
                                        onPressed: () => appProvider.setBarMode(WidgetBarMode.main),
                                      ),
                                      Expanded(
                                        child: Text(
                                          appProvider.selectedStopName ?? '정류장 정보',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!appProvider.isLoadingArrivals)
                                        IconButton(
                                          icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF3D7EFF)),
                                          onPressed: () => appProvider.refreshCurrentView(),
                                        ),
                                    ],
                                  ),
                                  Divider(height: 30, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                                  if (appProvider.isLoadingArrivals)
                                    const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF3D7EFF))))
                                  else if (appProvider.stopArrivals.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(40),
                                      child: Center(child: Text('도착 예정 정보가 없습니다.', style: TextStyle(color: Color(0xFF555D7A)))),
                                    )
                                  else
                                    ...appProvider.stopArrivals.map((bus) => _buildArrivalListTile(bus)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1E2E).withOpacity(0.8) : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(icon, size: 22, color: isDark ? Colors.white : Colors.black54),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
    );
  }
}

class _DepartureModal extends StatefulWidget {
  @override
  State<_DepartureModal> createState() => _DepartureModalState();
}

class _DepartureModalState extends State<_DepartureModal> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.1), blurRadius: 40)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: isDark ? const Color(0xFF1A1E2E).withOpacity(0.8) : const Color(0xFFFDFBF7).withOpacity(0.95),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), shape: BoxShape.circle),
                            child: Icon(Icons.close, color: isDark ? const Color(0xFF8B91A8) : Colors.black54, size: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text('출발지 설정', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: '출발지 입력...',
                          hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.2) : Colors.black26),
                          prefixIcon: const Icon(Icons.circle, color: Color(0xFF3D7EFF), size: 10),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (val) => appProvider.searchPlaces(val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 💡 [수석 개발자] 현재 위치 매크로 버튼 추가
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () {
                        appProvider.setDepartLabel('현재 위치');
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? const Color(0xFF3D7EFF).withOpacity(0.3) : const Color(0xFF3D7EFF).withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.my_location, size: 18, color: Color(0xFF3D7EFF)),
                            const SizedBox(width: 10),
                            Text(
                              '현재 위치로 설정',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    height: 1, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('즐겨찾는 장소', style: TextStyle(color: Color(0xFF555D7A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: appProvider.searchResults.isNotEmpty ? appProvider.searchResults.length : appProvider.favoritePlaces.length,
                      itemBuilder: (context, index) {
                        final bool isSearch = appProvider.searchResults.isNotEmpty;
                        final String name = isSearch ? appProvider.searchResults[index]['name'] : appProvider.favoritePlaces[index].name;
                        final String desc = isSearch ? appProvider.searchResults[index]['address'] : appProvider.favoritePlaces[index].address;
                        final String icon = isSearch ? '📍' : (name == '우리집' ? '🏠' : (name == '학교' ? '🏫' : '🏢'));

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                            title: Text(
                              isSearch ? name : (appProvider.favoritePlaces[index].alias ?? name), 
                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.bold)
                            ),
                            subtitle: Text(desc, style: const TextStyle(color: Color(0xFF555D7A), fontSize: 12), overflow: TextOverflow.ellipsis),
                            onTap: () {
                              if (isSearch) {
                                appProvider.setDepartLabel(name, lat: appProvider.searchResults[index]['lat'], lng: appProvider.searchResults[index]['lng']);
                              } else {
                                final p = appProvider.favoritePlaces[index];
                                // 💡 별칭으로 출발지 라벨 설정
                                appProvider.setDepartLabel(p.alias ?? p.name, lat: p.lat, lng: p.lng);
                              }
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DestinationModal extends StatefulWidget {
  @override
  State<_DestinationModal> createState() => _DestinationModalState();
}

class _DestinationModalState extends State<_DestinationModal> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _extraFocusNode = FocusNode();
  int? _editingIdx;
  String _extraInput = '';

  @override
  void dispose() {
    _extraFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final List<Place> tempExtras = appProvider.tempExtras;
    final bool hasExtras = tempExtras.isNotEmpty || _editingIdx != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.1), blurRadius: 40)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              color: isDark ? const Color(0xFF1A1E2E).withOpacity(0.85) : const Color(0xFFFDFBF7).withOpacity(0.95),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), shape: BoxShape.circle),
                            child: Icon(Icons.close, color: isDark ? const Color(0xFF8B91A8) : Colors.black54, size: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text('목적지 설정', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),

                  // Search Bar + Plus
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                            ),
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: '도착지 검색',
                                hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.2) : Colors.black26),
                                prefixIcon: const Icon(Icons.circle, color: Color(0xFFFF6B6B), size: 10),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                suffixIcon: const Icon(Icons.search, color: Color(0xFF3D7EFF), size: 20),
                              ),
                              onChanged: (val) {
                              appProvider.setTempArriveLabel(val);
                              appProvider.searchPlaces(val);
                            },
                            ),
                          ),
                        ),
                        if (tempExtras.length < 3 && appProvider.searchResults.isEmpty) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              if (_controller.text.isNotEmpty && appProvider.tempArriveLabel.isNotEmpty) {
                                // 💡 [수석 개발자] 검색창의 내용을 추가 목적지로 이동
                                appProvider.addTempExtra(
                                  appProvider.tempArriveLabel, 
                                  lat: appProvider.tempArriveLat, 
                                  lng: appProvider.tempArriveLng
                                );
                                // 검색창 초기화
                                setState(() {
                                  _controller.clear();
                                  appProvider.setTempArriveLabel('');
                                });
                                appProvider.searchPlaces('');
                              } else {
                                // 기존 로직: 그냥 포커스만 주기 (비어있을 때)
                                _extraFocusNode.requestFocus();
                              }
                            },
                            child: Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF3D7EFF), Color(0xFF6C5CE7)]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: const Color(0xFF3D7EFF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 💡 [수석 개발자] 목적지 모달에도 현재 위치 매크로 버튼 추가
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () {
                        final currentPos = appProvider.pins.firstWhere(
                          (p) => p.type == PinType.depart,
                          orElse: () => MapPin(x: 35.1601, y: 126.8515, type: PinType.depart)
                        );
                        appProvider.setTempArriveLabel('현재 위치', lat: currentPos.x, lng: currentPos.y);
                        // 💡 [수석 개발자] 선택 즉시 검색어 초기화 및 텍스트 반영
                        setState(() {
                          _controller.text = '현재 위치';
                        });
                        appProvider.searchPlaces('');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? const Color(0xFF3D7EFF).withOpacity(0.3) : const Color(0xFF3D7EFF).withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.my_location, size: 18, color: Color(0xFF3D7EFF)),
                            const SizedBox(width: 10),
                            Text(
                              '현재 위치로 설정',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fixed Height Content Area
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: appProvider.searchResults.isNotEmpty
                        ? _buildSearchResults(appProvider)
                        : (!hasExtras ? _buildFavorites(appProvider) : _buildExtraStops(appProvider, tempExtras)),
                  ),

                  // Action Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    child: GestureDetector(
                      onTap: () {
                        appProvider.startGuidance();
                        Navigator.pop(context);
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(builder: (context) => const RoutePreviewScreen()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF3D7EFF), Color(0xFF6C5CE7)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: const Color(0xFF3D7EFF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                            SizedBox(width: 12),
                            Text('안내 시작', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(AppProvider appProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('검색 결과', style: TextStyle(color: Color(0xFF3D7EFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: appProvider.searchResults.length,
            itemBuilder: (context, index) {
              final res = appProvider.searchResults[index];
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text('📍', style: TextStyle(fontSize: 18))),
                  ),
                  title: Text(res['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
                  subtitle: Text(res['address'], style: TextStyle(color: isDark ? const Color(0xFF8B91A8) : const Color(0xFF555D7A), fontSize: 12), overflow: TextOverflow.ellipsis),
                  onTap: () {
                    debugPrint('🔎 [UI] Search Result Selected: ${res['name']}');
                    setState(() {
                      if (_editingIdx == null) {
                        _controller.text = res['name'];
                        appProvider.setTempArriveLabel(res['name'], lat: res['lat'], lng: res['lng']);
                      } else {
                        if (_editingIdx == -1) {
                          appProvider.addTempExtra(res['name'], lat: res['lat'], lng: res['lng']);
                        } else {
                          appProvider.updateTempExtra(_editingIdx!, res['name'], lat: res['lat'], lng: res['lng']);
                        }
                        _editingIdx = null;
                      }
                    });
                    appProvider.searchPlaces(''); 
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavorites(AppProvider appProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('즐겨찾는 장소', style: TextStyle(color: isDark ? const Color(0xFF8B91A8) : const Color(0xFF555D7A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: appProvider.favoritePlaces.length,
            itemBuilder: (context, index) {
              final place = appProvider.favoritePlaces[index];
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  title: Text(place.alias ?? place.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
                  subtitle: Text(place.address, style: TextStyle(color: isDark ? const Color(0xFF8B91A8) : const Color(0xFF555D7A), fontSize: 12), overflow: TextOverflow.ellipsis),
                  onTap: () {
                    debugPrint('⭐️ [UI] Favorite Selected in Modal: ${place.alias ?? place.name}');
                    // 💡 [수석 개발자] 텍스트 필드 갱신 및 검색 결과 초기화로 확실한 반응성 확보
                    setState(() {
                      _controller.text = place.alias ?? place.name;
                    });
                    appProvider.setTempArriveLabel(place.alias ?? place.name, lat: place.lat, lng: place.lng);
                    appProvider.searchPlaces(''); // 검색 결과 지워서 확실히 선택되었음을 알림
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExtraStops(AppProvider appProvider, List<Place> extras) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('추가 목적지', style: TextStyle(color: isDark ? const Color(0xFF8B91A8) : const Color(0xFF555D7A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: extras.length,
            itemBuilder: (context, i) => _buildStopItem(i, extras[i].name, appProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildStopItem(int index, String name, AppProvider appProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: const Color(0xFF3D7EFF).withOpacity(0.2), shape: BoxShape.circle),
            child: Center(child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF3D7EFF), fontSize: 10, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: () => appProvider.removeTempExtra(index),
            child: Icon(Icons.remove_circle_outline, color: const Color(0xFFFF6B6B).withOpacity(0.7), size: 20),
          ),
        ],
      ),
    );
  }
}
