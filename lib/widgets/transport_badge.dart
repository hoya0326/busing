import 'package:flutter/material.dart';
import '../models.dart';

/// 💡 [Request 3] Atcha의 도보 뱃지(Badge) UI 포팅
/// 도보일 경우 옅은 회색 배경에 "도보" 텍스트를 보여줍니다.
class TransportBadgeWidget extends StatelessWidget {
  final TransportMode mode;
  final String? label;

  const TransportBadgeWidget({
    super.key,
    required this.mode,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    // 도보(.walk) 모드 처리
    if (mode == TransportMode.walk) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // Atcha 스타일의 회색 톤
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label ?? "도보",
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // 버스나 지하철 등 다른 수단 (필요 시 확장)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: mode == TransportMode.bus ? const Color(0xFF1E3A8A) : Colors.blueGrey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label ?? (mode == TransportMode.bus ? "버스" : "이동"),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
