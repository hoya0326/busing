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

  int _currentZoomLevel = 3;
  int _selectedPlaceIndex = -1;

  LatLng? _currentPosition;
  double _currentHeading = 0.0;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;

  bool _isFirstLocationSync = true;
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

    if (moveCamera && mapController != null) {
      mapController!.setCenter(newLatLng);
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
          xAnchor: 0.5, yAnchor: 1.0,
        ));
      }
    }

    final busStops = appProvider.pins.where((p) => p.type == PinType.busStop).toList();
    for (int i = 0; i < busStops.length; i++) {
      final pin = busStops[i];
      final type = pin.address; 
      
      String label = '정류장';
      Color color = const Color(0xFF2563EB);
      if (type == 'boarding') label = '승차';
      else if (type == 'alighting') label = '하차';
      else if (type == 'transfer') {
        label = '환승';
        color = const Color(0xFFF59E0B);
      }
      
      overlays.add(CustomOverlay(
        customOverlayId: 'bus_stop_${pin.x}_${pin.y}',
        latLng: LatLng(pin.x, pin.y),
        content: '''
          <div style="display: flex; flex-direction: column; align-items: center; pointer-events: none;">
            <div style="background: ${colorToHex(color)}; color: white; padding: 3px 9px; border-radius: 12px; font-size: 11px; font-weight: bold; margin-bottom: 2px; box-shadow: 0 2px 4px rgba(0,0,0,0.2); white-space: nowrap; border: 1px solid rgba(255,255,255,0.3);">
              $label
            </div>
            <div style="width: 24px; height: 24px; background: ${colorToHex(color)}; border-radius: 6px; border: 2px solid white; display: flex; justify-content: center; align-items: center; box-shadow: 0 2px 6px rgba(0,0,0,0.3);">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="white">
                <path d="M18 11V7c0-2.209-1.791-4-4-4h-4c-2.209 0-4 1.791-4 4v4H5v7c0 1.105.895 2 2 2v1c0 .552.448 1 1 1h1c.552 0 1-.448 1-1v-1h4v1c0 .552.448 1 1 1h1c.552 0 1-.448 1-1v-1c1.105 0 2-.895 2-2v-7h-1zM8 7c0-1.105.895-2 2-2h4c1.105 0 2 .895 2 2v4H8V7zm2 11c-.552 0-1-.448-1-1s.448-1 1-1 1 .448 1 1-.448 1-1 1zm4 0c-.552 0-1-.448-1-1s.448-1 1-1 1 .448 1 1-.448 1-1 1z"/>
              </svg>
            </div>
          </div>
        ''',
        xAnchor: 0.5, yAnchor: 0.88,
      ));
    }
    return overlays;
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
    if (_currentPosition != null && mapController != null) {
      mapController!.setCenter(_currentPosition!);
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

    setState(() {
      _currentZoomLevel = optimalLevel;
    });
    mapController!.setCenter(LatLng(centerLat, centerLng));
    mapController!.setLevel(optimalLevel);
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(8)),
        child: Text(bus.busName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text('${bus.busArrivalRemaining}분 뒤 도착', style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text(bus.statusText, style: TextStyle(color: bus.statusColor, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBusRouteCard(BusRouteInfo route, int index, bool isSelected, AppProvider appProvider) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
      backgroundColor: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
      onTap: () { appProvider.selectRoute(index); },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 70, padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(route.busName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${route.busArrivalRemaining}분 남음', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('(도보 ${route.walkTimeRemaining}분)', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    ],
                  ),
                  Text(route.routeDescription, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: route.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
                child: Text(route.statusText, style: TextStyle(color: route.statusColor, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 4),
              Text('총 ${route.totalDuration}분', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    if (appProvider.shouldFitBounds && _currentPosition != null) {
      final arrivePin = appProvider.pins.firstWhere((p) => p.type == PinType.arrive, orElse: () => MapPin(x: 0, y: 0, type: PinType.arrive));
      if (arrivePin.x != 0) {
        Future.microtask(() {
          _fitRouteBounds(_currentPosition!, LatLng(arrivePin.x, arrivePin.y));
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
                      onMapCreated: _onMapCreated,
                      center: _currentPosition!,
                      customOverlays: _generateOverlays(appProvider),
                      markers: appProvider.pins.where((p) => p.type == PinType.busStop).map((p) => Marker(
                        markerId: 'stop_${p.x}_${p.y}',
                        latLng: LatLng(p.x, p.y),
                        width: 48, height: 48,
                      )).toList(),
                      onMarkerTap: (markerId, latLng, zoomLevel) async {
                        await context.read<AppProvider>().fetchStopArrivalInfo(latLng.latitude, latLng.longitude);
                      },
                      polylines: appProvider.routeSegments.map((segment) => Polyline(
                        polylineId: 'route_${appProvider.routeSegments.indexOf(segment)}',
                        points: segment.points,
                        strokeColor: segment.color,
                        strokeWidth: segment.width.toInt(),
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
                  child: _buildSearchHeader(appProvider),
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
                      Center(child: Container(width: 45, height: 6, margin: const EdgeInsets.only(bottom: 25), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                      if (appProvider.barMode == WidgetBarMode.main) ...[
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
                        if (appProvider.isServiceEnded || appProvider.errorMessage != null)
                          _buildServiceEndedWidget(appProvider.errorMessage)
                        else if (appProvider.recommendedRoutes.isEmpty && !appProvider.isAnalyzing)
                          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('목적지를 선택하면 최적의 경로를 분석합니다.', style: TextStyle(color: Colors.grey)))
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
            decoration: InputDecoration(
              hintText: widget.isDepart ? '출발지 입력...' : '도착지 입력...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.circle, color: widget.isDepart ? Colors.blue : Colors.grey, size: 12),
              filled: true,
              fillColor: const Color(0xFF1F2937),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => appProvider.searchPlaces(val),
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
