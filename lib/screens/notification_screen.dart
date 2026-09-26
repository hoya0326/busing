import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../models.dart';
import '../services/notification_service.dart';
import 'dart:ui' as ui;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSearchBanner(appProvider),
          Expanded(
            child: _buildSavedAlarmsList(appProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBanner(AppProvider appProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20, left: 16, right: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1E2E) : const Color(0xFFFDFBF7),
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('막차 알림 설정', style: TextStyle(color: Color(0xFF8B91A8), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _openAlarmSearch(context, appProvider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242836) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('알림을 받을 목적지 검색...', 
                      style: TextStyle(fontSize: 14, color: Color(0xFF555D7A), fontWeight: FontWeight.w500)),
                  ),
                  const Icon(Icons.search, color: Color(0xFF3D7EFF), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAlarmSearch(BuildContext context, AppProvider provider) {
    provider.searchPlaces('');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AlarmSearchLayer(),
    );
  }

  Widget _buildSavedAlarmsList(AppProvider provider) {
    final alarms = provider.destinationAlarms;
    if (alarms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none, size: 48, color: Color(0xFF2E3347)),
            const SizedBox(height: 16),
            const Text('등록된 목적지가 없습니다.', style: TextStyle(color: Color(0xFF555D7A), fontSize: 14)),
            const Text('목적지를 검색해 막차 알림을 추가하세요.', style: TextStyle(color: Color(0xFF555D7A), fontSize: 12)),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                NotificationService().showImmediate(
                  id: 888,
                  title: '🔔 알림 테스트',
                  body: '루틴 버스 알림 시스템이 정상 작동 중입니다.',
                );
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('시스템 알림 테스트하기'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF3D7EFF)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: alarms.length,
      itemBuilder: (context, index) => _buildAlarmCard(alarms[index], provider),
    );
  }

  Widget _buildAlarmCard(DestinationAlarm alarm, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: alarm.isEnabled 
            ? const Color(0xFF3D7EFF).withOpacity(0.3) 
            : (isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05))
        ),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('📍', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alarm.destination.name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(alarm.destination.address, style: const TextStyle(color: Color(0xFF555D7A), fontSize: 12), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF555D7A), size: 18),
                onPressed: () => provider.removeDestinationAlarm(alarm.destination.id),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_bus, size: 16, color: alarm.isEnabled ? const Color(0xFF3D7EFF) : const Color(0xFF555D7A)),
                  const SizedBox(width: 8),
                  Text(alarm.isEnabled ? '실시간 막차 추적 중' : '알림 꺼짐', 
                    style: TextStyle(color: alarm.isEnabled ? const Color(0xFF3D7EFF) : const Color(0xFF555D7A), fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              CupertinoSwitch(
                value: alarm.isEnabled,
                onChanged: (_) => provider.toggleDestinationAlarm(alarm.destination.id),
                activeColor: const Color(0xFF3D7EFF),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => provider.sendTestNotificationForDestination(alarm),
              icon: const Icon(Icons.notification_add, size: 14, color: Color(0xFF3D7EFF)),
              label: const Text('지금 즉시 알림 테스트 보내기', style: TextStyle(fontSize: 12, color: Color(0xFF3D7EFF))),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFF3D7EFF).withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmSearchLayer extends StatefulWidget {
  const _AlarmSearchLayer();

  @override
  State<_AlarmSearchLayer> createState() => _AlarmSearchLayerState();
}

class _AlarmSearchLayerState extends State<_AlarmSearchLayer> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
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
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
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
                        Text('목적지 검색', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),

                  // Search Bar
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
                          hintText: '목적지 검색',
                          hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.2) : Colors.black26),
                          prefixIcon: const Icon(Icons.circle, color: Color(0xFFFF6B6B), size: 10),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          suffixIcon: const Icon(Icons.search, color: Color(0xFF3D7EFF), size: 20),
                        ),
                        onChanged: (v) => provider.searchPlaces(v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search Results
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: provider.searchResults.isEmpty 
                      ? _buildFavorites(provider)
                      : _buildSearchResults(provider),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('검색 결과', style: TextStyle(color: isDark ? const Color(0xFF3D7EFF) : const Color(0xFF3D7EFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: provider.searchResults.length,
            itemBuilder: (context, index) {
              final res = provider.searchResults[index];
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
                    provider.addDestinationAlarm(Place(
                      id: res['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      name: res['name'],
                      lat: res['lat'],
                      lng: res['lng'],
                      address: res['address'],
                    ));
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavorites(AppProvider provider) {
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
            itemCount: provider.favoritePlaces.length,
            itemBuilder: (context, index) {
              final place = provider.favoritePlaces[index];
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  title: Text(place.alias ?? place.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
                  subtitle: Text(place.address, style: TextStyle(color: isDark ? const Color(0xFF8B91A8) : const Color(0xFF555D7A), fontSize: 12), overflow: TextOverflow.ellipsis),
                  onTap: () {
                    provider.addDestinationAlarm(place);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
