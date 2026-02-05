//
//  WidgetDataManager.swift
//  NewsMobile
//
//  Created by Jordan Koch
//  Manages data sharing between the main app and widget
//

import Foundation
import WidgetKit

/// Manages data synchronization between the main app and the widget extension
final class WidgetDataManager {

    // MARK: - Singleton
    static let shared = WidgetDataManager()

    // MARK: - Constants
    private let appGroupIdentifier = "group.com.jordankoch.newsmobile"

    private enum Keys {
        static let cachedHeadlines = "cachedHeadlines"
        static let weatherTemp = "weatherTemp"
        static let weatherCondition = "weatherCondition"
        static let trendingTopic = "trendingTopic"
        static let lastUpdateTime = "widgetLastUpdateTime"
    }

    // MARK: - Properties
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Public Methods

    /// Updates the widget with the latest headlines
    /// - Parameter headlines: Array of headline dictionaries with title, source, category, sentiment
    func updateHeadlines(_ headlines: [[String: String]]) {
        if let data = try? JSONEncoder().encode(headlines) {
            sharedDefaults?.set(data, forKey: Keys.cachedHeadlines)
        }
        sharedDefaults?.set(Date(), forKey: Keys.lastUpdateTime)
        refreshWidget()
    }

    /// Updates the widget with current weather data
    /// - Parameters:
    ///   - temperature: Current temperature
    ///   - condition: Weather condition string (e.g., "Sunny", "Cloudy")
    func updateWeather(temperature: Int, condition: String) {
        sharedDefaults?.set(temperature, forKey: Keys.weatherTemp)
        sharedDefaults?.set(condition, forKey: Keys.weatherCondition)
        refreshWidget()
    }

    /// Updates the trending topic shown in the widget
    /// - Parameter topic: The trending topic string
    func updateTrendingTopic(_ topic: String) {
        sharedDefaults?.set(topic, forKey: Keys.trendingTopic)
        refreshWidget()
    }

    /// Refreshes all widget timelines to show updated data
    func refreshWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Clears all widget data
    func clearWidgetData() {
        sharedDefaults?.removeObject(forKey: Keys.cachedHeadlines)
        sharedDefaults?.removeObject(forKey: Keys.weatherTemp)
        sharedDefaults?.removeObject(forKey: Keys.weatherCondition)
        sharedDefaults?.removeObject(forKey: Keys.trendingTopic)
        sharedDefaults?.removeObject(forKey: Keys.lastUpdateTime)
        refreshWidget()
    }

    // MARK: - Convenience Methods

    /// Updates widget with articles from the news aggregator
    /// - Parameter articles: Array of NewsArticle objects
    func updateFromArticles(_ articles: [NewsArticle]) {
        let headlines = articles.prefix(10).map { article -> [String: String] in
            return [
                "title": article.title,
                "source": article.source,
                "category": article.category.rawValue,
                "sentiment": article.sentiment?.rawValue ?? "neutral"
            ]
        }
        updateHeadlines(headlines)
    }
}

// MARK: - NewsArticle Extension for Widget

extension WidgetDataManager {

    /// Call this when news is refreshed
    func onNewsRefreshed(articles: [NewsArticle], weather: (temp: Int, condition: String)?, trending: String?) {
        updateFromArticles(articles)

        if let weather = weather {
            updateWeather(temperature: weather.temp, condition: weather.condition)
        }

        if let trending = trending {
            updateTrendingTopic(trending)
        }
    }
}

// MARK: - Placeholder Types (if not already defined)

// These should match your existing models - adjust as needed
struct NewsArticle {
    let title: String
    let source: String
    let category: NewsCategory
    let sentiment: Sentiment?

    enum NewsCategory: String {
        case world, business, technology, sports, entertainment, science, health, general
    }

    enum Sentiment: String {
        case positive, negative, neutral
    }
}
