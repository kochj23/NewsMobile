//
//  NewsModels.swift
//  NewsMobile
//
//  Core data models for news aggregation
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - News Category

enum NewsCategory: String, CaseIterable, Codable, Identifiable {
    case topStories = "Top Stories"
    case us = "US"
    case world = "World"
    case business = "Business"
    case technology = "Technology"
    case science = "Science"
    case health = "Health"
    case sports = "Sports"
    case entertainment = "Entertainment"
    case politics = "Politics"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .topStories: return "star.fill"
        case .us: return "flag.fill"
        case .world: return "globe"
        case .business: return "chart.line.uptrend.xyaxis"
        case .technology: return "desktopcomputer"
        case .science: return "atom"
        case .health: return "heart.fill"
        case .sports: return "sportscourt.fill"
        case .entertainment: return "film.fill"
        case .politics: return "building.columns.fill"
        }
    }

    var color: String {
        switch self {
        case .topStories: return "FF6B6B"
        case .us: return "4ECDC4"
        case .world: return "45B7D1"
        case .business: return "96CEB4"
        case .technology: return "9B59B6"
        case .science: return "3498DB"
        case .health: return "E74C3C"
        case .sports: return "2ECC71"
        case .entertainment: return "F39C12"
        case .politics: return "1ABC9C"
        }
    }
}

// MARK: - Source Bias

enum SourceBias: String, Codable {
    case left = "Left"
    case leanLeft = "Lean Left"
    case center = "Center"
    case leanRight = "Lean Right"
    case right = "Right"
    case unknown = "Unknown"

    var color: String {
        switch self {
        case .left: return "3498DB"
        case .leanLeft: return "5DADE2"
        case .center: return "9B59B6"
        case .leanRight: return "E67E22"
        case .right: return "E74C3C"
        case .unknown: return "95A5A6"
        }
    }
}

// MARK: - News Source

struct NewsSource: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let feedURL: URL
    let category: NewsCategory
    let bias: SourceBias
    let reliability: Double

    init(name: String, feedURL: URL, category: NewsCategory, bias: SourceBias = .unknown, reliability: Double = 0.8) {
        self.id = UUID()
        self.name = name
        self.feedURL = feedURL
        self.category = category
        self.bias = bias
        self.reliability = reliability
    }
}

// MARK: - News Article

struct NewsArticle: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let rssDescription: String?
    let link: URL
    let pubDate: Date
    let source: NewsSource
    let category: NewsCategory
    let imageURL: URL?

    // ML-derived properties
    var sentiment: SentimentResult?
    var entities: [ExtractedEntity]?
    var isBreaking: Bool

    init(
        title: String,
        description: String?,
        link: URL,
        pubDate: Date,
        source: NewsSource,
        category: NewsCategory,
        imageURL: URL? = nil,
        isBreaking: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.rssDescription = description
        self.link = link
        self.pubDate = pubDate
        self.source = source
        self.category = category
        self.imageURL = imageURL
        self.isBreaking = isBreaking
    }

    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: pubDate, relativeTo: Date())
    }

    static func == (lhs: NewsArticle, rhs: NewsArticle) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sentiment

struct SentimentResult: Codable, Hashable {
    let score: Double
    let label: SentimentLabel

    enum SentimentLabel: String, Codable {
        case positive = "Positive"
        case negative = "Negative"
        case neutral = "Neutral"

        var color: String {
            switch self {
            case .positive: return "2ECC71"
            case .negative: return "E74C3C"
            case .neutral: return "95A5A6"
            }
        }

        var icon: String {
            switch self {
            case .positive: return "arrow.up.circle.fill"
            case .negative: return "arrow.down.circle.fill"
            case .neutral: return "minus.circle.fill"
            }
        }
    }
}

// MARK: - Entity

struct ExtractedEntity: Codable, Hashable, Identifiable {
    let id: UUID
    let text: String
    let type: EntityType

    init(text: String, type: EntityType) {
        self.id = UUID()
        self.text = text
        self.type = type
    }

    enum EntityType: String, Codable {
        case person = "Person"
        case organization = "Organization"
        case place = "Place"

        var icon: String {
            switch self {
            case .person: return "person.fill"
            case .organization: return "building.2.fill"
            case .place: return "mappin.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .person: return "3498DB"
            case .organization: return "9B59B6"
            case .place: return "2ECC71"
            }
        }
    }
}

// MARK: - Story Cluster

struct StoryCluster: Identifiable {
    let id: UUID
    let topic: String
    var articles: [NewsArticle]
    var perspectives: PerspectiveBreakdown?

    var sourceCount: Int {
        Set(articles.map { $0.source.name }).count
    }

    var articleCount: Int {
        articles.count
    }

