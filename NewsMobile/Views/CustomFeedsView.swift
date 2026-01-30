//
//  CustomFeedsView.swift
//  NewsMobile
//
//  Custom RSS feeds management
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct CustomFeedsView: View {
    @StateObject private var customFeeds = CustomFeedManager.shared
    @EnvironmentObject var settings: SettingsManager
    @State private var showAddFeed = false
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        NavigationStack {
            List {
                // Feed list
                if !settings.settings.customFeeds.isEmpty {
                    Section("Your Feeds") {
                        ForEach(settings.settings.customFeeds) { feed in
                            CustomFeedRow(feed: feed)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let feed = settings.settings.customFeeds[index]
                                customFeeds.removeFeed(id: feed.id)
                            }
                        }
                    }
                }

                // Suggested feeds
                Section("Suggested Feeds") {
                    ForEach(CustomFeedManager.suggestedFeeds, id: \.name) { suggestion in
                        Button {
                            if let url = URL(string: suggestion.url) {
                                customFeeds.addFeed(name: suggestion.name, url: url, category: suggestion.category)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.green)

                                VStack(alignment: .leading) {
                                    Text(suggestion.name)
                                        .foregroundColor(.primary)
                                    Text(suggestion.category.rawValue)
                                        .font(.caption)
                                        .foregroundColor(Color(hex: suggestion.category.color))
                                }
                            }
                        }
                    }
                }

                // Articles section
                if !customFeeds.customArticles.isEmpty {
                    Section("Recent Articles") {
                        ForEach(customFeeds.customArticles.prefix(20)) { article in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(article.title)
                                    .font(.headline)
                                    .lineLimit(2)

                                Text(article.source.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedArticle = article
                            }
                        }
                    }
                }
            }
            .navigationTitle("Custom Feeds")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddFeed = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFeed) {
                AddFeedView()
            }
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
            .refreshable {
                await customFeeds.fetchAllCustomFeeds()
            }
        }
    }
}

struct CustomFeedRow: View {
    let feed: CustomRSSFeed
    @StateObject private var customFeeds = CustomFeedManager.shared

    var body: some View {
        HStack {
            Button {
                customFeeds.toggleFeed(id: feed.id, enabled: !feed.isEnabled)
            } label: {
                Image(systemName: feed.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(feed.isEnabled ? .green : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(feed.name)
                    .fontWeight(.medium)
                    .foregroundColor(feed.isEnabled ? .primary : .secondary)

                HStack {
                    Image(systemName: feed.category.icon)
                        .font(.caption)
                    Text(feed.category.rawValue)
                        .font(.caption)

                    if feed.articleCount > 0 {
                        Text("• \(feed.articleCount) articles")
                            .font(.caption)
                    }
                }
                .foregroundColor(Color(hex: feed.category.color))
            }
        }
    }
}

struct AddFeedView: View {
    @StateObject private var customFeeds = CustomFeedManager.shared
    @State private var feedName = ""
    @State private var feedURL = ""
    @State private var selectedCategory: NewsCategory = .topStories
    @State private var isValidating = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Feed Details") {
                    TextField("Feed Name", text: $feedName)
                    TextField("RSS URL", text: $feedURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(NewsCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addFeed()
                    }
                    .disabled(feedName.isEmpty || feedURL.isEmpty || isValidating)
                }
            }
            .overlay {
                if isValidating {
                    ProgressView("Validating...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }

    private func addFeed() {
        guard let url = URL(string: feedURL) else {
            errorMessage = "Invalid URL"
            return
        }

        isValidating = true
        errorMessage = nil

        Task {
            let isValid = await customFeeds.validateFeedURL(url)

            if isValid {
                customFeeds.addFeed(name: feedName, url: url, category: selectedCategory)
                dismiss()
            } else {
                errorMessage = "Could not parse RSS feed at this URL"
            }

            isValidating = false
        }
    }
}

#Preview {
    CustomFeedsView()
        .environmentObject(SettingsManager.shared)
}
