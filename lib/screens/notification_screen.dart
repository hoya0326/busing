import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// 앱의 알림 기능을 시각적으로 보여주는 화면입니다. 잠금 화면 알림 위젯을 모사합니다.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 배경에 세 가지 색상의 그라데이션을 적용합니다.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF581C87),
            Color(0xFF312E81),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── 잠금 화면용 알림 카드 ──
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상단 행: 앱 아이콘과 이름, 시간
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)
                                    ],
                                  ),
                                  child: const Icon(Icons.directions_bus, size: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '루틴 버스',
                                  style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9)),
                                ),
                              ],
                            ),
                            Text(
                              '방금',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 핵심 알림 문구
                        const Text(
                          '학원 가기 위해 출발할 시간입니다!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        // 출발까지 남은 시간 강조
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF34D399),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF34D399).withOpacity(0.5), blurRadius: 8, spreadRadius: 2)
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '3분 후 출발',
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 상세 정보 영역 (버스 번호, 도착 시간 등)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(Icons.directions_bus, '버스 번호', '수완03', const Color(0xFF3B82F6)),
                              const SizedBox(height: 12),
                              _buildDetailRow(Icons.access_time, '정류장 도착', '6분 후', const Color(0xFFF59E0B)),
                              const SizedBox(height: 12),
                              _buildDetailRow(Icons.navigation_outlined, '도보 시간', '정류장까지 3분', const Color(0xFF10B981)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 최적 타이밍 강조 배지
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF34D399).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              const Text(
                                '최적 타이밍 - 지금 출발하세요!',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFD1FAE5)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 아이콘과 라벨, 값을 보여주는 작은 정보 행 위젯입니다.
  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
