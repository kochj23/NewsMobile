//
//  RSSParser.swift
//  NewsMobile
//
//  RSS feed parsing with XMLParser
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

actor RSSParser: NSObject, XMLParserDelegate {
    private var articles: [NewsArticle] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentImageURL = ""
    private var source: NewsSource?
    private var isInItem = false
    private var continuation: CheckedContinuation<[NewsArticle], Never>?

    func parse(data: Data, source: NewsSource) async -> [NewsArticle] {
        self.source = source
        self.articles = []

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
        }
    }

    nonisolated func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        Task { await handleStartElement(elementName, attributes: attributeDict) }
    }

    private func handleStartElement(_ elementName: String, attributes: [String: String]) {
        currentElement = elementName

        if elementName == "item" || elementName == "entry" {
            isInItem = true
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
            currentImageURL = ""
        }

        if elementName == "media:content" || elementName == "media:thumbnail" {
            if let url = attributes["url"] {
                currentImageURL = url
            }
        }

        if elementName == "enclosure" {
            if let url = attributes["url"], attributes["type"]?.contains("image") == true {
                currentImageURL = url
            }
        }

        if elementName == "link" {
            if let href = attributes["href"] {
                currentLink = href
            }
        }
    }

    nonisolated func parser(_ parser: XMLParser, foundCharacters string: String) {
        Task { await handleFoundCharacters(string) }
    }

    private func handleFoundCharacters(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "title":
            currentTitle += trimmed
        case "description", "summary", "content:encoded":
            currentDescription += trimmed
        case "link":
            if currentLink.isEmpty {
                currentLink += trimmed
            }
        case "pubDate", "published", "updated", "dc:date":
            currentPubDate += trimmed
        default:
            break
        }
    }

    nonisolated func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        Task { await handleEndElement(elementName) }
    }

    private func handleEndElement(_ elementName: String) {
        guard elementName == "item" || elementName == "entry" else { return }
        guard let source = source else { return }

        isInItem = false

        guard !currentTitle.isEmpty,
              let url = URL(string: currentLink.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }

        let pubDate = parseDate(currentPubDate) ?? Date()
        let imageURL = URL(string: currentImageURL)

        let cleanDescription = cleanHTML(currentDescription)

        let article = NewsArticle(
            title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: cleanDescription.isEmpty ? nil : cleanDescription,
            link: url,
            pubDate: pubDate,
            source: source,
            category: source.category,
            imageURL: imageURL
        )

        articles.append(article)
    }

    nonisolated func parserDidEndDocument(_ parser: XMLParser) {
        Task { await handleEndDocument() }
    }

    private func handleEndDocument() {
        continuation?.resume(returning: articles)
        continuation = nil
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
                let f = ISO8601DateFormatter()
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                df.locale = Locale(identifier: "en_US_POSIX")
                return df
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
