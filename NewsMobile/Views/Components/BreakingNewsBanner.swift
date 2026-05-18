//
//  BreakingNewsBanner.swift
//  NewsMobile
//
//  Breaking news alert banner
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct BreakingNewsBanner: View {
    let article: NewsArticle
    let onDismiss: () -> Void
    @State private var showDetail = false

    var body: some View {
        VStack(spacing: 0) {
            // Banner
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                        Text("BREAKING NEWS")
                    }
                    .font(.caption.weight(.heavy))
                    .foregroundColor(.white)

                    Spacer()

                    Button {
                        withAnimation {
                            onDismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text(article.source.name)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Button {
                        showDetail = true
                    } label: {
                        Text("Read More")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color.red)

            Spacer()
        }
        .transition(.move(edge: .top))
        .sheet(isPresented: $showDetail) {
            ArticleDetailView(article: article)
        }
    }
}

#Preview {
    BreakingNewsBanner(
        article: NewsArticle(
            title: "Breaking: Major Event Happening Right Now",
            description: "This is a breaking news alert.",
            link: URL(string: "https://example.com")!,
            pubDate: Date(),
            source: NewsSource(name: "Test Source", feedURL: URL(string: "https://example.com/feed")!, category: .topStories),
            category: .topStories,
            isBreaking: true
        ),
        onDismiss: {}
    )
}
