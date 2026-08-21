import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppProvider>();
    _nameController = TextEditingController(text: appState.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppProvider>();

    return Container(
      color: const Color(0xFFF3F4F6),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
            color: const Color(0xFF111827),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          ),
                          child: const Icon(Icons.person, size: 36, color: Colors.white),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(color: Color(0xFF39FF14), shape: BoxShape.circle),
                            child: const Center(child: Text('✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF111111)))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Name / Location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_editingName)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    autofocus: true,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF1F5F9)),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      fillColor: const Color(0xFF1F2937),
                                      filled: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF374151))),
                                    ),
                                    onSubmitted: (val) {
                                      appState.setUserName(val);
                                      setState(() => _editingName = false);
                                    },
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    appState.setUserName(_nameController.text);
                                    setState(() => _editingName = false);
                                  },
                                  icon: const Icon(Icons.check, size: 14, color: Color(0xFF111111)),
                                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF39FF14)),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Text(appState.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF1F5F9))),
                                IconButton(
                                  onPressed: () => setState(() => _editingName = true),
                                  icon: const Icon(Icons.edit, size: 14, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          const Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Color(0xFF39FF14)),
                              SizedBox(width: 4),
                              Text('광주광역시, 대한민국', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats Row
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      _buildStatItem('저장된 경로', '4', true),
                      _buildStatItem('이번 달 탑승', '23회', true),
                      _buildStatItem('절약한 시간', '1.2h', false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Saved Places
          _buildSection('내 장소', showAdd: true, child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: [
              _buildPlaceCard(Icons.home, '집', '광주 광산구 수완동 123', const Color(0xFF3B82F6)),
              _buildPlaceCard(Icons.school, '학교', '광주 동구 필문대로 309', const Color(0xFF8B5CF6)),
              _buildPlaceCard(Icons.book, '학원', '광주 광산구 수완로 45', const Color(0xFFF59E0B)),
              _buildPlaceCard(Icons.fitness_center, '헬스장', '광주 광산구 수완지구', const Color(0xFF10B981)),
            ],
          )),

          // Quick Toggles
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]),
            child: Column(
              children: [
                _buildToggleItem(Icons.notifications, '막차 알림', '출발 10분 전 자동 알림', const Color(0xFFEFF6FF), const Color(0xFF3B82F6), appState.notifOn, (v) => appState.setNotifOn(v)),
                const Divider(height: 1, indent: 64),
                _buildToggleItem(Icons.dark_mode, '다크 모드', '앱 전체 테마 변경', const Color(0xFFEEF2FF), const Color(0xFF6366F1), appState.darkMode, (v) => appState.setDarkMode(v)),
              ],
            ),
          ),

          // Menu List
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]),
            child: Column(
              children: [
                _buildMenuItem(Icons.smartphone, '위젯 설정', '홈 화면 위젯 구성', const Color(0xFF10B981)),
                const Divider(height: 1, indent: 64),
                _buildMenuItem(Icons.shield, '개인정보 보호', '데이터 및 권한 관리', const Color(0xFFF59E0B)),
                const Divider(height: 1, indent: 64),
                _buildMenuItem(Icons.help, '도움말 / 문의', '자주 묻는 질문 · 1:1 문의', const Color(0xFF64748B)),
                const Divider(height: 1, indent: 64),
                _buildMenuItem(Icons.star, '앱 평가하기', '스토어에서 리뷰 작성', const Color(0xFFEF4444)),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Routine Bus v1.0.0', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFFD1D5DB))),
          ),

          // Logout
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]),
            child: ListTile(
              leading: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle), child: const Icon(Icons.logout, size: 18, color: Color(0xFFEF4444))),
              title: const Text('로그아웃', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool hasBorder) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(right: BorderSide(color: hasBorder ? const Color(0xFF374151) : Colors.transparent))),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFFF1F5F9))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, {required Widget child, bool showAdd = false}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                if (showAdd)
                  GestureDetector(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(999)),
                      child: const Row(children: [Icon(Icons.add, size: 12, color: Color(0xFF374151)), SizedBox(width: 4), Text('추가', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)))]),
                    ),
                  ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: child),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(IconData icon, String label, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF3F4F6))),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(IconData icon, String label, String sub, Color bg, Color color, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, size: 18, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF39FF14),
            activeTrackColor: const Color(0xFF111827),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, String sub, Color color) {
    return ListTile(
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle), child: Icon(icon, size: 18, color: color)),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
      trailing: const Icon(Icons.chevron_right, size: 16, color: Color(0xFFD1D5DB)),
      onTap: () {},
    );
  }
}
