//
//  ContentView.swift
//  NewsMobile
//
//  Main tab-based navigation for iOS
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var newsAggregator: NewsAggregator
    @EnvironmentObject var settings: SettingsManager
    @State private var selectedTab = 0
    @State private var showBreakingNews = false
    @State private var breakingArticle: NewsArticle?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "newspaper.fill")
                }
                .tag(0)

            ForYouView()
                .tabItem {
                    Label("For You", systemImage: "star.fill")
                }
                .tag(1)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(2)

            WatchLaterView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .tint(.blue)
        .overlay {
            if showBreakingNews, let article = breakingArticle {
                BreakingNewsBanner(article: article) {
                    showBreakingNews = false
                }
            }
        }
        .onReceive(newsAggregator.$breakingNews) { article in
            if let article = article, settings.settings.showBreakingNewsAlerts {
                breakingArticle = article
                showBreakingNews = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NewsAggregator.shared)
        .environmentObject(SettingsManager.shared)
        .environmentObject(WatchLaterManager.shared)
}
