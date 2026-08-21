import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RootLayout extends StatelessWidget {
  final Widget child;

  const RootLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Stack(
        children: [
          Positioned.fill(
            child: child,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomTabBar(currentPath: location),
          ),
        ],
      ),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  final String currentPath;

  const _BottomTabBar({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'path': '/', 'label': '홈', 'icon': Icons.home_outlined},
      {'path': '/schedule', 'label': '일정', 'icon': Icons.calendar_today_outlined},
      {'path': '/notification', 'label': '알림', 'icon': Icons.notifications_none_outlined},
      {'path': '/profile', 'label': '프로필', 'icon': Icons.person_outline},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.07))),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems.map((item) {
          final bool isActive = currentPath == item['path'];
          final IconData icon = item['icon'] as IconData;

          return InkWell(
            onTap: () => context.go(item['path'] as String),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF111827) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 17,
                      color: isActive ? const Color(0xFF39FF14) : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
