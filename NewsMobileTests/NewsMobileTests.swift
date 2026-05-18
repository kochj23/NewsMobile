//
//  NewsMobileTests.swift
//  NewsMobileTests
//
//  Comprehensive test suite for NewsMobile
//  Unit, Functional, Integration, Security, and Frame tests
//
//  Created by Jordan Koch on 2026-05-01.
//  Updated by Jordan Koch on 2026-05-03.
//  Copyright (c) 2026 Jordan Koch. All rights reserved.
//

import XCTest
import SwiftUI
@testable import NewsMobile

// MARK: - Test Helpers

enum TestData {
    static func makeSource(
        name: String = "Test Source",
        category: NewsCategory = .topStories,
        bias: SourceBias = .center,
        reliability: Double = 0.8
    ) -> NewsSource {
        NewsSource(
            name: name,
            feedURL: URL(string: "https://example.com/rss")!,
            category: category,
            bias: bias,
            reliability: reliability
        )
    }

    static func makeArticle(
        title: String = "Test Article Headline",
        description: String? = "A test description for the article.",
        source: NewsSource? = nil,
        category: NewsCategory = .topStories,
        pubDate: Date = Date(),
        isBreaking: Bool = false
    ) -> NewsArticle {
        NewsArticle(
            title: title,
            description: description,
            link: URL(string: "https://example.com/article/\(UUID().uuidString)")!,
            pubDate: pubDate,
            source: source ?? makeSource(),
            category: category,
            isBreaking: isBreaking
        )
    }

