//
//  LocalNewsService.swift
//  NewsMobile
//
//  Local news based on ZIP code or city
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

@MainActor
class LocalNewsService: ObservableObject {
    static let shared = LocalNewsService()

    @Published var localArticles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var currentLocation: String?

    static let popularCities = [
        "New York", "Los Angeles", "Chicago", "Houston", "Phoenix",
        "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose",
        "Austin", "Jacksonville", "Fort Worth", "Columbus", "Indianapolis",
        "Charlotte", "San Francisco", "Seattle", "Denver", "Boston"
    ]

    private let parser = RSSParser()

    private init() {
        loadLocation()
    }

    func setLocation(zipCode: String) {
        SettingsManager.shared.settings.localNewsZipCode = zipCode
        currentLocation = zipCode
        Task { await fetchLocalNews() }
    }

    func setLocation(city: String) {
        SettingsManager.shared.settings.localNewsLocation = city
        currentLocation = city
        Task { await fetchLocalNews() }
    }

    func clearLocation() {
        SettingsManager.shared.settings.localNewsLocation = nil
        SettingsManager.shared.settings.localNewsZipCode = nil
        currentLocation = nil
        localArticles = []
    }

    private func loadLocation() {
        if let city = SettingsManager.shared.settings.localNewsLocation {
            currentLocation = city
        } else if let zip = SettingsManager.shared.settings.localNewsZipCode {
            currentLocation = zip
        }
    }

    func fetchLocalNews() async {
        guard let location = currentLocation else { return }

        isLoading = true

        let query = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location
        let feedURLString = "https://news.google.com/rss/search?q=\(query)+news&hl=en-US&gl=US&ceid=US:en"

        guard let feedURL = URL(string: feedURLString) else {
            isLoading = false
            return
        }

        let source = NewsSource(
            name: "Local News",
            feedURL: feedURL,
            category: .us,
            bias: .center
        )

        do {
            let (data, _) = try await URLSession.shared.data(from: feedURL)
            let articles = await parser.parse(data: data, source: source)

            // Filter and analyze
            var processedArticles = articles
            let sentimentAnalyzer = SentimentAnalyzer()

            for i in processedArticles.indices {
                processedArticles[i].sentiment = sentimentAnalyzer.analyze(processedArticles[i].title)
            }

            localArticles = processedArticles
        } catch {
            print("Failed to fetch local news: \(error)")
        }

        isLoading = false
    }
}