    init(topic: String, articles: [NewsArticle]) {
        self.id = UUID()
        self.topic = topic
        self.articles = articles
    }
}

struct PerspectiveBreakdown {
    let leftPerspective: String?
    let centerPerspective: String?
    let rightPerspective: String?
    let sharedFacts: [String]
    let contentions: [String]
}

// MARK: - Watch Later

struct WatchLaterItem: Codable, Identifiable {
    let id: UUID
    let article: NewsArticle
    let addedDate: Date
    var isRead: Bool

    init(article: NewsArticle) {
        self.id = UUID()
        self.article = article
        self.addedDate = Date()
        self.isRead = false
    }
}

// MARK: - Keyword Alert

struct KeywordAlert: Codable, Identifiable {
    let id: UUID
    var keyword: String
    var isEnabled: Bool
    var notifyOnMatch: Bool
    var matchCount: Int
    var lastMatchDate: Date?

    init(keyword: String) {
        self.id = UUID()
        self.keyword = keyword
        self.isEnabled = true
        self.notifyOnMatch = true
        self.matchCount = 0
        self.lastMatchDate = nil
    }
}

// MARK: - Custom Feed

struct CustomRSSFeed: Codable, Identifiable {
    let id: UUID
    var name: String
    var url: URL
    var category: NewsCategory
    var isEnabled: Bool
    var lastFetchDate: Date?
    var articleCount: Int

    init(name: String, url: URL, category: NewsCategory) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.category = category
        self.isEnabled = true
        self.lastFetchDate = nil
        self.articleCount = 0
    }
}

// MARK: - Trending Topic

struct TrendingTopic: Identifiable, Hashable {
    let id: UUID
    let name: String
    let articleCount: Int
    let category: NewsCategory?

    init(name: String, articleCount: Int, category: NewsCategory? = nil) {
        self.id = UUID()
        self.name = name
        self.articleCount = articleCount
        self.category = category
    }
}

// MARK: - Weather

struct WeatherData {
    let temperature: Double
    let condition: String
    let icon: String
    let location: String
    let humidity: Int
    let feelsLike: Double
}

// MARK: - Settings

struct NewsMobileSettings: Codable {
    var darkModeEnabled: Bool
    var showSentimentColors: Bool
    var showBiasIndicators: Bool
    var showBreakingNewsAlerts: Bool
    var enableAudioBriefings: Bool
    var speechRate: SpeechRate
    var fontSize: FontSize
    var enablePersonalization: Bool
    var enableBackgroundRefresh: Bool
    var refreshInterval: Int
    var enableNotifications: Bool
    var enableWeatherWidget: Bool
    var localNewsLocation: String?
    var localNewsZipCode: String?
    var enableICloudSync: Bool
    var filterAds: Bool
    var filterClickbait: Bool
    var keywordAlerts: [KeywordAlert]
    var customFeeds: [CustomRSSFeed]
    var excludedSources: [String]

    init() {
        self.darkModeEnabled = true
        self.showSentimentColors = true
        self.showBiasIndicators = true
        self.showBreakingNewsAlerts = true
        self.enableAudioBriefings = true
        self.speechRate = .normal
        self.fontSize = .medium
        self.enablePersonalization = true
        self.enableBackgroundRefresh = true
        self.refreshInterval = 15
        self.enableNotifications = true
        self.enableWeatherWidget = true
        self.localNewsLocation = nil
        self.localNewsZipCode = nil
        self.enableICloudSync = true
        self.filterAds = true
        self.filterClickbait = true
        self.keywordAlerts = []
        self.customFeeds = []
        self.excludedSources = []
    }

    enum SpeechRate: String, Codable, CaseIterable {
        case slow = "Slow"
        case normal = "Normal"
        case fast = "Fast"

        var rate: Float {
            switch self {
            case .slow: return 0.4
            case .normal: return 0.5
            case .fast: return 0.6
            }
        }
    }

    enum FontSize: String, Codable, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        case extraLarge = "Extra Large"

        var scaleFactor: CGFloat {
            switch self {
            case .small: return 0.9
            case .medium: return 1.0
            case .large: return 1.15
            case .extraLarge: return 1.3
            }
        }
    }
}

// MARK: - User Preference Profile

struct UserPreferenceProfile: Codable {
    var categoryPreferences: [NewsCategory: Double]
    var sourcePreferences: [String: Double]
    var topicInterests: [String: Double]
    var viewedArticleIds: Set<UUID>
    var readDuration: [UUID: TimeInterval]

    init() {
        self.categoryPreferences = [:]
        self.sourcePreferences = [:]
        self.topicInterests = [:]
        self.viewedArticleIds = []
        self.readDuration = [:]
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
