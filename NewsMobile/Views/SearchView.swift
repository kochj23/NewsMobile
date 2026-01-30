//
//  SearchView.swift
//  NewsMobile
//
//  Search across all articles
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var newsAggregator: NewsAggregator
    @State private var searchText = ""
    @State private var selectedArticle: NewsArticle?

    var filteredArticles: [NewsArticle] {
        if searchText.isEmpty {
            return []
        }

        let query = searchText.lowercased()
        return newsAggregator.articles.filter { article in
            article.title.lowercased().contains(query) ||
            (article.rssDescription?.lowercased().contains(query) ?? false) ||
            article.source.name.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    emptySearchView
                } else if filteredArticles.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search articles...")
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
        }
    }

    private var emptySearchView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Search News")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Search by headline, description, or source name.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No Results")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Try a different search term.")
                .foregroundColor(.secondary)
        }
    }

    private var resultsList: some View {
        List {
            ForEach(filteredArticles) { article in
                SearchResultRow(article: article, searchText: searchText)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedArticle = article
                    }
            }
        }
        .listStyle(.plain)
    }
}

struct SearchResultRow: View {
    let article: NewsArticle
    let searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(highlightedTitle)
                .font(.headline)
                .lineLimit(2)

            if let description = article.rssDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Image(systemName: article.category.icon)
                    .foregroundColor(Color(hex: article.category.color))
                Text(article.source.name)
                Text("•")
                Text(article.timeAgoString)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var highlightedTitle: AttributedString {
        var title = AttributedString(article.title)
        if let range = title.range(of: searchText, options: .caseInsensitive) {
            title[range].backgroundColor = .yellow.opacity(0.3)
        }
        return title
    }
}

#Preview {
    SearchView()
        .environmentObject(NewsAggregator.shared)
}
