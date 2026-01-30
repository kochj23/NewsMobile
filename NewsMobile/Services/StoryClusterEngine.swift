//
//  StoryClusterEngine.swift
//  NewsMobile
//
//  Groups related articles from multiple sources
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import NaturalLanguage

@MainActor
class StoryClusterEngine: ObservableObject {
    static let shared = StoryClusterEngine()

    @Published var clusters: [StoryCluster] = []

    private init() {}

    func clusterArticles(_ articles: [NewsArticle]) -> [StoryCluster] {
        var clusters: [StoryCluster] = []
        var processedIds: Set<UUID> = []

        for article in articles {
            guard !processedIds.contains(article.id) else { continue }

            let relatedArticles = findRelatedArticles(to: article, in: articles, excluding: processedIds)

            if relatedArticles.count >= 2 {
                var clusterArticles = [article] + relatedArticles
                clusterArticles.sort { $0.pubDate > $1.pubDate }

                let topic = extractMainTopic(from: clusterArticles)
                var cluster = StoryCluster(topic: topic, articles: clusterArticles)
                cluster.perspectives = analyzePerspectives(clusterArticles)

                clusters.append(cluster)

                processedIds.insert(article.id)
                processedIds.formUnion(relatedArticles.map { $0.id })
            }
        }

        self.clusters = clusters
        return clusters
    }

    private func findRelatedArticles(to article: NewsArticle, in articles: [NewsArticle], excluding: Set<UUID>) -> [NewsArticle] {
        let articleKeywords = extractKeywords(from: article.title)

        return articles.filter { other in
            guard other.id != article.id,
                  !excluding.contains(other.id),
                  other.source.name != article.source.name else {
                return false
            }

            let otherKeywords = extractKeywords(from: other.title)
            let commonKeywords = articleKeywords.intersection(otherKeywords)

            return commonKeywords.count >= 2
        }
    }

    private func extractKeywords(from text: String) -> Set<String> {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text.lowercased()

        var keywords: Set<String> = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
            if let tag = tag, tag == .noun || tag == .verb {
                let word = String(text[range]).lowercased()
                if word.count > 3 {
                    keywords.insert(word)
                }
            }
            return true
        }

        return keywords
    }

    private func extractMainTopic(from articles: [NewsArticle]) -> String {
        var wordCounts: [String: Int] = [:]

        for article in articles {
            let keywords = extractKeywords(from: article.title)
            for keyword in keywords {
                wordCounts[keyword, default: 0] += 1
            }
        }

        let topWords = wordCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key.capitalized }

        return topWords.joined(separator: " ")
    }

    private func analyzePerspectives(_ articles: [NewsArticle]) -> PerspectiveBreakdown {
        let leftArticles = articles.filter { $0.source.bias == .left || $0.source.bias == .leanLeft }
        let centerArticles = articles.filter { $0.source.bias == .center }
        let rightArticles = articles.filter { $0.source.bias == .right || $0.source.bias == .leanRight }

        let leftPerspective = leftArticles.first?.rssDescription
        let centerPerspective = centerArticles.first?.rssDescription
        let rightPerspective = rightArticles.first?.rssDescription

        // Extract common facts
        let allKeywords = articles.flatMap { extractKeywords(from: $0.title) }
        let keywordCounts = Dictionary(grouping: allKeywords, by: { $0 }).mapValues { $0.count }
        let sharedFacts = keywordCounts.filter { $0.value >= articles.count / 2 }.keys.map { $0.capitalized }

        return PerspectiveBreakdown(
            leftPerspective: leftPerspective,
            centerPerspective: centerPerspective,
            rightPerspective: rightPerspective,
            sharedFacts: Array(sharedFacts.prefix(5)),
            contentions: []
        )
    }
}
