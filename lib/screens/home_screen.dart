import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../models.dart';
import '../widgets/interactive_map.dart';

// 앱의 첫 화면으로 지도와 경로 추천 정보를 보여줍니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activePlaceIndex = 0; // 현재 선택된 장소 프리셋 번호

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppProvider>();

    return Stack(
      children: [
        Column(
          children: [
            // 상단 지도 영역 (화면의 약 58% 차지)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.58,
              child: InteractiveMap(
                pins: appState.pins,
                pendingType: appState.mapPending,
                onTap: (x, y) => appState.handleMapTap(x, y),
              ),
            ),
            // 하단 경로 정보 영역 (나머지 공간 차지)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 28, offset: Offset(0, -4))],
                ),
                child: _buildBottomSheetContent(appState),
              ),
            ),
          ],
        ),
        
        // 앱 제목 표시
        Positioned(
          top: 56,
          left: 20,
          child: IgnorePointer(
            child: const Text(
              'Routine Bus',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFF1F5F9)),
            ),
          ),
        ),

        // 공중에 떠 있는 검색창 영역
        Positioned(
          top: 88,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SearchButton(
                      label: appState.departLabel,
                      color: const Color(0xFF22C55E),
                      onTap: () {
                        appState.setMapPending(null);
                        _showSearchOverlay(context, PinType.depart);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.arrow_forward, size: 14, color: Color(0xFF9CA3AF)),
                  ),
                  Expanded(
                    child: _SearchButton(
                      label: appState.arriveLabel,
                      placeholder: '도착지',
                      color: appState.arriveLabel.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFFD1D5DB),
                      hasValue: appState.arriveLabel.isNotEmpty,
                      onClear: () => appState.clearArrival(),
                      onTap: () {
                        appState.setMapPending(null);
                        _showSearchOverlay(context, PinType.arrive);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _MapPinButton(
                    label: '지도에서 출발 선택',
                    isActive: appState.mapPending == PinType.depart,
                    color: const Color(0xFF60A5FA),
                    activeBg: const Color(0xFF1D4ED8),
                    onTap: () => appState.setMapPending(appState.mapPending == PinType.depart ? null : PinType.depart),
                  ),
                  const SizedBox(width: 8),
                  _MapPinButton(
                    label: '지도에서 도착 선택',
                    isActive: appState.mapPending == PinType.arrive,
                    color: const Color(0xFFF87171),
                    activeBg: const Color(0xFF991B1B),
                    onTap: () => appState.setMapPending(appState.mapPending == PinType.arrive ? null : PinType.arrive),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 지도 탭 안내 문구
        if (appState.mapPending != null)
          Positioned(
            top: 168,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: appState.mapPending == PinType.depart ? const Color(0xFF1D4ED8) : const Color(0xFFB91C1C),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      appState.mapPending == PinType.depart ? '지도를 탭해 출발지를 설정하세요' : '지도를 탭해 도착지를 설정하세요',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => appState.setMapPending(null),
                      child: Icon(Icons.close, size: 13, color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 현재 위치 재탐색 버튼
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.42 + 20,
          right: 16,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF222236),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF2E2E46)),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 2))],
            ),
            child: const Icon(Icons.navigation_outlined, size: 16, color: Color(0xFF60A5FA)),
          ),
        ),
      ],
    );
  }

  // 하단 시트 내부에 들어갈 경로 정보를 생성합니다.
  Widget _buildBottomSheetContent(AppProvider state) {
    final places = [
      {'label': '집', 'icon': Icons.home_outlined},
      {'label': '학교', 'icon': Icons.school_outlined},
      {'label': '학원', 'icon': Icons.book_outlined},
      {'label': '헬스장', 'icon': Icons.fitness_center_outlined},
    ];

    // 알고리즘에 의해 계산된 가상의 버스 경로 데이터입니다.
    final routes = [
      BusRouteInfo(
        busName: '수완03',
        status: '안정 탑승',
        minutesRemaining: 7,
        walkInfo: '정류장까지 도보 3분',
        totalTravelTime: 20,
        color: const Color(0xFF10B981),
      ),
      BusRouteInfo(
        busName: '지원151',
        status: '서두르세요',
        minutesRemaining: 5,
        walkInfo: '도보 4분',
        totalTravelTime: 35,
        color: const Color(0xFFF59E0B),
      ),
      BusRouteInfo(
        busName: '풍암16',
        status: '탑승 어려움',
        minutesRemaining: 2,
        walkInfo: '도보 5분',
        totalTravelTime: 35,
        color: const Color(0xFFDC2626),
        suggestion: '다음 버스 12분 후 도착 — 가장 빠른 도착을 위해 권장',
      ),
    ];

    return Column(
      children: [
        // 상단 손잡이 부분
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(999)),
          ),
        ),
        
        // 장소 선택 칩 목록
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: List.generate(places.length, (i) {
              final p = places[i];
              final bool isActive = i == _activePlaceIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    children: [
                      Icon(p['icon'] as IconData, size: 13, color: isActive ? const Color(0xFF39FF14) : const Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(p['label'] as String),
                    ],
                  ),
                  selected: isActive,
                  onSelected: (val) => setState(() => _activePlaceIndex = i),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF111827),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? Colors.white : const Color(0xFF374151),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: isActive ? const Color(0xFF111827) : const Color(0xFFE5E7EB), width: 1.5)),
                  showCheckmark: false,
                ),
              );
            }),
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('집으로 가는 가장 빠른 경로', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ),
        ),

        // 추천 경로 카드 리스트
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: routes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildRouteCard(routes[index]),
          ),
        ),
      ],
    );
  }

  // 개별 경로 카드를 구성합니다. 신호등 색상 로직이 적용되어 있습니다.
  Widget _buildRouteCard(BusRouteInfo route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: route.color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: route.color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(route.busName, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(color: route.color, borderRadius: BorderRadius.circular(999)),
                        child: Text(route.status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${route.minutesRemaining}분 남음', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: route.color)),
                  Text(route.walkInfo, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: route.color),
                  const SizedBox(width: 4),
                  Text('${route.totalTravelTime}분', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: route.color)),
                ],
              ),
            ],
          ),
          if (route.suggestion != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFED7AA))),
              child: Text(
                route.suggestion!,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 검색 화면을 전체 화면 팝업으로 띄웁니다.
  void _showSearchOverlay(BuildContext context, PinType mode) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, _, __) => SearchOverlay(mode: mode),
    );
  }
}

