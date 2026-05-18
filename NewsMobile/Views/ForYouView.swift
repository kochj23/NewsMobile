//
//  ForYouView.swift
//  NewsMobile
//
//  Personalized news feed
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ForYouView: View {
    @StateObject private var personalization = PersonalizationEngine.shared
    @EnvironmentObject var newsAggregator: NewsAggregator
    @EnvironmentObject var settings: SettingsManager
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        NavigationStack {
            Group {
                if !settings.settings.enablePersonalization {
                    disabledView
                } else if personalization.personalizedArticles.isEmpty {
                    emptyView
                } else {
                    articlesList
                }
            }
            .navigationTitle("For You")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            personalization.resetProfile()
                        } label: {
                            Label("Reset Preferences", systemImage: "arrow.counterclockwise")
                        }

                        Toggle("Personalization", isOn: $settings.settings.enablePersonalization)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
        }
    }

    private var disabledView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Personalization Disabled")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enable personalization in settings to see articles curated for you.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                settings.settings.enablePersonalization = true
            } label: {
                Text("Enable Personalization")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Building Your Feed")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Read some articles and we'll learn your preferences to curate a personalized feed.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var articlesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(personalization.personalizedArticles.prefix(50)) { article in
                    ArticleCard(article: article)
                        .onTapGesture {
                            selectedArticle = article
                        }
                }
            }
            .padding()
        }
        .refreshable {
            await newsAggregator.refresh()
        }
    }
}

#Preview {
    ForYouView()
        .environmentObject(NewsAggregator.shared)
        .environmentObject(SettingsManager.shared)
}
