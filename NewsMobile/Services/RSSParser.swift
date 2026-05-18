//
//  RSSParser.swift
//  NewsMobile
//
//  RSS feed parsing with XMLParser
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

/// Thread-safe buffer for collecting XMLParser delegate callbacks synchronously.
/// XMLParser delegate methods are called on the same thread as `parse()`, so
/// a simple class (not actor) with no concurrency is sufficient.
private final class XMLParserBuffer: NSObject, XMLParserDelegate {
    struct RawItem {
        var title: String = ""
        var description: String = ""
        var link: String = ""
        var pubDate: String = ""
        var imageURL: String = ""
    }

    private(set) var items: [RawItem] = []
    private var currentElement = ""
    private var currentItem = RawItem()
    private var isInItem = false

    // MARK: - XMLParserDelegate (all synchronous, called on parser thread)

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName

        if elementName == "item" || elementName == "entry" {
            isInItem = true
            currentItem = RawItem()
        }

        if elementName == "media:content" || elementName == "media:thumbnail" {
            if let url = attributeDict["url"] {
                currentItem.imageURL = url
            }
        }

        if elementName == "enclosure" {
            if let url = attributeDict["url"], attributeDict["type"]?.contains("image") == true {
                currentItem.imageURL = url
            }
        }

        if elementName == "link" {
            if let href = attributeDict["href"] {
                currentItem.link = href
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "title":
            currentItem.title += trimmed
        case "description", "summary", "content:encoded":
            currentItem.description += trimmed
        case "link":
            if currentItem.link.isEmpty {
                currentItem.link += trimmed
            }
        case "pubDate", "published", "updated", "dc:date":
            currentItem.pubDate += trimmed
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard elementName == "item" || elementName == "entry" else { return }
        isInItem = false
        items.append(currentItem)
    }
}

actor RSSParser {
    func parse(data: Data, source: NewsSource) async -> [NewsArticle] {
        // Run the synchronous XMLParser on a background thread, collecting
        // all delegate data into the buffer without any actor hops.
        let buffer = XMLParserBuffer()
        let rawItems: [XMLParserBuffer.RawItem] = await withCheckedContinuation { continuation in
            let parser = XMLParser(data: data)
            parser.delegate = buffer
            parser.parse()
            continuation.resume(returning: buffer.items)
        }

        // Convert raw items to NewsArticle on the actor (isolated)
        return processRawItems(rawItems, source: source)
    }

    private func processRawItems(_ rawItems: [XMLParserBuffer.RawItem], source: NewsSource) -> [NewsArticle] {
        var articles: [NewsArticle] = []

        for item in rawItems {
            guard !item.title.isEmpty,
                  let url = URL(string: item.link.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                continue
            }

            let pubDate = parseDate(item.pubDate) ?? Date()
            let imageURL = URL(string: item.imageURL)
            let cleanDescription = cleanHTML(item.description)

            let article = NewsArticle(
                title: item.title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: cleanDescription.isEmpty ? nil : cleanDescription,
                link: url,
                pubDate: pubDate,
                source: source,
                category: source.category,
                imageURL: imageURL
            )

            articles.append(article)
        }

        return articles
    }

    private func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }()
        ]

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    private func cleanHTML(_ html: String) -> String {
        var result = html
        result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#39;", with: "'")
        result = result.replacingOccurrences(of: "&apos;", with: "'")
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return result
    }
}
