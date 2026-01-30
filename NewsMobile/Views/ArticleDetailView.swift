//
//  ArticleDetailView.swift
//  NewsMobile
//
//  Article detail view with full content
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ArticleDetailView: View {
    let article: NewsArticle
    @StateObject private var watchLater = WatchLaterManager.shared
    @StateObject private var tts = TTSManager.shared
    @StateObject private var personalization = PersonalizationEngine.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showWebView = false
    @State private var viewStartTime = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Source and date
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: article.category.icon)
                                .foregroundColor(Color(hex: article.category.color))
                            Text(article.source.name)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        Text(article.timeAgoString)
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)

                    // Title
                    Text(article.title)
                        .font(.title)
                        .fontWeight(.bold)

                    // Sentiment and bias
                    HStack(spacing: 12) {
                        if let sentiment = article.sentiment {
                            SentimentBadge(sentiment: sentiment)
                        }

                        BiasIndicatorBadge(bias: article.source.bias)
                    }

                    // Description
                    if let description = article.rssDescription {
                        Text(description)
                            .font(.body)
                            .lineSpacing(4)
                    }

                    // Entities
                    if let entities = article.entities, !entities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mentioned")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(entities) { entity in
                                    EntityBadge(entity: entity)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            showWebView = true
                        } label: {
                            Label("Read Full Article", systemImage: "safari")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        HStack(spacing: 12) {
                            Button {
                                watchLater.toggle(article)
                            } label: {
                                Label(
                                    watchLater.isInWatchLater(article) ? "Saved" : "Save",
                                    systemImage: watchLater.isInWatchLater(article) ? "bookmark.fill" : "bookmark"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                if tts.isPlaying {
                                    tts.stop()
                                } else {
                                    tts.startBriefing(articles: [article])
                                }
                            } label: {
                                Label(
                                    tts.isPlaying ? "Stop" : "Listen",
                                    systemImage: tts.isPlaying ? "stop.fill" : "speaker.wave.2.fill"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            ShareLink(item: article.link) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 16)
                }
                .padding()
            }
            .navigationTitle("Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showWebView) {
                ArticleWebView(url: article.link)
            }
            .onDisappear {
                let duration = Date().timeIntervalSince(viewStartTime)
                personalization.recordView(article: article, duration: duration)
            }
        }
    }
}

struct SentimentBadge: View {
    let sentiment: SentimentResult

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: sentiment.label.icon)
            Text(sentiment.label.rawValue)
        }
        .font(.caption)
        .foregroundColor(Color(hex: sentiment.label.color))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: sentiment.label.color).opacity(0.15))
        .cornerRadius(8)
    }
}

struct BiasIndicatorBadge: View {
    let bias: SourceBias

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: bias.color))
                .frame(width: 6, height: 6)
            Text(bias.rawValue)
        }
        .font(.caption)
        .foregroundColor(Color(hex: bias.color))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: bias.color).opacity(0.15))
        .cornerRadius(8)
    }
}

struct EntityBadge: View {
    let entity: ExtractedEntity

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: entity.type.icon)
            Text(entity.text)
        }
        .font(.caption)
        .foregroundColor(Color(hex: entity.type.color))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: entity.type.color).opacity(0.1))
        .cornerRadius(8)
    }
}

// Simple flow layout for entities
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: proposal).offsets

        for (subview, offset) in zip(subviews, offsets) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (size: CGSize, offsets: [CGPoint]) {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for size in sizes {
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), offsets)
    }
}

#Preview {
    ArticleDetailView(article: NewsArticle(
        title: "Sample Article Title",
        description: "This is a sample article description for preview purposes.",
        link: URL(string: "https://example.com")!,
        pubDate: Date(),
        source: NewsSource(name: "Test Source", feedURL: URL(string: "https://example.com/feed")!, category: .technology),
        category: .technology
    ))
}
