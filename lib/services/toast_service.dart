import 'dart:async';
import 'package:flutter/material.dart';

/// 💡 [Request 10] Atcha 스타일의 비동기 타이머 기반 토스트 (Asynchronous Toast)
/// 여러 번 연속 호출해도 이전 토스트를 안전하게 제거하고 가장 마지막 메시지만 유지합니다.
class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  OverlayEntry? _currentEntry;
  Timer? _autoHideTimer;

  void show(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    // 1. 이미 떠 있는 토스트가 있다면 즉시 제거 (겹침 방지)
    dismiss();

    // 2. 새로운 토스트 생성
    _currentEntry = OverlayEntry(
      builder: (context) => _ToastWidget(message: message),
    );

    // 3. 화면에 띄우기
    Overlay.of(context).insert(_currentEntry!);

    // 4. Atcha 스타일 비동기 대기: 설정된 시간 후 자동 숨김
    _autoHideTimer = Timer(duration, () {
      dismiss();
    });
  }

  void dismiss() {
    // 유저가 강제로 닫거나 덮어씌워질 경우 타이머 취소
    _autoHideTimer?.cancel();
    _autoHideTimer = null;

    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
    }
  }
}

class _ToastWidget extends StatelessWidget {
  final String message;
  const _ToastWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
