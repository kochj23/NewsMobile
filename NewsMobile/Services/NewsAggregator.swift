//
//  NewsAggregator.swift
//  NewsMobile
//
//  Aggregates news from multiple RSS sources
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
class NewsAggregator: ObservableObject {
    static let shared = NewsAggregator()

    @Published var articles: [NewsArticle] = []
    @Published var articlesByCategory: [NewsCategory: [NewsArticle]] = [:]
    @Published var isLoading = false
    @Published var breakingNews: NewsArticle?
    @Published var lastRefresh: Date?

    private let parser = RSSParser()
    private let sentimentAnalyzer = SentimentAnalyzer()
    private let entityExtractor = EntityExtractor()
    private let contentFilter = ContentFilter()

    let sources: [NewsSource] = [
        // Top Stories
        NewsSource(name: "Associated Press", feedURL: URL(string: "https://feedx.net/rss/ap.xml")!, category: .topStories, bias: .center, reliability: 0.95),
        NewsSource(name: "Reuters", feedURL: URL(string: "https://feedx.net/rss/reuters.xml")!, category: .topStories, bias: .center, reliability: 0.95),
        NewsSource(name: "NPR", feedURL: URL(string: "https://feeds.npr.org/1001/rss.xml")!, category: .topStories, bias: .leanLeft, reliability: 0.9),

        // Disney
        NewsSource(name: "Disney Parks Blog", feedURL: URL(string: "https://disneyparks.disney.go.com/blog/feed/")!, category: .disney, bias: .center, reliability: 0.9),
        NewsSource(name: "D23", feedURL: URL(string: "https://d23.com/feed/")!, category: .disney, bias: .center, reliability: 0.9),
        NewsSource(name: "Disney News", feedURL: URL(string: "https://news.google.com/rss/search?q=Disney&hl=en-US&gl=US&ceid=US:en")!, category: .disney, bias: .center, reliability: 0.8),

        // US News
        NewsSource(name: "NY Times US", feedURL: URL(string: "https://rss.nytimes.com/services/xml/rss/nyt/US.xml")!, category: .us, bias: .leanLeft, reliability: 0.9),

        // World
        NewsSource(name: "BBC World", feedURL: URL(string: "https://feeds.bbci.co.uk/news/world/rss.xml")!, category: .world, bias: .center, reliability: 0.9),
        NewsSource(name: "The Guardian", feedURL: URL(string: "https://www.theguardian.com/world/rss")!, category: .world, bias: .leanLeft, reliability: 0.85),

        // Business
        NewsSource(name: "CNBC", feedURL: URL(string: "https://search.cnbc.com/rs/search/combinedcms/view.xml?partnerId=wrss01&id=100003114")!, category: .business, bias: .center, reliability: 0.85),

        // Technology
        NewsSource(name: "TechCrunch", feedURL: URL(string: "https://techcrunch.com/feed/")!, category: .technology, bias: .center, reliability: 0.85),
        NewsSource(name: "Ars Technica", feedURL: URL(string: "https://feeds.arstechnica.com/arstechnica/index")!, category: .technology, bias: .center, reliability: 0.9),
        NewsSource(name: "The Verge", feedURL: URL(string: "https://www.theverge.com/rss/index.xml")!, category: .technology, bias: .center, reliability: 0.85),

        // Science
        NewsSource(name: "Science Daily", feedURL: URL(string: "https://www.sciencedaily.com/rss/all.xml")!, category: .science, bias: .center, reliability: 0.9),

        // Health
        NewsSource(name: "Medical News Today", feedURL: URL(string: "https://www.medicalnewstoday.com/rss/featured.xml")!, category: .health, bias: .center, reliability: 0.85),

        // Sports
        NewsSource(name: "ESPN", feedURL: URL(string: "https://www.espn.com/espn/rss/news")!, category: .sports, bias: .center, reliability: 0.85),

        // Entertainment
        NewsSource(name: "Variety", feedURL: URL(string: "https://variety.com/feed/")!, category: .entertainment, bias: .center, reliability: 0.85),

        // Politics
        NewsSource(name: "Politico", feedURL: URL(string: "https://rss.politico.com/politics-news.xml")!, category: .politics, bias: .center, reliability: 0.85),
        NewsSource(name: "The Hill", feedURL: URL(string: "https://thehill.com/feed/")!, category: .politics, bias: .center, reliability: 0.85),
    ]

    private init() {}

    func fetchAllNews() async {
        isLoading = true

        var allArticles: [NewsArticle] = []

        await withTaskGroup(of: [NewsArticle].self) { group in
            for source in sources {
                group.addTask {
                    await self.fetchFeed(from: source)
                }
            }

            for await articles in group {
                allArticles.append(contentsOf: articles)
            }
        }

        // Filter content
        let settings = SettingsManager.shared.settings
        if settings.filterAds || settings.filterClickbait {
            allArticles = contentFilter.filter(allArticles)
        }

        // Analyze sentiment and extract entities
        for i in allArticles.indices {
            allArticles[i].sentiment = sentimentAnalyzer.analyze(allArticles[i].title)
            allArticles[i].entities = entityExtractor.extract(from: allArticles[i].title)
        }

        // Sort by date
        allArticles.sort { $0.pubDate > $1.pubDate }

        // Check for breaking news
        if let latestArticle = allArticles.first,
           latestArticle.pubDate > Date().addingTimeInterval(-3600),
           isBreakingNews(latestArticle) {
            breakingNews = latestArticle
        }

        // Group by category
        var byCategory: [NewsCategory: [NewsArticle]] = [:]
        for category in NewsCategory.allCases {
            byCategory[category] = allArticles.filter { $0.category == category }
        }

        articles = allArticles
        articlesByCategory = byCategory
        lastRefresh = Date()
        isLoading = false

        // Check keyword alerts
        KeywordAlertManager.shared.checkAlerts(against: allArticles)

        // Update personalization
        PersonalizationEngine.shared.updateFromFetch(articles: allArticles)

        // Update trending topics
        TrendingTopicsEngine.shared.analyze(articles: allArticles)
    }

    private func fetchFeed(from source: NewsSource) async -> [NewsArticle] {
        do {
            let (data, _) = try await URLSession.shared.data(from: source.feedURL)
            return await parser.parse(data: data, source: source)
        } catch {
            print("Failed to fetch \(source.name): \(error)")
            return []
        }
    }

    private func isBreakingNews(_ article: NewsArticle) -> Bool {
        let title = article.title.lowercased()
        let breakingKeywords = ["breaking", "just in", "developing", "urgent", "alert"]
        return breakingKeywords.contains { title.contains($0) }
    }

    func articles(for category: NewsCategory) -> [NewsArticle] {
        articlesByCategory[category] ?? []
    }

    func refresh() async {
        await fetchAllNews()
    }
}
