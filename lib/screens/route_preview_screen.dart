import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../models.dart';

class RoutePreviewScreen extends StatelessWidget {
  const RoutePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final depart = appProvider.departLabel;
    final arrive = appProvider.arriveLabel;
    final List<Place> extras = appProvider.state.extraDestinations;
    final List<int> durations = appProvider.state.segmentDurations;
    final List<double> distances = appProvider.state.segmentDistances;
    
    // 전체 경로 리스트 생성 (이름만)
    final List<String> allStopNames = [depart, ...extras.map((e) => e.name), arrive];
    
    // 총 시간 계산
    final int totalMinutes = durations.isNotEmpty 
        ? durations.reduce((a, b) => a + b) 
        : 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1E2E) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: isDark ? const Color(0xFF8B91A8) : Colors.black54, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('경로 안내 미리보기', 
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${extras.length}개 경유지 포함', 
                      style: TextStyle(color: isDark ? const Color(0xFF555D7A) : Colors.black38, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // 타임라인 리스트
          Expanded(
            child: appProvider.isAnalyzing 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3D7EFF)))
              : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: allStopNames.length,
              itemBuilder: (context, index) {
                final isFirst = index == 0;
                final isLast = index == allStopNames.length - 1;
                final stopName = allStopNames[index];
                
                Color dotColor = const Color(0xFF3D7EFF);
                if (isLast) dotColor = const Color(0xFFFF6B6B);
                else if (!isFirst) dotColor = const Color(0xFFA78BFA);

                // 현재 구간의 데이터 (이전 포인트에서 여기까지 오는데 걸린 정보)
                final int? currentDuration = (index > 0 && index - 1 < durations.length) ? durations[index - 1] : null;
                final double? currentDistance = (index > 0 && index - 1 < distances.length) ? distances[index - 1] : null;

                return IntrinsicHeight(
                  child: Row(
                    children: [
                      // 라인 & 도트
                      Column(
                        children: [
                          const SizedBox(height: 5),
                          Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              color: dotColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: dotColor, width: 2),
                            ),
                            child: Center(
                              child: Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      dotColor.withOpacity(0.5),
                                      (index + 1 == allStopNames.length - 1 ? const Color(0xFFFF6B6B) : const Color(0xFFA78BFA)).withOpacity(0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // 카드
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1A1E2E) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF2E3347) : Colors.black.withOpacity(0.05)),
                              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFirst ? '출발지' : (isLast ? '최종 목적지' : '경유지 ${index}'),
                                  style: TextStyle(color: dotColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  stopName.isEmpty ? '미설정' : stopName,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                                if (!isFirst && currentDuration != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Color(0xFF3D7EFF)),
                                      const SizedBox(width: 4),
                                      Text('+$currentDuration분', style: const TextStyle(color: Color(0xFF3D7EFF), fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 12),
                                      Text('${currentDistance?.toStringAsFixed(1)}km', style: const TextStyle(color: Color(0xFF555D7A), fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 하단 버튼
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1117),
              border: Border(top: BorderSide(color: Color(0xFF2E3347))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('예상 총 소요시간', style: TextStyle(color: Color(0xFF8B91A8), fontSize: 14)),
                    Text('$totalMinutes분', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D7EFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      appProvider.startGuidance();
                      Navigator.pop(context);
                    },
                    child: const Text('지금 안내 시작', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
