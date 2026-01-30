//
//  CategoryView.swift
//  NewsMobile
//
//  Category-specific news view
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct CategoryView: View {
    let category: NewsCategory
    @EnvironmentObject var newsAggregator: NewsAggregator
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(newsAggregator.articles(for: category)) { article in
                    ArticleCard(article: article)
                        .onTapGesture {
                            selectedArticle = article
                        }
                }
            }
            .padding()
        }
        .navigationTitle(category.rawValue)
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
    }
}

#Preview {
    NavigationStack {
        CategoryView(category: .technology)
            .environmentObject(NewsAggregator.shared)
    }
}
