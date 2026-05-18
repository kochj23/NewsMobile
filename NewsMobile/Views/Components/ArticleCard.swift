//
//  ArticleCard.swift
//  NewsMobile
//
//  Article card component
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ArticleCard: View {
    let article: NewsArticle
    @StateObject private var watchLater = WatchLaterManager.shared
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Source and time
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: article.category.icon)
                        .foregroundColor(Color(hex: article.category.color))
                    Text(article.source.name)
                        .fontWeight(.medium)
                }
                .font(.caption)

                Spacer()

                Text(article.timeAgoString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Title
            Text(article.title)
                .font(.headline)
                .lineLimit(3)
                .foregroundColor(sentimentColor)

            // Description
            if let description = article.rssDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Badges
            HStack(spacing: 8) {
                if settings.settings.showSentimentColors, let sentiment = article.sentiment {
                    HStack(spacing: 2) {
                        Image(systemName: sentiment.label.icon)
                        Text(sentiment.label.rawValue)
                    }
                    .font(.caption2)
                    .foregroundColor(Color(hex: sentiment.label.color))
                }

                if settings.settings.showBiasIndicators {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(Color(hex: article.source.bias.color))
                            .frame(width: 6, height: 6)
                        Text(article.source.bias.rawValue)
                    }
                    .font(.caption2)
                    .foregroundColor(Color(hex: article.source.bias.color))
                }

                Spacer()

                // Bookmark button
                Button {
                    watchLater.toggle(article)
                } label: {
                    Image(systemName: watchLater.isInWatchLater(article) ? "bookmark.fill" : "bookmark")
                        .foregroundColor(watchLater.isInWatchLater(article) ? .blue : .gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var sentimentColor: Color {
        guard settings.settings.showSentimentColors, let sentiment = article.sentiment else {
            return .primary
        }

        switch sentiment.label {
        case .positive: return Color(hex: "2ECC71")
        case .negative: return Color(hex: "E74C3C")
        case .neutral: return .primary
        }
    }
}

#Preview {
    ArticleCard(article: NewsArticle(
        title: "Sample Article Title That Can Be Quite Long",
        description: "This is a sample description for preview purposes. It can be multiple lines long.",
        link: URL(string: "https://example.com")!,
        pubDate: Date(),
        source: NewsSource(name: "Test Source", feedURL: URL(string: "https://example.com/feed")!, category: .technology),
        category: .technology
    ))
    .environmentObject(SettingsManager.shared)
    .padding()
}
