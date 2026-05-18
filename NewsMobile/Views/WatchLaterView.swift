//
//  WatchLaterView.swift
//  NewsMobile
//
//  Saved articles view
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct WatchLaterView: View {
    @EnvironmentObject var watchLater: WatchLaterManager
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        NavigationStack {
            Group {
                if watchLater.items.isEmpty {
                    emptyView
                } else {
                    articlesList
                }
            }
            .navigationTitle("Saved")
            .toolbar {
                if !watchLater.items.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Saved Articles")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap the bookmark icon on any article to save it for later.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var articlesList: some View {
        List {
            ForEach(watchLater.items) { item in
                WatchLaterRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedArticle = item.article
                        watchLater.markAsRead(item)
                    }
            }
            .onDelete { indexSet in
                watchLater.remove(at: indexSet)
            }
        }
        .listStyle(.plain)
    }
}

struct WatchLaterRow: View {
    let item: WatchLaterItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.article.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(item.isRead ? .secondary : .primary)

                HStack {
                    Text(item.article.source.name)
                    Text("•")
                    Text(item.addedDate.formatted(.relative(presentation: .named)))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            if !item.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WatchLaterView()
        .environmentObject(WatchLaterManager.shared)
}
