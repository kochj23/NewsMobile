//
//  KeywordAlertsView.swift
//  NewsMobile
//
//  Keyword alerts management
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct KeywordAlertsView: View {
    @StateObject private var alertManager = KeywordAlertManager.shared
    @EnvironmentObject var settings: SettingsManager
    @State private var newKeyword = ""
    @State private var selectedKeyword: String?
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        NavigationStack {
            List {
                // Add new keyword
                Section {
                    HStack {
                        TextField("New keyword...", text: $newKeyword)

                        Button {
                            if !newKeyword.isEmpty {
                                alertManager.addAlert(keyword: newKeyword)
                                newKeyword = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newKeyword.isEmpty)
                    }
                }

                // Existing keywords
                if !settings.settings.keywordAlerts.isEmpty {
                    Section("Your Keywords") {
                        ForEach(settings.settings.keywordAlerts) { alert in
                            KeywordRow(alert: alert, matchCount: alertManager.articles(for: alert.keyword).count)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedKeyword = alert.keyword
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let alert = settings.settings.keywordAlerts[index]
                                alertManager.removeAlert(id: alert.id)
                            }
                        }
                    }
                }

                // Suggestions
                if settings.settings.keywordAlerts.isEmpty {
                    Section("Suggestions") {
                        ForEach(["Apple", "Tesla", "AI", "Climate", "Bitcoin", "Entertainment"], id: \.self) { keyword in
                            Button {
                                alertManager.addAlert(keyword: keyword)
                            } label: {
                                Label(keyword, systemImage: "plus")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Keyword Alerts")
            .sheet(item: $selectedKeyword) { keyword in
                KeywordMatchesView(keyword: keyword)
            }
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct KeywordRow: View {
    let alert: KeywordAlert
    let matchCount: Int
    @StateObject private var alertManager = KeywordAlertManager.shared

    var body: some View {
        HStack {
            Button {
                alertManager.toggleAlert(id: alert.id, enabled: !alert.isEnabled)
            } label: {
                Image(systemName: alert.isEnabled ? "bell.fill" : "bell.slash")
                    .foregroundColor(alert.isEnabled ? .yellow : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.keyword)
                    .fontWeight(.medium)

                if let lastMatch = alert.lastMatchDate {
                    Text("Last: \(lastMatch.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if matchCount > 0 {
                Text("\(matchCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .cornerRadius(10)
            }
        }
    }
}

struct KeywordMatchesView: View {
    let keyword: String
    @StateObject private var alertManager = KeywordAlertManager.shared
    @State private var selectedArticle: NewsArticle?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                let articles = alertManager.articles(for: keyword)

                if articles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No Matches Yet")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("We'll notify you when articles match \"\(keyword)\".")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List(articles) { article in
                        ArticleRow(article: article, highlightKeyword: keyword)
                            .onTapGesture {
                                selectedArticle = article
                            }
                    }
                }
            }
            .navigationTitle("\"\(keyword)\" Matches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        alertManager.clearMatches(for: keyword)
                    }
                }
            }
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
        }
    }
}

struct ArticleRow: View {
    let article: NewsArticle
    let highlightKeyword: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(highlightedTitle)
                .font(.headline)
                .lineLimit(2)

            HStack {
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
        if let range = title.range(of: highlightKeyword, options: .caseInsensitive) {
            title[range].foregroundColor = .yellow
            title[range].font = .headline.bold()
        }
        return title
    }
}

#Preview {
    KeywordAlertsView()
        .environmentObject(SettingsManager.shared)
}
