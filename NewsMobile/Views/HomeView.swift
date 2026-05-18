//
//  HomeView.swift
//  NewsMobile
//
//  Main home view with categories
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var newsAggregator: NewsAggregator
    @EnvironmentObject var settings: SettingsManager
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var trendingEngine = TrendingTopicsEngine.shared
    @State private var selectedCategory: NewsCategory = .topStories
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Weather widget
                    if settings.settings.enableWeatherWidget {
                        WeatherWidget()
                            .padding(.horizontal)
                    }

                    // Trending topics
                    if !trendingEngine.trendingTopics.isEmpty {
                        TrendingBar(topics: trendingEngine.trendingTopics)
                    }

                    // Category picker
                    categoryPicker

                    // Articles
                    LazyVStack(spacing: 12) {
                        ForEach(newsAggregator.articles(for: selectedCategory)) { article in
                            ArticleCard(article: article)
                                .onTapGesture {
                                    selectedArticle = article
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("News")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if newsAggregator.isLoading {
                        ProgressView()
                    } else {
                        Button {
                            Task { await newsAggregator.refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .refreshable {
                await newsAggregator.refresh()
            }
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
            .onAppear {
                if settings.settings.enableWeatherWidget {
                    weatherService.requestLocation()
                }
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NewsCategory.allCases) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryButton: View {
    let category: NewsCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                Text(category.rawValue)
            }
            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: category.color) : Color.gray.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environmentObject(NewsAggregator.shared)
        .environmentObject(SettingsManager.shared)
}
