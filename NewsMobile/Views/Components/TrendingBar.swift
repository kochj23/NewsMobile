//
//  TrendingBar.swift
//  NewsMobile
//
//  Scrolling trending topics bar
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct TrendingBar: View {
    let topics: [TrendingTopic]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.orange)
                Text("Trending")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(topics) { topic in
                        TrendingChip(topic: topic)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TrendingChip: View {
    let topic: TrendingTopic

    var body: some View {
        HStack(spacing: 6) {
            if let category = topic.category {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundColor(Color(hex: category.color))
            }

            Text(topic.name)
                .font(.subheadline)

            Text("\(topic.articleCount)")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange)
                .cornerRadius(8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(20)
    }
}

#Preview {
    TrendingBar(topics: [
        TrendingTopic(name: "Apple", articleCount: 5, category: .technology),
        TrendingTopic(name: "Elections", articleCount: 8, category: .politics),
        TrendingTopic(name: "Climate", articleCount: 4, category: .science)
    ])
}
