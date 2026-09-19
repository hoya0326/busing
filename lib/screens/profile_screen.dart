import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../services/notification_service.dart';
import '../models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _activeSubPage; 

  int _mockMin = 3;
  int _mockStop = 1;

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    
    if (_activeSubPage == 'widget') {
      return _buildWidgetSimulation(appProvider);
    }
    
    if (_activeSubPage != null) {
      return _buildSubPage(_activeSubPage!);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20, left: 20),
            child: Text('설정', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          ),
          // _buildDarkStats() 삭제됨

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('내 장소', style: TextStyle(color: Color(0xFF8B91A8), fontSize: 13, fontWeight: FontWeight.bold)),
                if (appProvider.favoritePlaces.length < 6)
                  GestureDetector(
                    onTap: () => _openEditPlaceModal(context, -1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF3D7EFF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Color(0xFF3D7EFF), size: 14),
                          SizedBox(width: 4),
                          Text('추가', style: TextStyle(color: Color(0xFF3D7EFF), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: [
                ...List.generate(appProvider.favoritePlaces.length, (index) {
                  final place = appProvider.favoritePlaces[index];
                  return _buildPlaceCard(
                    place.alias ?? place.name, 
                    () => _openEditPlaceModal(context, index),
                    onLongPress: () => _showDeleteConfirm(context, index, place.alias ?? place.name),
                  );
                }),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, 12),
            child: Text('기본 설정', style: TextStyle(color: Color(0xFF8B91A8), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1E2E) : const Color(0xFFFDFBF7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05)),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildDrillDownItem(
                    icon: Icons.notifications_none,
                    label: '알림 및 소리',
                    desc: '알림 ${appProvider.notifOn ? "ON" : "OFF"}',
                    onTap: () => setState(() => _activeSubPage = 'alarm'),
                  ),
                  _buildDivider(isDark),
                  _buildDrillDownItem(
                    icon: Icons.dark_mode_outlined,
                    label: '화면 및 테마',
                    desc: '다크 모드 ${appProvider.darkMode ? "ON" : "OFF"}',
                    onTap: () => setState(() => _activeSubPage = 'display'),
                  ),
                  _buildDivider(isDark),
                  _buildDrillDownItem(
                    icon: Icons.directions_walk,
                    label: '이동 스타일',
                    desc: 'GPS 권한 및 위치 설정',
                    onTap: () => setState(() => _activeSubPage = 'move'),
                  ),
                  _buildDivider(isDark),
                  _buildDrillDownItem(
                    icon: Icons.settings_outlined,
                    label: '시스템 및 데이터',
                    desc: '실시간 데이터 관리',
                    onTap: () => setState(() => _activeSubPage = 'system'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(String label, VoidCallback onTap, {VoidCallback? onLongPress}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1E2E) : const Color(0xFFFDFBF7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label, 
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPlaceCard(bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: isDark ? Colors.white38 : Colors.black26, size: 18),
            const SizedBox(width: 8),
            Text('추가', style: TextStyle(color: isDark ? Colors.white38 : Colors.black26, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrillDownItem({required IconData icon, required String label, required String desc, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: isDark ? const Color(0xFF242836) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: const Color(0xFF3D7EFF), size: 20),
      ),
      title: Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(desc, style: TextStyle(color: isDark ? const Color(0xFF555D7A) : Colors.black45, fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF2E3347) : Colors.black12),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) => Divider(height: 1, color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05), indent: 72);

  Widget _buildSubPage(String type) {
    String title = '';
    if (type == 'alarm') title = '알림 및 소리';
    else if (type == 'display') title = '화면 및 테마';
    else if (type == 'move') title = '이동 스타일';
    else if (type == 'system') title = '시스템 및 데이터';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: isDark ? const Color(0xFF8B91A8) : Colors.black54, size: 20), onPressed: () => setState(() => _activeSubPage = null)),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 17, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: _getSubPageItems(type),
      ),
    );
  }

  List<Widget> _getSubPageItems(String type) {
    final provider = context.watch<AppProvider>();
    if (type == 'alarm') {
      return [
        _buildToggleTile('알림 온/오프', '막차 및 루틴 알림', provider.notifOn, (v) => provider.setNotifOn(v)),
      ];
    } else if (type == 'display') {
      return [
        _buildToggleTile('다크 모드', '앱 UI 색상 변경', provider.darkMode, (v) => provider.setDarkMode(v)),
        const SizedBox(height: 20),
        const Text('글자 및 아이콘 크기', style: TextStyle(color: Color(0xFF8B91A8), fontSize: 12)),
        const SizedBox(height: 10),
        _buildChipSelector(
          ['작게', '보통', '크게'], 
          provider.state.fontScaleDelta == -5 ? '작게' : (provider.state.fontScaleDelta == 5 ? '크게' : '보통'), 
          (v) {
            double delta = 0;
            if (v == '작게') delta = -5;
            if (v == '크게') delta = 5;
            provider.setFontScaleDelta(delta);
          }
        ),
      ];
    } else if (type == 'move') {
      return [
        _buildToggleTile('위치 및 GPS 권한', '현재 위치 자동 갱신', true, (v) {}),
      ];
    } else {
      return [
        _buildToggleTile('실시간 데이터 새로고침', '버스 위치 자동 업데이트', provider.state.realTimeRefresh, (v) => provider.setRealTimeRefresh(v)),
        const SizedBox(height: 20),
        _buildMenuButton('잠금화면 위젯 설정', '홈 화면 위젯 구성', Icons.layers_outlined, () => _openWidgetPreview(context)),
        _buildMenuButton('캐시 및 데이터 삭제', '저장된 임시 데이터 초기화', Icons.delete_outline, () => _showClearConfirm(context)),
        _buildMenuButton('앱 정보 및 버전', 'v1.0.0', Icons.info_outline, () => _showAppInfo(context)),
      ];
    }
  }

  Widget _buildToggleTile(String label, String desc, bool val, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1E2E) : const Color(0xFFFDFBF7), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
            Text(desc, style: TextStyle(color: isDark ? const Color(0xFF555D7A) : Colors.black45, fontSize: 12)),
          ]),
          CupertinoSwitch(value: val, onChanged: onChanged, activeColor: const Color(0xFF3D7EFF)),
        ],
      ),
    );
  }

  Widget _buildChipSelector(List<String> options, String current, ValueChanged<String> onSelect) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: options.map((opt) {
        final isSelected = current == opt;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3D7EFF) : (isDark ? const Color(0xFF1A1E2E) : const Color(0xFFFDFBF7)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.transparent : (isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05))),
                ),
                child: Center(child: Text(opt, style: TextStyle(color: isSelected ? Colors.white : (isDark ? const Color(0xFF8B91A8) : Colors.black54), fontSize: 13, fontWeight: FontWeight.bold))),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMenuButton(String label, String desc, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        tileColor: isDark ? const Color(0xFF1A1E2E) : const Color(0xFFFDFBF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05))
        ),
        leading: Icon(icon, color: const Color(0xFF3D7EFF)),
        title: Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(desc, style: const TextStyle(color: Color(0xFF555D7A), fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF2E3347) : Colors.black12),
        onTap: onTap,
      ),
    );
  }

  void _openEditPlaceModal(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditPlaceModal(placeIndex: index),
    );
  }

  void _showDeleteConfirm(BuildContext context, int index, String name) {
    final provider = context.read<AppProvider>();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('\'$name\' 삭제'),
        content: const Text('이 장소를 내 장소에서 삭제하시겠습니까?'),
        actions: [
          CupertinoDialogAction(child: const Text('취소'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDestructiveAction: true, 
            child: const Text('삭제'), 
            onPressed: () {
              provider.removeFavoritePlace(index);
              Navigator.pop(context);
            }
          ),
        ],
      ),
    );
  }

  void _showClearConfirm(BuildContext context) {
    final provider = context.read<AppProvider>();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('삭제하시겠습니까?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('즐겨찾기, 루틴, 알람이 모두 삭제됩니다.'),
        actions: [
          CupertinoDialogAction(child: const Text('취소'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDestructiveAction: true, 
            child: const Text('삭제하기'), 
            onPressed: () {
              provider.clearAllData();
              Navigator.pop(context);
              setState(() => _activeSubPage = null); 
            }
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('앱 정보'),
        content: const Text('루틴 버스 v1.0.0\nBuild 2026.08.29\nDeveloped by RoutineBus Team'),
        actions: [CupertinoDialogAction(child: const Text('확인'), onPressed: () => Navigator.pop(context))],
      ),
    );
  }

  void _openWidgetPreview(BuildContext context) {
    setState(() => _activeSubPage = 'widget');
  }

  Widget _buildWidgetSimulation(AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: isDark ? const Color(0xFF8B91A8) : Colors.black54, size: 20), onPressed: () => setState(() => _activeSubPage = 'system')),
        title: Text('잠금화면 위젯 설정', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('실시간 미리보기', style: TextStyle(color: isDark ? const Color(0xFF555D7A) : Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                  ? [const Color(0xFF1E3A8A), const Color(0xFF0F1117)]
                  : [const Color(0xFF3D7EFF), const Color(0xFFE0E7FF)],
              ),
              border: Border.all(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 40, left: 0, right: 0,
                  child: Column(
                    children: [
                      Text('8월 29일 금요일', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('09:41', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 56, fontWeight: FontWeight.w200)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20, left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: const Color(0xFF3D7EFF).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.directions_bus, color: Color(0xFF3D7EFF), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('첨단30 | $_mockMin분 후 도착', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('삼익아파트 정류장 · $_mockStop개 전', style: TextStyle(color: isDark ? Colors.white60 : Colors.black45, fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: isDark ? Colors.white38 : Colors.black26, size: 18),
                          onPressed: () {
                            setState(() {
                              _mockMin = _mockMin > 1 ? _mockMin - 1 : 5;
                              _mockStop = _mockStop > 1 ? _mockStop - 1 : 3;
                            });
                            
                            NotificationService().showImmediate(
                              id: 777,
                              title: '🏃 지금 출발하세요!',
                              body: '첨단30 버스가 삼익아파트 정류장에 $_mockMin분 후 도착 예정입니다. 지금 출발하세요! ($_mockStop개 전)',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Text('위젯 옵션', style: TextStyle(color: Color(0xFF555D7A), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1E2E) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05))),
            child: Column(
              children: [
                _buildOptionRow('노선 번호', '첨단30'),
                Divider(height: 24, color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05)),
                _buildOptionRow('위젯 스타일', '간결형'),
              ],
            ),
          ),

          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1E2E) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05))),
            child: Column(
              children: [
                const Text(
                  'iOS(Live Activities)나 Android 잠금화면 위젯은 시스템 권한 설정이 필요할 수 있습니다.',
                  style: TextStyle(color: Color(0xFF8B91A8), fontSize: 12, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D3A8A).withOpacity(0.2),
                      foregroundColor: const Color(0xFF3D7EFF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1D3A8A))),
                    ),
                    onPressed: () {},
                    child: const Text('잠금화면 권한 설정하기', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(String label, String val) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15)),
        Row(
          children: [
            Text(val, style: const TextStyle(color: Color(0xFF3D7EFF), fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: isDark ? const Color(0xFF2E3347) : Colors.black12, size: 16),
          ],
        ),
      ],
    );
  }
}

