//
//  BusingWidget.swift
//  BusingWidget
//
//  Created by hoyeong on 9/23/26.
//

import WidgetKit
import SwiftUI
import AppIntents

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), busName: "급행:첨단09", remainMin: "3", stopName: "🚏 광주버스종합터미널 ➔ 조선대학교 (도보 5분)", destination: "조선대학교", count: 1, index: 0)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        return getEntry(configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = getEntry(configuration: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date().addingTimeInterval(60)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func getEntry(configuration: ConfigurationAppIntent) -> SimpleEntry {
        let defaults = UserDefaults(suiteName: "group.com.example.busing")
        let count = max(1, defaults?.integer(forKey: "widget_count") ?? 1)
        var index = defaults?.integer(forKey: "widget_index") ?? 0
        if index < 0 { index = 0 }
        if index >= count { index = count - 1 }

        let busName = defaults?.string(forKey: "widget_busName_\(index)") ?? defaults?.string(forKey: "widget_busName") ?? "데이터 로딩 중"
        let remainMin = defaults?.string(forKey: "widget_remainMin_\(index)") ?? defaults?.string(forKey: "widget_remainMin") ?? "-"
        let stopName = defaults?.string(forKey: "widget_stopName_\(index)") ?? defaults?.string(forKey: "widget_stopName") ?? "현재 위치"
        let destination = defaults?.string(forKey: "widget_destination_\(index)") ?? defaults?.string(forKey: "widget_destination") ?? "목적지"

        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            busName: busName,
            remainMin: remainMin,
            stopName: stopName,
            destination: destination,
            count: count,
            index: index
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let busName: String
    let remainMin: String
    let stopName: String
    let destination: String
    let count: Int
    let index: Int
}

@available(iOS 17.0, *)
struct BusingWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.date)
        let isNightTime = hour >= 5 && hour < 24 // 05:00 ~ 23:59
        let hasValidData = entry.busName != "데이터 로딩 중" && entry.remainMin != "-" && entry.remainMin != "막차시간이 아닙니다" && !entry.busName.isEmpty

        let mainText: String
        let subText: String

        if hasValidData {
            let formattedStopInfo = entry.stopName
            if entry.remainMin == "도착정보없음" || entry.remainMin == "-1" || entry.remainMin == "-2" {
                mainText = "\(entry.busName) | 도착정보없음"
                subText = formattedStopInfo
            } else {
                mainText = "\(entry.busName) | \(entry.remainMin)분 후 도착"
                subText = formattedStopInfo
            }
        } else if !isNightTime {
            mainText = "막차시간이 아닙니다"
            subText = "05:00 ~ 23:59 사이 가동됩니다"
        } else {
            mainText = "실시간 도착 정보 대기 중"
            subText = "\(entry.stopName) ➔ \(entry.destination)"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timeString = "\(dateFormatter.string(from: entry.date)) 기준 업데이트"

        let hasPrev = entry.index > 0
        let hasNext = entry.index < entry.count - 1

        let activeColor = Color(red: 0.38, green: 0.65, blue: 0.98) // #60A5FA
        let disabledColor = Color(red: 0.29, green: 0.33, blue: 0.39) // #4B5563

        return VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 4) {
                Text("버씽 막차알림 정보")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                // Prev Button
                Button(intent: PrevPageIntent()) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(hasPrev ? activeColor : disabledColor)
                }
                .buttonStyle(.plain)
                .disabled(!hasPrev)

                // Page text
                Text("\(entry.index + 1)/\(entry.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                // Next Button
                Button(intent: NextPageIntent()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(hasNext ? activeColor : disabledColor)
                }
                .buttonStyle(.plain)
                .disabled(!hasNext)

                // Refresh Button
                Button(intent: RefreshWidgetIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Main Info
            Text(mainText)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(red: 0.38, green: 0.65, blue: 0.98))
                .lineLimit(1)

            // Sub Info
            Text(subText)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)

            // Footer Time
            Text(timeString)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(12)
        .containerBackground(Color(red: 0.11, green: 0.13, blue: 0.16), for: .widget)
        .widgetURL(URL(string: "busing://guidance"))
    }
}

@available(iOS 17.0, *)
struct BusingWidget: Widget {
    let kind: String = "BusingWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            BusingWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("버씽 막차알림 정보")
        .description("실시간 막차 버스 도착 정보를 확인하세요.")
    }
}
