import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart'; // 💡 context.go 사용을 위해 추가
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../models.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final days = ["월", "화", "수", "목", "금", "토", "일"];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // 헤더: 내 루틴 시간표
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            child: Text(
              '내 루틴 시간표',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
          ),

          // 요일 선택 탭
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(days.length, (i) {
                final isSelected = appProvider.selectedDay == days[i];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => appProvider.setSelectedDay(days[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF3D7EFF) : (isDark ? const Color(0xFF1A1E2E) : Colors.black.withOpacity(0.05)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.transparent : (isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05))),
                        ),
                        child: Center(
                          child: Text(
                            days[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF555D7A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 루틴 추가 버튼 (Figma 스펙: 요일 탭 바로 아래 전체 너비)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.1)),
                  backgroundColor: isDark ? const Color(0xFF1A1E2E) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _openAddRoutineModal(context),
                icon: const Icon(Icons.add, color: Color(0xFF8B91A8), size: 18),
                label: const Text('루틴 추가', style: TextStyle(color: Color(0xFF8B91A8), fontWeight: FontWeight.w500)),
              ),
            ),
          ),

          // 루틴 목록
          Expanded(
            child: appProvider.routinesForSelectedDay.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: appProvider.routinesForSelectedDay.length,
                  itemBuilder: (context, index) => _buildRoutineCard(context, appProvider.routinesForSelectedDay[index], appProvider),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1E2E) : Colors.black.withOpacity(0.03), 
              borderRadius: BorderRadius.circular(20), 
              border: Border.all(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05))
            ),
            child: Icon(Icons.calendar_today_outlined, color: isDark ? const Color(0xFF2E3347) : Colors.black26, size: 28),
          ),
          const SizedBox(height: 16),
          Text('등록된 루틴이 없습니다', style: TextStyle(color: isDark ? const Color(0xFF555D7A) : Colors.black38, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, Routine routine, AppProvider appProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (routine.name?.trim().isNotEmpty == true) ? routine.name! : '출근 루틴',
                      style: TextStyle(color: isDark ? const Color(0xFFE8EAF2) : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          routine.time, // 예: "오전 06:00"
                          style: const TextStyle(color: Color(0xFF3D7EFF), fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        CupertinoSwitch(
                          value: routine.enabled,
                          onChanged: (_) => appProvider.toggleRoutine(routine.id),
                          activeColor: const Color(0xFF3D7EFF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF555D7A), size: 20),
                onPressed: () => appProvider.deleteRoutine(routine.id),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3D7EFF), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(routine.from, style: const TextStyle(color: Color(0xFF8B91A8), fontSize: 12), overflow: TextOverflow.ellipsis)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 12, color: Color(0xFF555D7A))),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(routine.to, style: const TextStyle(color: Color(0xFF8B91A8), fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D7EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // 💡 [Figma] 즉시 길안내 시작
                    appProvider.setDepartLabel(routine.from);
                    appProvider.setArriveLabel(routine.to);
                    appProvider.startGuidance();
                    context.go('/'); // 💡 홈 탭으로 자동 전환
                  },
                  child: const Text('길안내', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAddRoutineModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddRoutineModal(),
    );
  }
}

class _AddRoutineModal extends StatefulWidget {
  const _AddRoutineModal();

  @override
  State<_AddRoutineModal> createState() => _AddRoutineModalState();
}

class _AddRoutineModalState extends State<_AddRoutineModal> {
  late TextEditingController _nameController;
  late TextEditingController _fromController;
  late TextEditingController _toController;
  
  late FixedExtentScrollController _ampmController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minController;
  late FixedExtentScrollController _dayController;

  int _ampmIdx = 0; // 0: 오전, 1: 오후
  int _hourIdx = 5; // 6시
  int _minIdx = 0;
  int _dayIdx = 0;
  
  final List<String> _days = ["월", "화", "수", "목", "금", "토", "일"];

  String? _activeSearchField; // 'from' 또는 'to'

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _fromController = TextEditingController();
    _toController = TextEditingController();
    
    // 현재 선택된 요일을 초기값으로 설정
    final currentDay = context.read<AppProvider>().selectedDay;
    _dayIdx = _days.indexOf(currentDay);
    if (_dayIdx == -1) _dayIdx = 0;