class _EditPlaceModal extends StatefulWidget {
  final int placeIndex;
  const _EditPlaceModal({required this.placeIndex});

  @override
  State<_EditPlaceModal> createState() => _EditPlaceModalState();
}

class _EditPlaceModalState extends State<_EditPlaceModal> {
  late TextEditingController _aliasController;
  Place? _selectedPlace;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final provider = context.read<AppProvider>();
      if (widget.placeIndex != -1 && widget.placeIndex < provider.favoritePlaces.length) {
        final p = provider.favoritePlaces[widget.placeIndex];
        _aliasController = TextEditingController(text: p.alias ?? p.name);
        _selectedPlace = p;
      } else {
        _aliasController = TextEditingController();
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  void _openLocationSearch() async {
    final result = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PlaceSearchModal(),
    );
    if (result != null) {
      setState(() {
        _selectedPlace = result;
        if (_aliasController.text.isEmpty) {
          _aliasController.text = result.name;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<AppProvider>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.65, 
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1E2E) : const Color(0xFFFDFBF7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('취소', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16)),
                  ),
                  Text(
                    widget.placeIndex == -1 ? '장소 추가' : '장소 수정',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: (_selectedPlace != null && _aliasController.text.isNotEmpty) ? () async {
                      final finalPlace = Place(
                        id: _selectedPlace!.id,
                        name: _selectedPlace!.name,
                        lat: _selectedPlace!.lat,
                        lng: _selectedPlace!.lng,
                        address: _selectedPlace!.address,
                        alias: _aliasController.text,
                      );
                      if (widget.placeIndex == -1) {
                        await provider.addFavoritePlace(finalPlace);
                      } else {
                        await provider.updateFavoritePlace(widget.placeIndex, finalPlace);
                      }
                      if (mounted) Navigator.pop(context);
                    } : null,
                    child: Text(
                      '저장', 
                      style: TextStyle(
                        color: (_selectedPlace != null && _aliasController.text.isNotEmpty) 
                          ? const Color(0xFF3D7EFF) 
                          : (isDark ? Colors.white12 : Colors.black12), 
                        fontSize: 16, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text('장소 별칭', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _aliasController,
                autofocus: widget.placeIndex == -1,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                onChanged: (v) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '예: 우리집, 회사, 운동',
                  hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF242836) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Text('위치 설정', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _openLocationSearch,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF242836) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: _selectedPlace != null ? const Color(0xFF3D7EFF) : (isDark ? Colors.white24 : Colors.black26), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedPlace?.name ?? '위치 검색...',
                          style: TextStyle(
                            color: _selectedPlace != null ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white24 : Colors.black26),
                            fontSize: 14,
                            fontWeight: _selectedPlace != null ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.search, color: Color(0xFF3D7EFF), size: 18),
                    ],
                  ),
                ),
              ),
              if (_selectedPlace != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(_selectedPlace!.address, style: const TextStyle(color: Color(0xFF555D7A), fontSize: 12)),
                ),
              ],
              const SizedBox(height: 100), // 💡 하단 여백을 충분히 주어 더 위로 올림
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceSearchModal extends StatefulWidget {
  const _PlaceSearchModal();

  @override
  State<_PlaceSearchModal> createState() => _PlaceSearchModalState();
}

class _PlaceSearchModalState extends State<_PlaceSearchModal> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFFDFBF7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87), 
                onPressed: () => Navigator.pop(context)
              ),
              Text(
                '위치 검색', 
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: '장소 이름 입력...',
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
              filled: true, 
              fillColor: isDark ? const Color(0xFF242836) : Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.black26),
            ),
            onChanged: (v) => provider.searchPlaces(v),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.isSearching 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final res = provider.searchResults[index];
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text(res['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        subtitle: Text(res['address'], style: const TextStyle(color: Color(0xFF555D7A), fontSize: 12)),
                        onTap: () {
                          final place = Place(
                            id: res['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            name: res['name'],
                            lat: res['lat'],
                            lng: res['lng'],
                            address: res['address'],
                          );
                          Navigator.pop(context, place);
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
