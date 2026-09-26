import 'package:flutter/material.dart';
import '../models.dart';

// 사용자와 상호작용이 가능한 지도를 그리는 위젯입니다.
class InteractiveMap extends StatelessWidget {
  final List<MapPin> pins;
  final PinType? pendingType;
  final Function(double, double) onTap;

  const InteractiveMap({
    super.key,
    required this.pins,
    this.pendingType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        // 선택 대기 상태일 때만 좌표 연산을 수행합니다.
        if (pendingType == null) return;
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset localOffset = box.globalToLocal(details.globalPosition);
        onTap(
          (localOffset.dx / box.size.width) * 390,
          (localOffset.dy / box.size.height) * 440,
        );
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: MapPainter(pins: pins, pendingType: pendingType),
      ),
    );
  }
}

// 캔버스에 도로, 건물, 핀 등을 직접 그리는 도구입니다.
class MapPainter extends CustomPainter {
  final List<MapPin> pins;
  final PinType? pendingType;

  MapPainter({required this.pins, this.pendingType});

  @override
  void paint(Canvas canvas, Size size) {
    // 화면 크기에 맞게 좌표 비율을 계산합니다.
    final double scaleX = size.width / 390;
    final double scaleY = size.height / 440;

    // 배경(땅) 그리기
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1A1A2A),
    );

    // 건물 블록 그리기 데이터
    final blocks = [
      [6, 6, 74, 52], [88, 6, 56, 52], [152, 6, 80, 52], [240, 6, 60, 52], [308, 6, 74, 52],
      [6, 66, 74, 38], [88, 66, 56, 38], [240, 66, 60, 38], [308, 66, 74, 38],
      [6, 112, 74, 50], [88, 112, 56, 50], [240, 112, 60, 50], [308, 112, 74, 50],
      [6, 170, 74, 42], [88, 170, 56, 42], [240, 170, 60, 42], [308, 170, 74, 42],
      [6, 220, 74, 36], [88, 220, 56, 36], [240, 220, 60, 36], [308, 220, 74, 36],
      [6, 264, 74, 42], [88, 264, 56, 42], [152, 264, 80, 42], [240, 264, 60, 42], [308, 264, 74, 42],
      [6, 314, 74, 42], [88, 314, 56, 42], [152, 314, 80, 42], [240, 314, 60, 42], [308, 314, 74, 42],
      [6, 364, 74, 68], [88, 364, 56, 68], [152, 364, 80, 68], [240, 364, 60, 68], [308, 364, 74, 68],
    ];

    for (int i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final color = i % 3 == 0 ? const Color(0xFF222236) : i % 3 == 1 ? const Color(0xFF1E1E30) : const Color(0xFF232338);
      canvas.drawRRect(
        RRect.fromLTRBR(b[0] * scaleX, b[1] * scaleY, (b[0] + b[2]) * scaleX, (b[1] + b[3]) * scaleY, const Radius.circular(3)),
        Paint()..color = color,
      );
    }

    // 도로 격자 그리기
    final roadPaint = Paint()..color = const Color(0xFF2E2E46);
    for (var y in [58, 106, 162, 212, 256, 306, 356]) {
      canvas.drawRect(Rect.fromLTWH(0, y * scaleY, size.width, 8 * scaleY), roadPaint);
    }
    for (var x in [80, 144, 232, 300]) {
      canvas.drawRect(Rect.fromLTWH(x * scaleX, 0, 8 * scaleX, size.height), roadPaint);
    }

    // 큰길(중앙선 포함) 그리기
    final boulevardPaint = Paint()..color = const Color(0xFF353550);
    canvas.drawRect(Rect.fromLTWH(0, 210 * scaleY, size.width, 12 * scaleY), boulevardPaint);
    canvas.drawRect(Rect.fromLTWH(144 * scaleX, 0, 12 * scaleX, size.height), boulevardPaint);

    final dashPaint = Paint()
      ..color = const Color(0xFF4A4A6A)
      ..strokeWidth = 1;
    _drawDashedLine(canvas, Offset(0, 216 * scaleY), Offset(size.width, 216 * scaleY), dashPaint, scaleX);
    _drawDashedLine(canvas, Offset(150 * scaleX, 0), Offset(150 * scaleX, size.height), dashPaint, scaleY);

    // 경로선(출발지에서 도착지까지) 그리기
    final depart = pins.firstWhere((p) => p.type == PinType.depart, orElse: () => MapPin(x: 162, y: 240, type: PinType.depart));
    final arrive = pins.cast<MapPin?>().firstWhere((p) => p?.type == PinType.arrive, orElse: () => null);

    if (arrive != null) {
      final path = Path()
        ..moveTo(depart.x * scaleX, depart.y * scaleY)
        ..lineTo(depart.x * scaleX, (depart.y + arrive.y) / 2 * scaleY)
        ..lineTo(arrive.x * scaleX, (depart.y + arrive.y) / 2 * scaleY)
        ..lineTo(arrive.x * scaleX, arrive.y * scaleY);

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.blue.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9 * scaleX
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF60A5FA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5 * scaleX
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // 지도 탭 유도 강조 효과
    if (pendingType != null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = (pendingType == PinType.depart ? Colors.blue : Colors.red).withOpacity(0.06),
      );
    }

    // 지점 표시 핀(출발/도착) 그리기
    _drawDepartPin(canvas, depart.x * scaleX, depart.y * scaleY, scaleX, scaleY);
    if (arrive != null) {
      _drawArrivePin(canvas, arrive.x * scaleX, arrive.y * scaleY, scaleX, scaleY);
    }

    // 하단 페이드 아웃 효과
    final Rect rect = Rect.fromLTRB(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.55, 1.0],
      colors: [const Color(0xFF1A1A2A).withOpacity(0), const Color(0xFF1A1A2A).withOpacity(0.75)],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  // 점선을 그리는 내부 함수입니다.
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double scale) {
    double dashWidth = 14 * scale;
    double dashSpace = 9 * scale;
    double distance = (end - start).distance;
    double currentDistance = 0;
    while (currentDistance < distance) {
      canvas.drawLine(
        start + (end - start) * (currentDistance / distance),
        start + (end - start) * ((currentDistance + dashWidth) / distance),
        paint,
      );
      currentDistance += dashWidth + dashSpace;
    }
  }

  // 출발지 핀 아이콘과 문구를 그립니다.
  void _drawDepartPin(Canvas canvas, double x, double y, double sx, double sy) {
    canvas.drawCircle(Offset(x, y), 30 * sx, Paint()..color = const Color(0xFF3B82F6).withOpacity(0.28));
    canvas.drawCircle(Offset(x, y), 11 * sx, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(x, y), 8 * sx, Paint()..color = const Color(0xFF3B82F6));
    canvas.drawCircle(Offset(x, y), 4 * sx, Paint()..color = Colors.white);

    final rect = Rect.fromCenter(center: Offset(x, y - 33 * sy), width: 72 * sx, height: 26 * sy);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(13 * sx)), Paint()..color = const Color(0xFF111111));
    
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '출발',
        style: TextStyle(color: Color(0xFF39FF14), fontSize: 11, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 33 * sy - textPainter.height / 2));

    canvas.drawLine(Offset(x, y - 20 * sy), Offset(x, y - 12 * sy), Paint()..color = const Color(0xFF111111)..strokeWidth = 2);
  }

  // 도착지 핀 아이콘과 문구를 그립니다.
  void _drawArrivePin(Canvas canvas, double x, double y, double sx, double sy) {
    canvas.drawCircle(Offset(x, y), 13 * sx, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(x, y), 9 * sx, Paint()..color = const Color(0xFFDC2626));
    canvas.drawCircle(Offset(x, y), 4 * sx, Paint()..color = Colors.white);

    final rect = Rect.fromCenter(center: Offset(x, y - 35 * sy), width: 72 * sx, height: 26 * sy);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(13 * sx)), Paint()..color = const Color(0xFF111111));

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '도착',
        style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 35 * sy - textPainter.height / 2));

    canvas.drawLine(Offset(x, y - 22 * sy), Offset(x, y - 14 * sy), Paint()..color = const Color(0xFF111111)..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) => true;
}
