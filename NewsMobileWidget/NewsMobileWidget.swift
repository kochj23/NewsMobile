//
//  NewsMobileWidget.swift
//  NewsMobileWidget
//
//  Created by Jordan Koch
//

import WidgetKit
import SwiftUI

// MARK: - iOS 17 Compatibility Extension
extension View {
    @ViewBuilder
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            background(backgroundView)
        }
    }
}

// MARK: - Widget Entry
struct NewsEntry: TimelineEntry {
    let date: Date
    let headlines: [HeadlineItem]
    let weather: WeatherData?
    let trendingTopic: String?
}

struct HeadlineItem: Identifiable {
    let id = UUID()
    let title: String
    let source: String
    let category: String
    let sentiment: String // positive, negative, neutral
}

struct WeatherData {
    let temperature: Int
    let condition: String
    let icon: String
}

// MARK: - Timeline Provider
struct NewsProvider: TimelineProvider {
    func placeholder(in context: Context) -> NewsEntry {
        NewsEntry(
            date: Date(),
            headlines: [
                HeadlineItem(title: "Breaking news headline here...", source: "News Source", category: "World", sentiment: "neutral")
            ],
            weather: WeatherData(temperature: 72, condition: "Sunny", icon: "sun.max.fill"),
            trendingTopic: "Technology"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NewsEntry) -> Void) {
        let entry = NewsEntry(
            date: Date(),
            headlines: loadCachedHeadlines(),
            weather: loadCachedWeather(),
            trendingTopic: loadTrendingTopic()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NewsEntry>) -> Void) {
        let currentDate = Date()
        let entry = NewsEntry(
            date: currentDate,
            headlines: loadCachedHeadlines(),
            weather: loadCachedWeather(),
            trendingTopic: loadTrendingTopic()
        )

        // Refresh every 30 minutes for news
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadCachedHeadlines() -> [HeadlineItem] {
        let userDefaults = UserDefaults(suiteName: "group.com.jordankoch.newsmobile")

        if let data = userDefaults?.data(forKey: "cachedHeadlines"),
           let headlines = try? JSONDecoder().decode([[String: String]].self, from: data) {
            return headlines.prefix(5).map { dict in
                HeadlineItem(
                    title: dict["title"] ?? "News Headline",
                    source: dict["source"] ?? "Unknown",
                    category: dict["category"] ?? "General",
                    sentiment: dict["sentiment"] ?? "neutral"
                )
            }
        }

        return [
            HeadlineItem(title: "Tap to see latest news", source: "NewsMobile", category: "General", sentiment: "neutral")
        ]
    }

    private func loadCachedWeather() -> WeatherData? {
        let userDefaults = UserDefaults(suiteName: "group.com.jordankoch.newsmobile")
        guard let temp = userDefaults?.integer(forKey: "weatherTemp"),
              let condition = userDefaults?.string(forKey: "weatherCondition") else {
            return WeatherData(temperature: 72, condition: "Clear", icon: "sun.max.fill")
        }
        return WeatherData(
            temperature: temp,
            condition: condition,
            icon: weatherIcon(for: condition)
        )
    }

    private func loadTrendingTopic() -> String? {
        let userDefaults = UserDefaults(suiteName: "group.com.jordankoch.newsmobile")
        return userDefaults?.string(forKey: "trendingTopic") ?? "Technology"
    }

    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case let c where c.contains("sun") || c.contains("clear"):
            return "sun.max.fill"
        case let c where c.contains("cloud"):
            return "cloud.fill"
        case let c where c.contains("rain"):
            return "cloud.rain.fill"
        case let c where c.contains("snow"):
            return "cloud.snow.fill"
        case let c where c.contains("thunder") || c.contains("storm"):
            return "cloud.bolt.fill"
        default:
            return "sun.max.fill"
        }
    }
}

// MARK: - Widget Views
struct NewsWidgetEntryView: View {
    var entry: NewsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallNewsWidget(entry: entry)
        case .systemMedium:
            MediumNewsWidget(entry: entry)
        case .systemLarge:
            LargeNewsWidget(entry: entry)
        default:
            SmallNewsWidget(entry: entry)
        }
    }
}

struct SmallNewsWidget: View {
    let entry: NewsEntry

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "newspaper.fill")
                        .foregroundColor(.white)
                    Text("News")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    if let weather = entry.weather {
                        HStack(spacing: 2) {
                            Image(systemName: weather.icon)
                                .font(.caption)
                            Text("\(weather.temperature)°")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                    }
                }

                if let headline = entry.headlines.first {
                    Text(headline.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
        .widgetBackground(Color.clear)
    }
}

struct MediumNewsWidget: View {
    let entry: NewsEntry

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "newspaper.fill")
                        .foregroundColor(.white)
                    Text("NewsMobile")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    if let weather = entry.weather {
                        HStack(spacing: 4) {
                            Image(systemName: weather.icon)
                            Text("\(weather.temperature)°")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                    }

                    if let trending = entry.trendingTopic {
                        Text("#\(trending)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                }

                ForEach(entry.headlines.prefix(2)) { headline in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(sentimentColor(headline.sentiment))
                            .frame(width: 6, height: 6)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(headline.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(2)

                            Text(headline.source)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .widgetBackground(Color.clear)
    }

    private func sentimentColor(_ sentiment: String) -> Color {
        switch sentiment {
        case "positive": return .green
        case "negative": return .red
        default: return .yellow
        }
    }
}

struct LargeNewsWidget: View {
    let entry: NewsEntry

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Image(systemName: "newspaper.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("NewsMobile")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    if let weather = entry.weather {
                        HStack(spacing: 4) {
                            Image(systemName: weather.icon)
                            Text("\(weather.temperature)°")
                            Text(weather.condition)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                    }
                }

                if let trending = entry.trendingTopic {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.yellow)
                        Text("Trending: \(trending)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                // Headlines
                ForEach(entry.headlines.prefix(4)) { headline in
                    NewsHeadlineRow(headline: headline)
                }

                Spacer()

                HStack {
                    Text("Last updated: \(entry.date, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))

                    Spacer()

                    Text("Tap to open app")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding()
        }
        .widgetBackground(Color.clear)
    }
}

struct NewsHeadlineRow: View {
    let headline: HeadlineItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack {
                Circle()
                    .fill(sentimentColor(headline.sentiment))
                    .frame(width: 8, height: 8)
            }
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(headline.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack {
                    Text(headline.source)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))

                    Text("•")
                        .foregroundColor(.white.opacity(0.5))

                    Text(headline.category)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()
        }
    }

    private func sentimentColor(_ sentiment: String) -> Color {
        switch sentiment {
        case "positive": return .green
        case "negative": return .red
        default: return .yellow
        }
    }
}

// MARK: - Widget Configuration
@main
struct NewsMobileWidget: Widget {
    let kind: String = "NewsMobileWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NewsProvider()) { entry in
            NewsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("News Headlines")
        .description("Stay updated with the latest news and weather")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