    _ampmController = FixedExtentScrollController(initialItem: _ampmIdx);
    _hourController = FixedExtentScrollController(initialItem: _hourIdx);
    _minController = FixedExtentScrollController(initialItem: _minIdx);
    _dayController = FixedExtentScrollController(initialItem: _dayIdx);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _ampmController.dispose();
    _hourController.dispose();
    _minController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // 핸들
            Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: isDark ? const Color(0xFF2E3347) : Colors.black12, borderRadius: BorderRadius.circular(2)))),

            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: TextStyle(color: isDark ? const Color(0xFF8B91A8) : Colors.black54))),
                  Text('루틴 추가', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      final timeStr = '${_ampmIdx == 0 ? "오전" : "오후"} ${(_hourIdx + 1).toString().padLeft(2, '0')}:${_minIdx.toString().padLeft(2, '0')}';
                      context.read<AppProvider>().addRoutine(
                        name: _nameController.text,
                        from: _fromController.text,
                        to: _toController.text,
                        time: timeStr,
                        day: _days[_dayIdx],
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('저장', style: TextStyle(color: Color(0xFF3D7EFF), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text('루틴 이름 (선택)', style: TextStyle(color: isDark ? const Color(0xFF8B91A8) : Colors.black54, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildField(_nameController, '예: 출근 루틴, 학교 가는 날', isDark),
                    
                    const SizedBox(height: 24),
                    Text('출발시간 및 요일', style: TextStyle(color: isDark ? const Color(0xFF8B91A8) : Colors.black54, fontSize: 12)),
                    const SizedBox(height: 12),
                    
                    Container(
                      height: 180,
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF111418) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(24)),
                      child: Row(
                        children: [
                          _buildPicker(_days, _dayController, (i) => setState(() => _dayIdx = i), isDark, loop: false),
                          _buildPicker(['오전', '오후'], _ampmController, (i) => setState(() => _ampmIdx = i), isDark, loop: false),
                          _buildPicker(List.generate(12, (i) => '${i + 1}'), _hourController, (i) => setState(() => _hourIdx = i), isDark),
                          Center(child: Text(':', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold))),
                          _buildPicker(List.generate(60, (i) => i.toString().padLeft(2, '0')), _minController, (i) => setState(() => _minIdx = i), isDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text('위치 설정', style: TextStyle(color: isDark ? const Color(0xFF8B91A8) : Colors.black54, fontSize: 12)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF242836) : Colors.black.withOpacity(0.02), 
                        borderRadius: BorderRadius.circular(24), 
                        border: Border.all(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05))
                      ),
                      child: Column(
                        children: [
                          _buildLocationInput(appProvider, _fromController, '출발지', const Color(0xFF3D7EFF), 'from', isDark),
                          Divider(height: 1, color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05)),
                          _buildLocationInput(appProvider, _toController, '도착지', const Color(0xFFFF6B6B), 'to', isDark),
                        ],
                      ),
                    ),

                    if (_activeSearchField != null && appProvider.searchResults.isNotEmpty)
                      _buildSearchResults(appProvider, isDark),

                    const SizedBox(height: 100), // 여백 확보
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(AppProvider appProvider, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242836) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF3D7EFF).withOpacity(0.3) : const Color(0xFF3D7EFF).withOpacity(0.1)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appProvider.searchResults.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05)),
          itemBuilder: (context, index) {
            final res = appProvider.searchResults[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: const Text('📍', style: TextStyle(fontSize: 18)),
              title: Text(res['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text(res['address'], style: const TextStyle(color: Color(0xFF555D7A), fontSize: 12), overflow: TextOverflow.ellipsis),
              onTap: () {
                if (_activeSearchField == 'from') {
                  _fromController.text = res['name'];
                } else if (_activeSearchField == 'to') {
                  _toController.text = res['name'];
                }
                setState(() {
                  _activeSearchField = null;
                });
                appProvider.searchPlaces(''); // 검색결과 초기화
                FocusScope.of(context).unfocus();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, bool isDark) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? const Color(0xFF555D7A) : Colors.black26),
        filled: true, fillColor: isDark ? const Color(0xFF242836) : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildLocationInput(AppProvider appProvider, TextEditingController controller, String label, Color dotColor, String fieldId, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: dotColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          TextField(
            controller: controller,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
            onChanged: (val) {
              setState(() {
                _activeSearchField = fieldId;
              });
              appProvider.searchPlaces(val);
            },
            onTap: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _activeSearchField = fieldId;
                });
                appProvider.searchPlaces(controller.text);
              }
            },
            decoration: InputDecoration(
              hintText: '위치 검색 또는 직접 입력', 
              hintStyle: TextStyle(color: isDark ? const Color(0xFF555D7A) : Colors.black26), 
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker(List<String> items, FixedExtentScrollController controller, ValueChanged<int> onSelect, bool isDark, {bool loop = true}) {
    return Expanded(
      child: CupertinoPicker(
        itemExtent: 44,
        scrollController: controller,
        onSelectedItemChanged: onSelect,
        looping: loop,
        children: items.map((s) => Center(child: Text(s, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.w500)))).toList(),
      ),
    );
  }
}
