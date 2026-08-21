import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../models.dart';
import '../widgets/interactive_map.dart';

// 버씽의 메인 화면입니다. 6:4 분할 화면 구조를 가집니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activePlaceIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppProvider>();

    return Stack(
      children: [
        Column(
          children: [
            // ── 상단 60%: 다크 모드 지도 ──
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.58,
              child: InteractiveMap(
                pins: appState.pins,
                pendingType: appState.mapPending,
                onTap: (x, y) => appState.handleMapTap(x, y),
              ),
            ),
            // ── 하단 40%: 경로 분석 결과 리스트 ──
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 28, offset: Offset(0, -4))],
                ),
                child: _buildResultPanel(appState),
              ),
            ),
          ],
        ),
        
        // ── 플로팅 유아이 요소들 ──

        // 상단 앱 타이틀
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

        // 검색 및 위치 설정 영역
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
                      placeholder: '도착지 설정',
                      color: appState.arriveLabel.isNotEmpty ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
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
              // 지도 직접 선택 버튼들
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

        // 지도 탭 안내 배너
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
                    const Icon(Icons.location_on, size: 13, color: Colors.white),
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
      ],
    );
  }

  // 하단 패널: 경로 추천 리스트와 분석 엔진 상태를 표시합니다.
  Widget _buildResultPanel(AppProvider state) {
    if (state.arriveLabel.isEmpty) {
      return _buildInitialPrompt();
    }

    return Column(
      children: [
        // 상단 손잡이
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(999)),
          ),
        ),
        
        // 장소 프리셋
        _buildPlacePresets(),

        // 분석 상태 문구
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  '${state.arriveLabel}으로 가는 최적 경로',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                if (state.isAnalyzing) ...[
                  const SizedBox(width: 8),
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                ]
              ],
            ),
          ),
        ),

        // 실시간 추천 경로 목록 (정렬 알고리즘 적용됨)
        Expanded(
          child: state.recommendedRoutes.isEmpty && state.isAnalyzing
              ? const Center(child: Text('데이터 분석 중...'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: state.recommendedRoutes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildRouteCard(state.recommendedRoutes[index]),
                ),
        ),
      ],
    );
  }

  // 도착지 설정 전 보여주는 안내 화면입니다.
  Widget _buildInitialPrompt() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, size: 48, color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text('어디로 가시나요?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
          Text('도착지를 설정하면 실시간 경로를 분석합니다', style: TextStyle(fontSize: 14, color: Color(0xFFD1D5DB))),
        ],
      ),
    );
  }

  // 장소 프리셋(집, 학교 등) 칩 목록입니다.
  Widget _buildPlacePresets() {
    final presets = [
      {'label': '집', 'icon': Icons.home_outlined},
      {'label': '학교', 'icon': Icons.school_outlined},
      {'label': '학원', 'icon': Icons.book_outlined},
      {'label': '헬스장', 'icon': Icons.fitness_center_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(presets.length, (i) {
          final p = presets[i];
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
              onSelected: (val) {
                setState(() => _activePlaceIndex = i);
                context.read<AppProvider>().setArriveLabel(p['label'] as String);
              },
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
    );
  }

  // 핵심: 신호등 알고리즘이 시각화된 경로 카드입니다.
  Widget _buildRouteCard(BusRouteInfo route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: route.statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: route.statusColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 2))],
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
                      Text(route.busName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                      const SizedBox(width: 10),
                      // 신호등 태그
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: route.statusColor, borderRadius: BorderRadius.circular(999)),
                        child: Text(route.statusText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 도착 시간 분석 결과
                  Row(
                    children: [
                      Text('${route.busArrivalRemaining}분 뒤 도착', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: route.statusColor)),
                      const Text('  •  ', style: TextStyle(color: Color(0xFFD1D5DB))),
                      Text(route.routeDescription, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    ],
                  ),
                ],
              ),
              // 총 소요 시간 (최종 하차 시간 기준)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Color(0xFF111827)),
                      const SizedBox(width: 4),
                      Text('총 ${route.totalETA}분', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    ],
                  ),
                  const Text('목적지 도착 예정', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
          
          // 탑승 어려움(🔴) 상태일 때의 특별 안내
          if (route.status == RouteStatus.hard) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFEE2E2))),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '현재 버스는 놓칠 확률이 높습니다. 다음 배차를 이용하세요.',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSearchOverlay(BuildContext context, PinType mode) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, _, __) => SearchOverlay(mode: mode),
    );
  }
}

// ── 하위 컴포넌트 (검색 버튼, 오버레이 등) ──

class _SearchButton extends StatelessWidget {
  final String label;
  final String? placeholder;
  final Color color;
  final VoidCallback onTap;
  final bool hasValue;
  final VoidCallback? onClear;

  const _SearchButton({required this.label, this.placeholder, required this.color, required this.onTap, this.hasValue = true, this.onClear});

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

    final Color themeColor = widget.mode == PinType.depart ? const Color(0xFF22C55E) : const Color(0xFF3B82F6);

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
                    const SizedBox(width: 12),
                    Text(
                      widget.mode == PinType.depart ? '출발지 설정' : '도착지 설정',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFF1F5F9)),
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
                  ),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: const TextStyle(fontSize: 15, color: Color(0xFFF1F5F9)),
                          decoration: InputDecoration(
                            hintText: widget.mode == PinType.depart ? '어디서 출발하시나요?' : '어디로 가시나요?',
                            hintStyle: const TextStyle(color: Color(0xFF64748B)),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
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
                  padding: EdgeInsets.fromLTRB(20, 20, 16, 8),
                  child: Text('즐겨찾는 장소', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A4A6A), letterSpacing: 0.5)),
                ),
                ...filtered.map((s) => ListTile(
                  onTap: () {
                    if (widget.mode == PinType.depart) appState.setDepartLabel(s['label']);
                    else appState.setArriveLabel(s['label']);
                    Navigator.pop(context);
                  },
                  leading: Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(color: Color(0xFF2E2E46), shape: BoxShape.circle),
                    child: Icon(s['icon'] as IconData, size: 18, color: const Color(0xFF94A3B8)),
                  ),
                  title: Text(s['label'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9))),
                  subtitle: Text(s['sub'], style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
