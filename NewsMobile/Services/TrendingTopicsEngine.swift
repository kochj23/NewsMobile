//
//  TrendingTopicsEngine.swift
//  NewsMobile
//
//  Analyzes trending topics across feeds
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import NaturalLanguage

@MainActor
class TrendingTopicsEngine: ObservableObject {
    static let shared = TrendingTopicsEngine()

    @Published var trendingTopics: [TrendingTopic] = []

    private init() {}

    func analyze(articles: [NewsArticle]) {
        var topicCounts: [String: (count: Int, category: NewsCategory?)] = [:]

        for article in articles {
            let topics = extractTopics(from: article.title)
            for topic in topics {
                let current = topicCounts[topic] ?? (0, nil)
                topicCounts[topic] = (current.count + 1, article.category)
            }
        }

        let trending = topicCounts
            .filter { $0.value.count >= 3 }
            .sorted { $0.value.count > $1.value.count }
            .prefix(15)
            .map { TrendingTopic(name: $0.key, articleCount: $0.value.count, category: $0.value.category) }

        trendingTopics = Array(trending)
    }

    private func extractTopics(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text

        var topics: [String] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if let tag = tag {
                switch tag {
                case .personalName, .organizationName, .placeName:
                    let word = String(text[range])
                    if word.count > 2 {
                        topics.append(word)
                    }
                default:
                    break
                }
            }
            return true
        }

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
            if let tag = tag, tag == .noun {
                let word = String(text[range])
                if word.count > 4 && word.first?.isUppercase == true {
                    if !topics.contains(word) {
                        topics.append(word)
                    }
                }
            }
            return true
        }

        return topics
    }
}
