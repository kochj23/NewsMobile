//
//  CustomFeedManager.swift
//  NewsMobile
//
//  Manages user-added custom RSS feeds
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

@MainActor
class CustomFeedManager: ObservableObject {
    static let shared = CustomFeedManager()

    @Published var customArticles: [NewsArticle] = []
    @Published var isLoading = false

    private let parser = RSSParser()

    static let suggestedFeeds: [(name: String, url: String, category: NewsCategory)] = [
        ("Hacker News", "https://hnrss.org/frontpage", .technology),
        ("Reddit Technology", "https://www.reddit.com/r/technology/.rss", .technology),
        ("MacRumors", "https://feeds.macrumors.com/MacRumors-All", .technology),
        ("9to5Mac", "https://9to5mac.com/feed/", .technology),
        ("Wired", "https://www.wired.com/feed/rss", .technology),
        ("Nature News", "https://www.nature.com/nature.rss", .science),
        ("NASA", "https://www.nasa.gov/rss/dyn/breaking_news.rss", .science),
    ]

    private init() {}

    func addFeed(name: String, url: URL, category: NewsCategory) {
        var settings = SettingsManager.shared.settings
        guard !settings.customFeeds.contains(where: { $0.url == url }) else { return }
        settings.customFeeds.append(CustomRSSFeed(name: name, url: url, category: category))
        SettingsManager.shared.settings = settings
        Task { await fetchAllCustomFeeds() }
    }

    func removeFeed(id: UUID) {
        var settings = SettingsManager.shared.settings
        settings.customFeeds.removeAll { $0.id == id }
        SettingsManager.shared.settings = settings
    }

    func toggleFeed(id: UUID, enabled: Bool) {
        var settings = SettingsManager.shared.settings
        if let index = settings.customFeeds.firstIndex(where: { $0.id == id }) {
            settings.customFeeds[index].isEnabled = enabled
            SettingsManager.shared.settings = settings
        }
    }

    func fetchAllCustomFeeds() async {
        let feeds = SettingsManager.shared.settings.customFeeds.filter { $0.isEnabled }
        guard !feeds.isEmpty else {
            customArticles = []
            return
        }

        isLoading = true
        var allArticles: [NewsArticle] = []

        await withTaskGroup(of: (UUID, [NewsArticle]).self) { group in
            for feed in feeds {
                group.addTask {
                    let articles = await self.fetchFeed(feed)
                    return (feed.id, articles)
                }
            }

            for await (feedId, articles) in group {
                allArticles.append(contentsOf: articles)

                // Update article count
                var settings = SettingsManager.shared.settings
                if let index = settings.customFeeds.firstIndex(where: { $0.id == feedId }) {
                    settings.customFeeds[index].articleCount = articles.count
                    settings.customFeeds[index].lastFetchDate = Date()
                    SettingsManager.shared.settings = settings
                }
            }
        }

        allArticles.sort { $0.pubDate > $1.pubDate }
        customArticles = allArticles
        isLoading = false
    }

    private func fetchFeed(_ feed: CustomRSSFeed) async -> [NewsArticle] {
        let source = NewsSource(
            name: feed.name,
            feedURL: feed.url,
            category: feed.category,
            bias: .unknown
        )

        do {
            let (data, _) = try await URLSession.shared.data(from: feed.url)
            return await parser.parse(data: data, source: source)
        } catch {
            print("Failed to fetch custom feed \(feed.name): \(error)")
            return []
        }
    }

    func validateFeedURL(_ url: URL) async -> Bool {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let testSource = NewsSource(name: "Test", feedURL: url, category: .topStories)
            let articles = await parser.parse(data: data, source: testSource)
            return !articles.isEmpty
        } catch {
            return false
        }
    }
}
