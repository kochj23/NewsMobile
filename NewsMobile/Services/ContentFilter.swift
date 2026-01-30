//
//  ContentFilter.swift
//  NewsMobile
//
//  Filters advertisements and sponsored content
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

class ContentFilter {
    private let adKeywords = [
        "sponsored", "advertisement", "ad:", "[ad]", "promoted",
        "partner content", "paid content", "affiliate", "deal alert",
        "promo code", "discount code", "save now", "limited time offer",
        "buy now", "shop now", "exclusive offer", "special offer"
    ]

    private let clickbaitPatterns = [
        "you won't believe",
        "shocking",
        "mind-blowing",
        "what happens next",
        "doctors hate",
        "one weird trick",
        "number \\d+ will",
        "\\d+ things you",
        "this is why",
        "here's why"
    ]

    private let suspiciousSources = [
        "outbrain", "taboola", "revcontent", "content.ad",
        "mgid", "zergnet", "around the web"
    ]

    func filter(_ articles: [NewsArticle]) -> [NewsArticle] {
        let settings = SettingsManager.shared.settings

        return articles.filter { article in
            let title = article.title.lowercased()
            let description = article.rssDescription?.lowercased() ?? ""
            let source = article.source.name.lowercased()

            // Check for ad keywords
            if settings.filterAds {
                for keyword in adKeywords {
                    if title.contains(keyword) || description.contains(keyword) {
                        return false
                    }
                }

                // Check suspicious sources
                for suspicious in suspiciousSources {
                    if source.contains(suspicious) {
                        return false
                    }
                }
            }

            // Check for clickbait
            if settings.filterClickbait {
                for pattern in clickbaitPatterns {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                        let range = NSRange(title.startIndex..., in: title)
                        if regex.firstMatch(in: title, options: [], range: range) != nil {
                            return false
                        }
                    }
                }
            }

            // Check excluded sources
            if settings.excludedSources.contains(where: { source.contains($0.lowercased()) }) {
                return false
            }

            return true
        }
    }

    func isAdvertisement(_ article: NewsArticle) -> Bool {
        let title = article.title.lowercased()
        let description = article.rssDescription?.lowercased() ?? ""

        for keyword in adKeywords {
            if title.contains(keyword) || description.contains(keyword) {
                return true
            }
        }

        return false
    }

    func isClickbait(_ article: NewsArticle) -> Bool {
        let title = article.title.lowercased()

        for pattern in clickbaitPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(title.startIndex..., in: title)
                if regex.firstMatch(in: title, options: [], range: range) != nil {
                    return true
                }
            }
        }

        return false
    }
}