// 검색창 모양의 버튼 위젯입니다.
class _SearchButton extends StatelessWidget {
  final String label;
  final String? placeholder;
  final Color color;
  final VoidCallback onTap;
  final bool hasValue;
  final VoidCallback? onClear;

  const _SearchButton({
    required this.label,
    this.placeholder,
    required this.color,
    required this.onTap,
    this.hasValue = true,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label.isEmpty ? (placeholder ?? '') : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: label.isNotEmpty ? FontWeight.w600 : FontWeight.w400, color: label.isNotEmpty ? const Color(0xFF111827) : const Color(0xFF9CA3AF)),
              ),
            ),
            if (hasValue && onClear != null)
              GestureDetector(
                onTap: () => onClear!(),
                child: const Icon(Icons.close, size: 12, color: Color(0xFF9CA3AF)),
              ),
          ],
        ),
      ),
    );
  }
}

// 지도에서 지점을 선택하기 위한 하단 버튼 위젯입니다.
class _MapPinButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final Color activeBg;
  final VoidCallback onTap;

  const _MapPinButton({required this.label, required this.isActive, required this.color, required this.activeBg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeBg : const Color(0xFF1E1E30).withOpacity(0.85),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, size: 11, color: isActive ? const Color(0xFFBFDBFE) : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFFBFDBFE) : color),
            ),
          ],
        ),
      ),
    );
  }
}

// 장소 검색을 수행하는 오버레이 화면입니다.
class SearchOverlay extends StatefulWidget {
  final PinType mode;
  const SearchOverlay({super.key, required this.mode});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final _controller = TextEditingController();
  final List<Map<String, dynamic>> _suggestions = [
    {'icon': Icons.home_outlined, 'label': '우리집', 'sub': '광주 광산구 수완동 123'},
    {'icon': Icons.school_outlined, 'label': '조선대학교', 'sub': '광주 동구 필문대로 309'},
    {'icon': Icons.location_on_outlined, 'label': '수완버스터미널', 'sub': '광주 광산구 수완동'},
    {'icon': Icons.book_outlined, 'label': '수완학원', 'sub': '광주 광산구 수완로 45'},
    {'icon': Icons.fitness_center_outlined, 'label': '스포애니 헬스장', 'sub': '광주 광산구 수완지구'},
    {'icon': Icons.location_on_outlined, 'label': '광주송정역', 'sub': '광주 광산구 송정2동'},
    {'icon': Icons.location_on_outlined, 'label': '조선대학교 후문', 'sub': '광주 동구 서석동'},
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppProvider>();
    final query = _controller.text.toLowerCase();
    final filtered = _suggestions.where((s) => s['label'].toLowerCase().contains(query) || s['sub'].toLowerCase().contains(query)).toList();

    final Color themeColor = widget.mode == PinType.depart ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: const Color(0xFF181824),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2E2E46)))),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFF2E2E46), shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 18, color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.mode == PinType.depart ? '출발지 설정' : '도착지 설정',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF1F5F9)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222236),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: themeColor, width: 1.5),
                    boxShadow: [BoxShadow(color: themeColor.withOpacity(0.15), blurRadius: 0, spreadRadius: 3)],
                  ),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: const TextStyle(fontSize: 14, color: Color(0xFFF1F5F9)),
                          decoration: InputDecoration(
                            hintText: widget.mode == PinType.depart ? '출발지 입력...' : '도착지 입력...',
                            hintStyle: const TextStyle(color: Color(0xFF64748B)),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _controller.clear()),
                          child: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFF2E2E46), borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFF3E3E5E))),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF60A5FA)),
                        SizedBox(width: 8),
                        Text('지도에서 직접 선택하기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF93C5FD))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('즐겨찾는 장소', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4A4A6A), letterSpacing: 0.5)),
                ),
                ...filtered.map((s) => ListTile(
                  onTap: () {
                    if (widget.mode == PinType.depart) appState.출발지문구설정(s['label']);
                    else appState.도착지문구설정(s['label']);
                    Navigator.pop(context);
                  },
                  leading: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: Color(0xFF2E2E46), shape: BoxShape.circle),
                    child: Icon(s['icon'] as IconData, size: 17, color: const Color(0xFF94A3B8)),
                  ),
                  title: Text(s['label'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9))),
                  subtitle: Text(s['sub'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.chevron_right, size: 16, color: Color(0xFF3E3E5E)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: const Border(bottom: BorderSide(color: Color(0xFF1E1E30))),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
