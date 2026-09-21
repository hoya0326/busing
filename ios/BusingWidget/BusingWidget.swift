import WidgetKit
import SwiftUI

// 💡 [수석 개발자] Flutter와 iOS Native Widget 간 데이터 연동
func getWidgetEntry() -> SimpleEntry {
    let prefs = UserDefaults(suiteName: "group.com.example.busing") ?? UserDefaults.standard

    let busName = prefs.string(forKey: "flutter.widget_busName") ?? "정보 없음"
    let remainMin = prefs.string(forKey: "flutter.widget_remainMin") ?? "도착정보없음"
    let stopName = prefs.string(forKey: "flutter.widget_stopName") ?? "대기 중"

    return SimpleEntry(date: Date(), busName: busName, remainMin: remainMin, stopName: stopName)
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), busName: "버스 번호", remainMin: "도착정보없음", stopName: "도착지 및 정류장 대기 중")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(getWidgetEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getWidgetEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let busName: String
    let remainMin: String
    let stopName: String
}

struct BusingWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 12) {
            // 왼쪽 버스 아이콘 박스
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 61/255, green: 126/255, blue: 255/255).opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "bus.fill")
                    .foregroundColor(Color(red: 61/255, green: 126/255, blue: 255/255))
                    .font(.system(size: 20))
            }

            // 중앙 텍스트 영역
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(entry.busName) |")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)

                    if entry.remainMin == "도착정보없음" || entry.remainMin == "-1" || entry.remainMin == "-2" {
                        Text("도착정보없음")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(entry.remainMin)분 후 도착")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }

                Text("\(entry.stopName)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 우측 새로고침 아이콘
            Image(systemName: "arrow.clockwise")
                .foregroundColor(.gray.opacity(0.6))
                .font(.system(size: 16))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(UIColor.systemBackground))
    }
}

@main
struct BusingWidget: Widget {
    let kind: String = "BusingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BusingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("버씽 실시간 안내")
        .description("자주 타는 버스의 실시간 위치와 도착 예정 시간을 홈 화면에서 확인하세요.")
        .supportedFamilies([.systemMedium]) // 💡 가로형(Medium) 위젯 사이즈 전용
    }
}
