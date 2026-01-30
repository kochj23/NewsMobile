//
//  PersonalizationEngine.swift
//  NewsMobile
//
//  AI-powered personalization based on reading habits
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

@MainActor
class PersonalizationEngine: ObservableObject {
    static let shared = PersonalizationEngine()

    @Published var personalizedArticles: [NewsArticle] = []
    @Published private(set) var profile = UserPreferenceProfile()

    private let profileKey = "UserPreferenceProfile"

    private init() {
        loadProfile()
    }

    func recordView(article: NewsArticle, duration: TimeInterval) {
        guard SettingsManager.shared.settings.enablePersonalization else { return }

        profile.viewedArticleIds.insert(article.id)
        profile.readDuration[article.id] = duration

        // Update category preference
        let categoryWeight = min(duration / 60.0, 1.0) * 0.1
        profile.categoryPreferences[article.category, default: 0.5] += categoryWeight

        // Update source preference
        let sourceWeight = min(duration / 60.0, 1.0) * 0.1
        profile.sourcePreferences[article.source.name, default: 0.5] += sourceWeight

        // Extract and weight topics
        if let entities = article.entities {
            for entity in entities {
                let topicWeight = min(duration / 60.0, 1.0) * 0.05
                profile.topicInterests[entity.text, default: 0.0] += topicWeight
            }
        }

        normalizePreferences()
        saveProfile()
    }

    func updateFromFetch(articles: [NewsArticle]) {
        guard SettingsManager.shared.settings.enablePersonalization else {
            personalizedArticles = articles
            return
        }

        let scored = articles.map { article -> (NewsArticle, Double) in
            var score = 0.0

            // Category score
            score += profile.categoryPreferences[article.category, default: 0.5] * 0.4

            // Source score
            score += profile.sourcePreferences[article.source.name, default: 0.5] * 0.3

            // Topic score
            if let entities = article.entities {
                let topicScore = entities.reduce(0.0) { sum, entity in
                    sum + profile.topicInterests[entity.text, default: 0.0]
                }
                score += min(topicScore, 1.0) * 0.2
            }

            // Recency score
            let hoursOld = Date().timeIntervalSince(article.pubDate) / 3600
            let recencyScore = max(0, 1 - (hoursOld / 24))
            score += recencyScore * 0.1

            return (article, score)
        }

        personalizedArticles = scored
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    private func normalizePreferences() {
        // Normalize category preferences
        let maxCategory = profile.categoryPreferences.values.max() ?? 1.0
        if maxCategory > 1.0 {
            for key in profile.categoryPreferences.keys {
                profile.categoryPreferences[key]! /= maxCategory
            }
        }

        // Normalize source preferences
        let maxSource = profile.sourcePreferences.values.max() ?? 1.0
        if maxSource > 1.0 {
            for key in profile.sourcePreferences.keys {
                profile.sourcePreferences[key]! /= maxSource
            }
        }

        // Normalize topic interests
        let maxTopic = profile.topicInterests.values.max() ?? 1.0
        if maxTopic > 1.0 {
            for key in profile.topicInterests.keys {
                profile.topicInterests[key]! /= maxTopic
            }
        }
    }

    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }

    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserPreferenceProfile.self, from: data) {
            profile = decoded
        }
    }

    func resetProfile() {
        profile = UserPreferenceProfile()
        saveProfile()
    }
}