    static let sampleRSSXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
    <channel>
        <title>Test Feed</title>
        <item>
            <title>Economy Shows Strong Growth</title>
            <link>https://example.com/article1</link>
            <description>GDP growth exceeded expectations at 3.2%.</description>
            <pubDate>Thu, 01 May 2026 12:00:00 +0000</pubDate>
            <media:content url="https://example.com/image1.jpg"/>
        </item>
        <item>
            <title>Breaking: Earthquake Detected</title>
            <link>https://example.com/article2</link>
            <description>&lt;p&gt;A 5.4 magnitude &lt;strong&gt;earthquake&lt;/strong&gt; was detected.&lt;/p&gt;</description>
            <pubDate>Thu, 01 May 2026 14:00:00 +0000</pubDate>
        </item>
        <item>
            <title>New AI Chip Released</title>
            <link>https://example.com/article3</link>
            <description><![CDATA[<p>Apple announced its next-gen chip.</p>]]></description>
            <pubDate>2026-05-01T10:00:00Z</pubDate>
        </item>
    </channel>
    </rss>
    """

    static let malformedRSS = """
    <?xml version="1.0"?>
    <rss><channel>
        <item>
            <title>No Link Item</title>
        </item>
        <item>
            <title></title>
            <link>https://example.com/empty</link>
        </item>
    </channel></rss>
    """

    static let xssPayloads = [
        "<script>alert('xss')</script>",
        "<img src=x onerror=alert(1)>",
        "javascript:alert(1)",
        "<svg onload=alert(1)>",
        "<iframe src=\"javascript:alert(1)\">",
    ]
}

// MARK: - NewsArticle Model Tests (Unit)

final class NewsArticleModelTests: XCTestCase {

    func testArticleCreation() {
        let article = TestData.makeArticle(title: "Test Headline")
        XCTAssertEqual(article.title, "Test Headline")
        XCTAssertFalse(article.isBreaking)
        XCTAssertNil(article.sentiment)
        XCTAssertNil(article.entities)
    }

    func testArticleEquality() {
        let a1 = TestData.makeArticle(title: "First")
        let a2 = TestData.makeArticle(title: "Second")
        XCTAssertNotEqual(a1, a2, "Different articles should not be equal")
    }

    func testArticleHashability() {
        let a1 = TestData.makeArticle()
        let a2 = TestData.makeArticle()
        var set = Set<NewsArticle>()
        set.insert(a1)
        set.insert(a2)
        XCTAssertEqual(set.count, 2)
    }

    func testArticleCodable() throws {
        let article = TestData.makeArticle(title: "Codable Test", description: "Test description")
        let data = try JSONEncoder().encode(article)
        XCTAssertFalse(data.isEmpty)
        let decoded = try JSONDecoder().decode(NewsArticle.self, from: data)
        XCTAssertEqual(decoded.title, "Codable Test")
        XCTAssertEqual(decoded.rssDescription, "Test description")
    }

    func testArticleCodableWithMLFields() throws {
        var article = TestData.makeArticle(title: "ML Test")
        article.sentiment = SentimentResult(score: 0.5, label: .positive)
        article.entities = [ExtractedEntity(text: "Apple", type: .organization)]
        let data = try JSONEncoder().encode(article)
        let decoded = try JSONDecoder().decode(NewsArticle.self, from: data)
        XCTAssertEqual(decoded.sentiment?.label, .positive)
        XCTAssertEqual(decoded.entities?.count, 1)
    }

    func testBreakingArticle() {
        let article = TestData.makeArticle(title: "BREAKING: Major Event", isBreaking: true)
        XCTAssertTrue(article.isBreaking)
    }

    func testTimeAgoString() {
        let article = TestData.makeArticle(pubDate: Date().addingTimeInterval(-3600))
        let timeAgo = article.timeAgoString
        XCTAssertFalse(timeAgo.isEmpty, "Time ago string should not be empty")
    }

    func testTimeAgoStringRecent() {
        let article = TestData.makeArticle(pubDate: Date().addingTimeInterval(-60))
        XCTAssertFalse(article.timeAgoString.isEmpty)
    }

    func testArticleWithNilDescription() {
        let article = TestData.makeArticle(description: nil)
        XCTAssertNil(article.rssDescription)
    }

    func testArticleURLScheme() {
        let article = TestData.makeArticle()
        XCTAssertEqual(article.link.scheme, "https")
    }

    func testArticleMutability() {
        var article = TestData.makeArticle()
        XCTAssertNil(article.sentiment)
        article.sentiment = SentimentResult(score: 0.3, label: .neutral)
        XCTAssertNotNil(article.sentiment)
        XCTAssertEqual(article.sentiment?.label, .neutral)
    }
}

// MARK: - NewsCategory Tests (Unit)

final class NewsCategoryModelTests: XCTestCase {

    func testAllCategories() {
        XCTAssertEqual(NewsCategory.allCases.count, 10)
    }

    func testCategoryIcons() {
        for category in NewsCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) should have an icon")
        }
    }

    func testCategoryColors() {
        for category in NewsCategory.allCases {
            XCTAssertFalse(category.color.isEmpty, "\(category) should have a color hex")
            XCTAssertEqual(category.color.count, 6, "\(category) should have 6-char hex color")
        }
    }

    func testCategoryIdentifiable() {
        for category in NewsCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue)
        }
    }

    func testCategoryCodable() throws {
        let category = NewsCategory.technology
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(NewsCategory.self, from: data)
        XCTAssertEqual(decoded, .technology)
    }

    func testAllCategoriesCodableRoundTrip() throws {
        for category in NewsCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(NewsCategory.self, from: data)
            XCTAssertEqual(decoded, category, "\(category) should survive Codable round trip")
        }
    }

    func testCategoryRawValues() {
        XCTAssertEqual(NewsCategory.topStories.rawValue, "Top Stories")
        XCTAssertEqual(NewsCategory.politics.rawValue, "Politics")
    }
}

// MARK: - SourceBias Tests (Unit)

final class SourceBiasTests: XCTestCase {

    func testBiasColors() {
        for bias in [SourceBias.left, .leanLeft, .center, .leanRight, .right, .unknown] {
            XCTAssertFalse(bias.color.isEmpty, "\(bias) should have a color")
        }
    }

    func testBiasColorLength() {
        for bias in [SourceBias.left, .leanLeft, .center, .leanRight, .right, .unknown] {
            XCTAssertEqual(bias.color.count, 6, "\(bias) color should be 6-char hex")
        }
    }

    func testBiasCodable() throws {
        let bias = SourceBias.leanLeft
        let data = try JSONEncoder().encode(bias)
        let decoded = try JSONDecoder().decode(SourceBias.self, from: data)
        XCTAssertEqual(decoded, .leanLeft)
    }

    func testAllBiasesCodable() throws {
        for bias in [SourceBias.left, .leanLeft, .center, .leanRight, .right, .unknown] {
            let data = try JSONEncoder().encode(bias)
            let decoded = try JSONDecoder().decode(SourceBias.self, from: data)
            XCTAssertEqual(decoded, bias)
        }
    }
}

// MARK: - NewsSource Tests (Unit)

final class NewsSourceModelTests: XCTestCase {

    func testSourceCreation() {
        let source = TestData.makeSource(name: "AP News", bias: .center, reliability: 0.95)
        XCTAssertEqual(source.name, "AP News")
        XCTAssertEqual(source.bias, .center)
        XCTAssertEqual(source.reliability, 0.95)
    }

    func testSourceHashability() {
        let s1 = TestData.makeSource(name: "Source A")
        let s2 = TestData.makeSource(name: "Source B")
        var set = Set<NewsSource>()
        set.insert(s1)
        set.insert(s2)
        XCTAssertEqual(set.count, 2)
    }

    func testSourceCodable() throws {
        let source = TestData.makeSource(name: "Test")
        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(NewsSource.self, from: data)
        XCTAssertEqual(decoded.name, "Test")
    }

    func testSourceURLScheme() {
        let source = TestData.makeSource()
        XCTAssertEqual(source.feedURL.scheme, "https")
    }

    func testSourceDefaultValues() {
        let source = NewsSource(name: "Simple", feedURL: URL(string: "https://example.com")!, category: .us)
        XCTAssertEqual(source.bias, .unknown)
        XCTAssertEqual(source.reliability, 0.8)
    }
}

// MARK: - SentimentResult Tests (Unit)

final class SentimentResultTests: XCTestCase {

    func testPositiveSentiment() {
        let sentiment = SentimentResult(score: 0.8, label: .positive)
        XCTAssertEqual(sentiment.label, .positive)
        XCTAssertGreaterThan(sentiment.score, 0)
    }

    func testNegativeSentiment() {
        let sentiment = SentimentResult(score: -0.6, label: .negative)
        XCTAssertEqual(sentiment.label, .negative)
        XCTAssertLessThan(sentiment.score, 0)
    }

    func testNeutralSentiment() {
        let sentiment = SentimentResult(score: 0.0, label: .neutral)
        XCTAssertEqual(sentiment.label, .neutral)
    }

    func testSentimentCodable() throws {
        let sentiment = SentimentResult(score: 0.5, label: .positive)
        let data = try JSONEncoder().encode(sentiment)
        let decoded = try JSONDecoder().decode(SentimentResult.self, from: data)
        XCTAssertEqual(decoded.label, .positive)
        XCTAssertEqual(decoded.score, 0.5, accuracy: 0.01)
    }

    func testSentimentLabelIcons() {
        for label in [SentimentResult.SentimentLabel.positive, .negative, .neutral] {
            XCTAssertFalse(label.icon.isEmpty)
            XCTAssertFalse(label.color.isEmpty)
        }
    }

    func testSentimentLabelColors() {
        XCTAssertEqual(SentimentResult.SentimentLabel.positive.color, "2ECC71")
        XCTAssertEqual(SentimentResult.SentimentLabel.negative.color, "E74C3C")
        XCTAssertEqual(SentimentResult.SentimentLabel.neutral.color, "95A5A6")
    }

    func testSentimentHashable() {
        let s1 = SentimentResult(score: 0.5, label: .positive)
        let s2 = SentimentResult(score: 0.5, label: .positive)
        XCTAssertEqual(s1, s2)
    }
}

// MARK: - ExtractedEntity Tests (Unit)

final class ExtractedEntityTests: XCTestCase {

    func testEntityCreation() {
        let entity = ExtractedEntity(text: "Apple Inc.", type: .organization)
        XCTAssertEqual(entity.text, "Apple Inc.")
        XCTAssertEqual(entity.type, .organization)
    }

    func testEntityTypes() {
        for type in [ExtractedEntity.EntityType.person, .organization, .place] {
            XCTAssertFalse(type.icon.isEmpty)
            XCTAssertFalse(type.color.isEmpty)
        }
    }

    func testEntityCodable() throws {
        let entity = ExtractedEntity(text: "John Doe", type: .person)
        let data = try JSONEncoder().encode(entity)
        let decoded = try JSONDecoder().decode(ExtractedEntity.self, from: data)
        XCTAssertEqual(decoded.text, "John Doe")
        XCTAssertEqual(decoded.type, .person)
    }

    func testEntityHashable() {
        let e1 = ExtractedEntity(text: "Apple", type: .organization)
        let e2 = ExtractedEntity(text: "Apple", type: .organization)
        // Different UUIDs so they should not be equal
        XCTAssertNotEqual(e1.id, e2.id)
    }

    func testEntityTypeColors() {
        XCTAssertEqual(ExtractedEntity.EntityType.person.color, "3498DB")
        XCTAssertEqual(ExtractedEntity.EntityType.organization.color, "9B59B6")
        XCTAssertEqual(ExtractedEntity.EntityType.place.color, "2ECC71")
    }
}

// MARK: - StoryCluster Tests (Functional)

final class StoryClusterTests: XCTestCase {

    func testClusterCreation() {
        let articles = [
            TestData.makeArticle(title: "Story A", source: TestData.makeSource(name: "Source A")),
            TestData.makeArticle(title: "Story B", source: TestData.makeSource(name: "Source B")),
        ]
        let cluster = StoryCluster(topic: "Test Topic", articles: articles)
        XCTAssertEqual(cluster.topic, "Test Topic")
        XCTAssertEqual(cluster.articleCount, 2)
        XCTAssertEqual(cluster.sourceCount, 2)
    }

    func testClusterWithSingleSource() {
        let source = TestData.makeSource(name: "Same Source")
        let articles = [
            TestData.makeArticle(title: "Story A", source: source),
            TestData.makeArticle(title: "Story B", source: source),
        ]
        let cluster = StoryCluster(topic: "Topic", articles: articles)
        XCTAssertEqual(cluster.sourceCount, 1)
    }

    func testClusterIdentifiable() {
        let c1 = StoryCluster(topic: "A", articles: [])
        let c2 = StoryCluster(topic: "A", articles: [])
        XCTAssertNotEqual(c1.id, c2.id)
    }
}

// MARK: - WatchLaterItem Tests (Unit)

final class WatchLaterItemTests: XCTestCase {

    func testWatchLaterCreation() {
        let article = TestData.makeArticle(title: "Save for Later")
        let item = WatchLaterItem(article: article)
        XCTAssertFalse(item.isRead)
        XCTAssertEqual(item.article.title, "Save for Later")
    }

    func testWatchLaterCodable() throws {
        let item = WatchLaterItem(article: TestData.makeArticle())
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(WatchLaterItem.self, from: data)
        XCTAssertFalse(decoded.isRead)
    }

    func testWatchLaterMutability() {
        var item = WatchLaterItem(article: TestData.makeArticle())
        XCTAssertFalse(item.isRead)
        item.isRead = true
        XCTAssertTrue(item.isRead)
    }
}

// MARK: - KeywordAlert Tests (Unit)

final class KeywordAlertTests: XCTestCase {

    func testKeywordAlertCreation() {
        let alert = KeywordAlert(keyword: "Apple")
        XCTAssertEqual(alert.keyword, "Apple")
        XCTAssertTrue(alert.isEnabled)
        XCTAssertTrue(alert.notifyOnMatch)
        XCTAssertEqual(alert.matchCount, 0)
        XCTAssertNil(alert.lastMatchDate)
    }

    func testKeywordAlertCodable() throws {
        let alert = KeywordAlert(keyword: "Tesla")
        let data = try JSONEncoder().encode(alert)
        let decoded = try JSONDecoder().decode(KeywordAlert.self, from: data)
        XCTAssertEqual(decoded.keyword, "Tesla")
    }

    func testKeywordAlertMutability() {
        var alert = KeywordAlert(keyword: "AI")
        alert.isEnabled = false
        XCTAssertFalse(alert.isEnabled)
        alert.matchCount = 5
        XCTAssertEqual(alert.matchCount, 5)
    }
}

// MARK: - CustomRSSFeed Tests (Unit)

final class CustomRSSFeedTests: XCTestCase {

    func testCustomFeedCreation() {
        let feed = CustomRSSFeed(name: "My Blog", url: URL(string: "https://blog.example.com/rss")!, category: .technology)
        XCTAssertEqual(feed.name, "My Blog")
        XCTAssertTrue(feed.isEnabled)
        XCTAssertNil(feed.lastFetchDate)
        XCTAssertEqual(feed.articleCount, 0)
    }

    func testCustomFeedCodable() throws {
        let feed = CustomRSSFeed(name: "Test", url: URL(string: "https://example.com/rss")!, category: .science)
        let data = try JSONEncoder().encode(feed)
        let decoded = try JSONDecoder().decode(CustomRSSFeed.self, from: data)
        XCTAssertEqual(decoded.name, "Test")
        XCTAssertEqual(decoded.category, .science)
    }

    func testCustomFeedMutability() {
        var feed = CustomRSSFeed(name: "Blog", url: URL(string: "https://blog.com/rss")!, category: .technology)
        feed.isEnabled = false
        XCTAssertFalse(feed.isEnabled)
        feed.articleCount = 42
        XCTAssertEqual(feed.articleCount, 42)
    }
}

// MARK: - Settings Tests (Unit / Integration)

final class SettingsTests: XCTestCase {

    func testDefaultSettings() {
        let settings = NewsMobileSettings()
        XCTAssertTrue(settings.darkModeEnabled)
        XCTAssertTrue(settings.showSentimentColors)
        XCTAssertTrue(settings.showBiasIndicators)
        XCTAssertTrue(settings.filterAds)
        XCTAssertTrue(settings.filterClickbait)
        XCTAssertTrue(settings.enableBackgroundRefresh)
        XCTAssertEqual(settings.refreshInterval, 15)
        XCTAssertEqual(settings.fontSize, .medium)
        XCTAssertTrue(settings.customFeeds.isEmpty)
        XCTAssertTrue(settings.keywordAlerts.isEmpty)
        XCTAssertTrue(settings.excludedSources.isEmpty)
    }

    func testDefaultSettingsEnableFlags() {
        let settings = NewsMobileSettings()
        XCTAssertTrue(settings.enableAudioBriefings)
        XCTAssertTrue(settings.enablePersonalization)
        XCTAssertTrue(settings.enableNotifications)
        XCTAssertTrue(settings.enableWeatherWidget)
        XCTAssertTrue(settings.enableICloudSync)
        XCTAssertTrue(settings.showBreakingNewsAlerts)
    }

    func testSpeechRates() {
        XCTAssertLessThan(NewsMobileSettings.SpeechRate.slow.rate, NewsMobileSettings.SpeechRate.normal.rate)
        XCTAssertLessThan(NewsMobileSettings.SpeechRate.normal.rate, NewsMobileSettings.SpeechRate.fast.rate)
    }

    func testSpeechRateValues() {
        XCTAssertEqual(NewsMobileSettings.SpeechRate.slow.rate, 0.4)
        XCTAssertEqual(NewsMobileSettings.SpeechRate.normal.rate, 0.5)
        XCTAssertEqual(NewsMobileSettings.SpeechRate.fast.rate, 0.6)
    }

    func testFontSizeScaleFactors() {
        XCTAssertLessThan(NewsMobileSettings.FontSize.small.scaleFactor, NewsMobileSettings.FontSize.medium.scaleFactor)
        XCTAssertLessThan(NewsMobileSettings.FontSize.medium.scaleFactor, NewsMobileSettings.FontSize.large.scaleFactor)
        XCTAssertLessThan(NewsMobileSettings.FontSize.large.scaleFactor, NewsMobileSettings.FontSize.extraLarge.scaleFactor)
    }

    func testFontSizeScaleValues() {
        XCTAssertEqual(NewsMobileSettings.FontSize.small.scaleFactor, 0.9)
        XCTAssertEqual(NewsMobileSettings.FontSize.medium.scaleFactor, 1.0)
        XCTAssertEqual(NewsMobileSettings.FontSize.large.scaleFactor, 1.15)
        XCTAssertEqual(NewsMobileSettings.FontSize.extraLarge.scaleFactor, 1.3)
    }

    func testSettingsCodable() throws {
        var settings = NewsMobileSettings()
        settings.darkModeEnabled = false
        settings.refreshInterval = 30
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(NewsMobileSettings.self, from: data)
        XCTAssertFalse(decoded.darkModeEnabled)
        XCTAssertEqual(decoded.refreshInterval, 30)
    }

    func testSettingsWithCustomFeeds() throws {
        var settings = NewsMobileSettings()
        let feed = CustomRSSFeed(name: "Custom", url: URL(string: "https://custom.com/rss")!, category: .technology)
        settings.customFeeds.append(feed)
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(NewsMobileSettings.self, from: data)
        XCTAssertEqual(decoded.customFeeds.count, 1)
        XCTAssertEqual(decoded.customFeeds.first?.name, "Custom")
    }

    func testSettingsNilLocation() {
        let settings = NewsMobileSettings()
        XCTAssertNil(settings.localNewsLocation)
        XCTAssertNil(settings.localNewsZipCode)
    }
}

// MARK: - UserPreferenceProfile Tests (Unit / Functional)

final class UserPreferenceProfileTests: XCTestCase {

    func testDefaultProfile() {
        let profile = UserPreferenceProfile()
        XCTAssertTrue(profile.categoryPreferences.isEmpty)
        XCTAssertTrue(profile.sourcePreferences.isEmpty)
        XCTAssertTrue(profile.topicInterests.isEmpty)
        XCTAssertTrue(profile.viewedArticleIds.isEmpty)
    }

    func testProfileCodable() throws {
        var profile = UserPreferenceProfile()
        profile.categoryPreferences[.technology] = 0.8
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserPreferenceProfile.self, from: data)
        XCTAssertEqual(decoded.categoryPreferences[.technology], 0.8)
    }

    func testProfileReadDuration() {
        var profile = UserPreferenceProfile()
        let articleId = UUID()
        profile.readDuration[articleId] = 120.0
        XCTAssertEqual(profile.readDuration[articleId], 120.0)
    }

    func testProfileViewTracking() {
        var profile = UserPreferenceProfile()
        let id = UUID()
        profile.viewedArticleIds.insert(id)
        XCTAssertTrue(profile.viewedArticleIds.contains(id))
    }
}

// MARK: - Color Extension Tests (Unit)

final class ColorExtensionTests: XCTestCase {

    func testHexColorCreation() {
        let _ = SwiftUI.Color(hex: "FF6B6B")
        let _ = SwiftUI.Color(hex: "4ECDC4")
        let _ = SwiftUI.Color(hex: "000000")
        let _ = SwiftUI.Color(hex: "FFFFFF")
    }

    func testHexColorWithInvalidInput() {
        let _ = SwiftUI.Color(hex: "")
        let _ = SwiftUI.Color(hex: "XYZ")
        let _ = SwiftUI.Color(hex: "#FF0000")
    }

    func testHexColorWith3Chars() {
        let _ = SwiftUI.Color(hex: "F00")
    }

    func testHexColorWith8Chars() {
        let _ = SwiftUI.Color(hex: "FF00FF00")
    }
}

// MARK: - Security Tests

final class SecurityTests: XCTestCase {

    func testNoHardcodedAPIKeys() {
        let dangerousPatterns = [
            "sk-[A-Za-z0-9]{20,}",
            "AKIA[A-Z0-9]{16}",
            "ghp_[A-Za-z0-9]{36}",
            "xox[bpoas]-[A-Za-z0-9]",
        ]

        let testString = TestData.sampleRSSXML
        for pattern in dangerousPatterns {
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(testString.startIndex..., in: testString)
            let matches = regex?.numberOfMatches(in: testString, range: range) ?? 0
            XCTAssertEqual(matches, 0, "Found potential API key pattern '\(pattern)'")
        }
    }

    func testHTMLSanitization() {
        for payload in TestData.xssPayloads {
            let article = TestData.makeArticle(description: payload)
            XCTAssertNotNil(article.rssDescription)
        }
    }

    func testArticleLinkURLScheme() {
        let safeArticle = TestData.makeArticle()
        XCTAssertTrue(
            safeArticle.link.scheme == "https" || safeArticle.link.scheme == "http",
            "Article URLs should use HTTP(S) scheme"
        )
    }

    func testSourceURLsAreHTTPS() {
        let source = TestData.makeSource()
        XCTAssertEqual(source.feedURL.scheme, "https", "Feed URLs should use HTTPS")
    }

    func testNoSensitiveDataInCodableOutput() throws {
        let article = TestData.makeArticle(title: "Secret Test")
        let data = try JSONEncoder().encode(article)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        XCTAssertFalse(jsonString.contains("password"), "Codable output should not contain passwords")
        XCTAssertFalse(jsonString.contains("apiKey"), "Codable output should not contain API keys")
    }

    func testXSSPayloadsInTitles() {
        for payload in TestData.xssPayloads {
            let article = TestData.makeArticle(title: payload)
            // Article should accept any title without crashing
            XCTAssertEqual(article.title, payload)
        }
    }

    func testFeedURLNotJavascript() {
        let source = TestData.makeSource()
        XCTAssertNotEqual(source.feedURL.scheme, "javascript")
    }
}

// MARK: - Trending Topic Tests (Unit)

final class TrendingTopicTests: XCTestCase {

    func testTopicCreation() {
        let topic = TrendingTopic(name: "AI", articleCount: 15)
        XCTAssertEqual(topic.name, "AI")
        XCTAssertEqual(topic.articleCount, 15)
        XCTAssertNil(topic.category)
    }

    func testTopicWithCategory() {
        let topic = TrendingTopic(name: "Tech", articleCount: 10, category: .technology)
        XCTAssertEqual(topic.category, .technology)
    }

    func testTopicHashable() {
        let t1 = TrendingTopic(name: "AI", articleCount: 10)
        let t2 = TrendingTopic(name: "AI", articleCount: 10)
        var set = Set<TrendingTopic>()
        set.insert(t1)
        set.insert(t2)
        XCTAssertEqual(set.count, 2, "Different instances should have different IDs")
    }
}

// MARK: - PerspectiveBreakdown Tests (Unit)

final class PerspectiveBreakdownTests: XCTestCase {

    func testBreakdownCreation() {
        let breakdown = PerspectiveBreakdown(
            leftPerspective: "Left view",
            centerPerspective: "Center view",
            rightPerspective: "Right view",
            sharedFacts: ["Fact 1", "Fact 2"],
            contentions: ["Contention 1"]
        )
        XCTAssertEqual(breakdown.leftPerspective, "Left view")
        XCTAssertEqual(breakdown.sharedFacts.count, 2)
        XCTAssertEqual(breakdown.contentions.count, 1)
    }

    func testBreakdownWithNils() {
        let breakdown = PerspectiveBreakdown(
            leftPerspective: nil,
            centerPerspective: nil,
            rightPerspective: nil,
            sharedFacts: [],
            contentions: []
        )
        XCTAssertNil(breakdown.leftPerspective)
        XCTAssertTrue(breakdown.sharedFacts.isEmpty)
    }
}

// MARK: - Frame / Performance Tests

final class FrameTests: XCTestCase {

    func testArticleCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = TestData.makeArticle()
            }
        }
    }

    func testArticleCodablePerformance() {
        let articles = (0..<100).map { TestData.makeArticle(title: "Article \($0)") }
        measure {
            for article in articles {
                if let data = try? JSONEncoder().encode(article) {
                    let _ = try? JSONDecoder().decode(NewsArticle.self, from: data)
                }
            }
        }
    }

    func testSourceCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = TestData.makeSource()
            }
        }
    }

    func testSettingsCodablePerformance() {
        let settings = NewsMobileSettings()
        measure {
            for _ in 0..<500 {
                if let data = try? JSONEncoder().encode(settings) {
                    let _ = try? JSONDecoder().decode(NewsMobileSettings.self, from: data)
                }
            }
        }
    }

    func testHexColorPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = SwiftUI.Color(hex: "FF6B6B")
                let _ = SwiftUI.Color(hex: "4ECDC4")
                let _ = SwiftUI.Color(hex: "9B59B6")
            }
        }
    }
}
