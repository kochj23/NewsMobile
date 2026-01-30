//
//  SentimentAnalyzer.swift
//  NewsMobile
//
//  On-device sentiment analysis using NaturalLanguage
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import NaturalLanguage

class SentimentAnalyzer {
    private let tagger = NLTagger(tagSchemes: [.sentimentScore])

    func analyze(_ text: String) -> SentimentResult {
        tagger.string = text

        var totalScore: Double = 0
        var count = 0

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                count += 1
            }
            return true
        }

        let averageScore = count > 0 ? totalScore / Double(count) : 0

        let label: SentimentResult.SentimentLabel
        if averageScore > 0.1 {
            label = .positive
        } else if averageScore < -0.1 {
            label = .negative
        } else {
            label = .neutral
        }

        return SentimentResult(score: averageScore, label: label)
    }
}
