//
//  StoryClusterView.swift
//  NewsMobile
//
//  Multi-source story comparison
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct StoryClusterView: View {
    let cluster: StoryCluster
    @State private var selectedArticleIndex = 0
    @State private var selectedArticle: NewsArticle?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "square.stack.3d.up")
                                .foregroundColor(.cyan)
                            Text("Multi-Source Story")
                                .foregroundColor(.cyan)
                        }
                        .font(.subheadline.weight(.semibold))

                        Text(cluster.topic)
                            .font(.title)
                            .fontWeight(.bold)

                        Text("\(cluster.sourceCount) sources • \(cluster.articleCount) articles")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cyan.opacity(0.1))
                    .cornerRadius(12)

                    // Source selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(cluster.articles.enumerated()), id: \.element.id) { index, article in
                                SourceChip(
                                    source: article.source,
                                    isSelected: index == selectedArticleIndex
                                ) {
                                    selectedArticleIndex = index
                                }
                            }
                        }
                    }

                    // Selected article
                    if selectedArticleIndex < cluster.articles.count {
                        let article = cluster.articles[selectedArticleIndex]

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(article.source.name)
                                    .fontWeight(.semibold)

                                Spacer()

                                BiasIndicatorBadge(bias: article.source.bias)
                            }

                            Text(article.title)
                                .font(.headline)

                            if let description = article.rssDescription {
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }

                            Button {
                                selectedArticle = article
                            } label: {
                                Label("Read Full Article", systemImage: "arrow.up.right")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    // Perspective breakdown
                    if let perspectives = cluster.perspectives {
                        PerspectiveSection(perspectives: perspectives)
                    }
                }
                .padding()
            }
            .navigationTitle("Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
        }
    }
}

struct SourceChip: View {
    let source: NewsSource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: source.bias.color))
                    .frame(width: 8, height: 8)
                Text(source.name)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.cyan.opacity(0.2) : Color(.tertiarySystemBackground))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct PerspectiveSection: View {
    let perspectives: PerspectiveBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Perspective Analysis")
                .font(.headline)

            HStack(alignment: .top, spacing: 12) {
                if let left = perspectives.leftPerspective {
                    PerspectiveCard(title: "Left", content: left, color: .blue)
                }

                if let center = perspectives.centerPerspective {
                    PerspectiveCard(title: "Center", content: center, color: .purple)
                }

                if let right = perspectives.rightPerspective {
                    PerspectiveCard(title: "Right", content: right, color: .red)
                }
            }

            if !perspectives.sharedFacts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shared Facts")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green)

                    ForEach(perspectives.sharedFacts, id: \.self) { fact in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(fact)
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
}

struct PerspectiveCard: View {
    let title: String
    let content: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(color)

            Text(content)
                .font(.caption)
                .lineLimit(4)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    StoryClusterView(cluster: StoryCluster(topic: "Sample Topic", articles: []))
}
