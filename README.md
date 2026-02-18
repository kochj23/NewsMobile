# News Mobile - AI-Powered News for iPhone & iPad

**On-Device Machine Learning News Reader with Sentiment Analysis, Personalization, and Multi-Source Comparison**

![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20iPadOS%2017.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.0.0-success)
![ML](https://img.shields.io/badge/ML-NaturalLanguage%20%7C%20Vision-purple)

---

## Overview

News Mobile brings AI-powered news analysis to your iPhone and iPad. Using Apple's on-device machine learning frameworks (NaturalLanguage, Vision), it provides real-time sentiment analysis, named entity recognition, personalized feeds, and multi-source story comparison - all without requiring cloud services.

Built as a companion to NewsTV (Apple TV), News Mobile is optimized for mobile touch interactions with a beautiful, native SwiftUI interface.

---

## Features

### On-Device Machine Learning

| Feature | Framework | Description |
|---------|-----------|-------------|
| **Sentiment Analysis** | NaturalLanguage | Color-coded sentiment indicators for headlines |
| **Named Entity Recognition** | NaturalLanguage | Identifies people, organizations, locations |
| **Topic Extraction** | NaturalLanguage | Identifies trending topics across feeds |
| **Story Clustering** | NaturalLanguage | Groups related articles from different sources |
| **Personalization Engine** | NaturalLanguage | Learns your preferences over time |

### Mobile-Optimized Features

- **Tab-Based Navigation** - Home, For You, Search, Saved, Settings
- **Pull-to-Refresh** - Native iOS refresh gesture
- **Full Article WebView** - Read complete articles in-app
- **Share Sheet Integration** - Share articles via iOS share sheet
- **Push Notifications** - Breaking news and keyword alerts
- **Background Refresh** - Automatic news updates
- **iCloud Sync** - Sync across all your Apple devices
- **Dark Mode** - Full dark mode support

### Smart Features

- **Personalized "For You" Feed** - AI learns your reading habits
- **Watch Later Queue** - Save articles with iCloud sync
- **Multi-Source Story View** - Compare how different sources cover stories
- **Local News** - News from your ZIP code or city
- **Keyword Alerts** - Monitor for specific topics
- **Custom RSS Feeds** - Add any RSS feed
- **Weather Widget** - Current conditions at a glance
- **Trending Topics** - See what's trending across sources
- **Content Filtering** - Removes ads and sponsored content
- **Audio Briefings** - Text-to-speech news reading

### News Analysis

- **Sentiment Coloring** - Headlines color-coded by sentiment
- **Entity Extraction** - See who and what is mentioned
- **Perspective Analysis** - Compare left, center, and right coverage
- **Source Bias Indicators** - Visual badges showing political leaning
- **Source Reliability** - Reliability scores for news sources

---

## News Sources

### Default Sources (25+)

| Category | Sources |
|----------|---------|
| **Top Stories** | Associated Press, Reuters, NPR |
| **Disney** | Disney Parks Blog, D23, Google News Disney |
| **US** | NY Times |
| **World** | BBC, The Guardian |
| **Technology** | TechCrunch, Ars Technica, The Verge |
| **Business** | CNBC |
| **Science** | Science Daily |
| **Health** | Medical News Today |
| **Sports** | ESPN |
| **Entertainment** | Variety |
| **Politics** | Politico, The Hill |

---

## Requirements

- **iOS 17.0** / **iPadOS 17.0** or later
- **iPhone** or **iPad**
- **Xcode 15.0** or later (for building)
- **iCloud account** (optional, for sync)
- **Location Services** (optional, for local news and weather)

---

## Installation

### From Xcode

1. Clone the repository:
   ```bash
   git clone https://github.com/kochj23/NewsMobile.git
   cd NewsMobile
   ```

2. Open in Xcode:
   ```bash
   open NewsMobile.xcodeproj
   ```

3. Select your device as the destination
4. Build and run (Cmd+R)

---

## Privacy

News Mobile respects your privacy:

- **No cloud AI** - All ML processing happens on your device
- **No analytics** - No usage tracking or telemetry
- **No accounts** - No sign-in required (iCloud optional)
- **No data collection** - News is fetched directly from RSS feeds
- **Open source** - Full source code available for inspection

---

## Related Projects

- **[NewsTV](https://github.com/kochj23/NewsTV)** - Apple TV version

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Author

**Jordan Koch** ([@kochj23](https://github.com/kochj23))

---

*News Mobile v1.0.0 - AI-Powered News in Your Pocket*

© 2026 Jordan Koch. All rights reserved.

---

> **Disclaimer:** This is a personal project created on my own time. It is not affiliated with, endorsed by, or representative of my employer.
