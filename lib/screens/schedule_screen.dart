import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../models.dart';

// 사용자의 요일별 루틴 목록을 관리하고 시각화하는 화면입니다.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppProvider>();
    final days = [
      {'short': '월', 'full': '월요일'},
      {'short': '화', 'full': '화요일'},
      {'short': '수', 'full': '수요일'},
      {'short': '목', 'full': '목요일'},
      {'short': '금', 'full': '금요일'},
      {'short': '토', 'full': '토요일'},
      {'short': '일', 'full': '일요일'},
    ];

    return Container(
      color: const Color(0xFFF3F4F6),
      child: Column(
        children: [
          // 상단 헤더 영역: 제목과 요일 선택기
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('내 루틴 시간표', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 24),
                // 가로 스크롤이 가능한 요일 선택 버튼 목록
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: days.map((day) {
                      final bool isSelected = appState.선택된요일 == day['short'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => appState.요일설정(day['short']!),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                            ),
                            child: Text(
                              day['short']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 중앙 루틴 목록 영역
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              children: [
                if (appState.루틴불러오는중)
                  const Center(child: CircularProgressIndicator())
                else if (appState.루틴목록.isEmpty)
                  _buildEmptyState(appState.선택된요일)
                else
                  ...appState.루틴목록.map((routine) => _buildRoutineCard(context, routine, appState)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 루틴 정보가 없을 때 표시할 안내 화면입니다.
  Widget _buildEmptyState(String day) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 64),
          const Icon(Icons.calendar_today, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text('$day요일에 예정된 루틴이 없습니다', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
          const SizedBox(height: 4),
          const Text('+ 버튼을 눌러 새 루틴을 추가하세요', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
        ],
      ),
    );
  }

  // 개별 루틴 정보를 담고 있는 카드 위젯입니다. 활성화 스위치를 포함합니다.
  Widget _buildRoutineCard(BuildContext context, Routine routine, AppProvider state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 시간 표시와 온/오프 스위치
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Text(routine.time, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                      ],
                    ),
                    Switch(
                      value: routine.enabled,
                      onChanged: (_) => state.루틴상태전환(routine.id),
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF3B82F6),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 출발지와 도착지 경로 표시
                Row(
                  children: [
                    Text(routine.from, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward, size: 20, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 12),
                    Text(routine.to, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                  ],
                ),
                const SizedBox(height: 12),
                // 선호하는 버스 정보 안내문
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus, size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      const Text('선호 버스:', style: TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
                      const SizedBox(width: 4),
                      Text(routine.bus, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 루틴이 꺼져있을 때 흐릿하게 만드는 덮개
          if (!routine.enabled)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
