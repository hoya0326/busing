import WidgetKit
import SwiftUI

// 💡 [수석 개발자] Flutter와 iOS Native Widget 간 데이터 연동
func getWidgetEntry() -> SimpleEntry {
    let prefs = UserDefaults(suiteName: "group.com.example.busing") ?? UserDefaults.standard

    let count = max(1, prefs.integer(forKey: "flutter.widget_count"))
    var index = prefs.integer(forKey: "flutter.widget_index")
    if index < 0 { index = 0 }
    if index >= count { index = count - 1 }

    let busName = prefs.string(forKey: "flutter.widget_busName_\(index)")
        ?? prefs.string(forKey: "flutter.widget_busName") ?? "대기 중"
    let remainMin = prefs.string(forKey: "flutter.widget_remainMin_\(index)")
        ?? prefs.string(forKey: "flutter.widget_remainMin") ?? "막차시간이 아닙니다"
    let stopName = prefs.string(forKey: "flutter.widget_stopName_\(index)")
        ?? prefs.string(forKey: "flutter.widget_stopName") ?? "18:00 ~ 00:00 사이 가동됩니다"

    return SimpleEntry(date: Date(), count: count, index: index, busName: busName, remainMin: remainMin, stopName: stopName)
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), count: 1, index: 0, busName: "대기 중", remainMin: "막차시간이 아닙니다", stopName: "18:00 ~ 00:00 사이 가동됩니다")
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
    let count: Int
    let index: Int
    let busName: String
    let remainMin: String
    let stopName: String
}

struct BusingWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        let hasPrev = entry.index > 0
        let hasNext = entry.index < entry.count - 1

        VStack(alignment: .leading, spacing: 6) {
            // 상단 헤더: 타이틀 + 좌우 이동 버튼 + 새로고침 아이콘
            HStack(spacing: 4) {
                Text("🚌 버씽 막차알림 정보")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                // 이전 버튼
                Image(systemName: "chevron.left")
                    .foregroundColor(hasPrev ? Color(red: 96/255, green: 165/255, blue: 250/255) : Color.gray.opacity(0.4))
                    .font(.system(size: 12, weight: .bold))

                // 페이지 표시
                Text("\(entry.index + 1)/\(entry.count)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                // 다음 버튼
                Image(systemName: "chevron.right")
                    .foregroundColor(hasNext ? Color(red: 96/255, green: 165/255, blue: 250/255) : Color.gray.opacity(0.4))
                    .font(.system(size: 12, weight: .bold))

                // 새로고침 버튼
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: 13))
                    .padding(.leading, 2)
            }

            Spacer(minLength: 0)

            // 본문 실시간 안내
            if entry.remainMin == "막차시간이 아닙니다" || entry.busName == "대기 중" {
                VStack(alignment: .leading, spacing: 2) {
                    Text("막차시간이 아닙니다")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(entry.stopName.isEmpty ? "18:00 ~ 00:00 사이 가동됩니다" : entry.stopName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
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
            }

            Spacer(minLength: 0)

            Text("\(entry.date, style: .time) 기준 업데이트")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
        .widgetURL(URL(string: "busing://widget_click")) // 💡 위젯 클릭 시 딥링크 전달
    }
}

@main
struct BusingWidget: Widget {
    let kind: String = "BusingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BusingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("버씽 막차알림 정보")
        .description("자주 타는 버스의 실시간 막차 위치와 도착 예정 시간을 홈 화면에서 확인하세요.")
        .supportedFamilies([.systemMedium]) // 💡 가로형(Medium) 위젯 사이즈 전용
    }
}
