//
//  AppIntent.swift
//  BusingWidget
//
//  Created by hoyeong on 9/23/26.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Busing Widget Configuration" }

    @Parameter(title: "Favorite Emoji", default: "🚌")
    var favoriteEmoji: String
}

struct PrevPageIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("Previous Page")

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.example.busing")
        let count = defaults?.integer(forKey: "widget_count") ?? 1
        var index = defaults?.integer(forKey: "widget_index") ?? 0
        index = max(0, index - 1)
        defaults?.set(index, forKey: "widget_index")

        if let dest = defaults?.string(forKey: "widget_destination_\(index)") {
            defaults?.set(dest, forKey: "widget_destination")
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct NextPageIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("Next Page")

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.example.busing")
        let count = defaults?.integer(forKey: "widget_count") ?? 1
        var index = defaults?.integer(forKey: "widget_index") ?? 0
        index = min(count - 1, index + 1)
        defaults?.set(index, forKey: "widget_index")

        if let dest = defaults?.string(forKey: "widget_destination_\(index)") {
            defaults?.set(dest, forKey: "widget_destination")
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct RefreshWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("Refresh Widget")

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
