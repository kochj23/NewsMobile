//
//  EntityExtractor.swift
//  NewsMobile
//
//  Named entity recognition using NaturalLanguage
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import NaturalLanguage

class EntityExtractor {
    private let tagger = NLTagger(tagSchemes: [.nameType])

    func extract(from text: String) -> [ExtractedEntity] {
        tagger.string = text

        var entities: [ExtractedEntity] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            guard let tag = tag else { return true }

            let entityText = String(text[range])

            let entityType: ExtractedEntity.EntityType?
            switch tag {
            case .personalName:
                entityType = .person
            case .organizationName:
                entityType = .organization
            case .placeName:
                entityType = .place
            default:
                entityType = nil
            }

            if let type = entityType {
                let entity = ExtractedEntity(text: entityText, type: type)
                if !entities.contains(where: { $0.text == entityText }) {
                    entities.append(entity)
                }
            }

            return true
        }

        return entities
    }
}
