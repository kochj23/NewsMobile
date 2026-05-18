//
//  SettingsView.swift
//  NewsMobile
//
//  App settings
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @StateObject private var cloudSync = CloudSyncManager.shared
    @StateObject private var notifications = NotificationManager.shared

    var body: some View {
        NavigationStack {
            Form {
                // Display
                Section("Display") {
                    Toggle("Dark Mode", isOn: $settings.settings.darkModeEnabled)

                    Picker("Font Size", selection: $settings.settings.fontSize) {
                        ForEach(NewsMobileSettings.FontSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }

                    Toggle("Sentiment Colors", isOn: $settings.settings.showSentimentColors)
                    Toggle("Source Bias Indicators", isOn: $settings.settings.showBiasIndicators)
                }

                // Notifications
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $settings.settings.enableNotifications)
                    Toggle("Breaking News Alerts", isOn: $settings.settings.showBreakingNewsAlerts)

                    if !notifications.isAuthorized {
                        Button("Request Permission") {
                            notifications.requestPermission()
                        }
                    }
                }

                // Audio
                Section("Audio Briefings") {
                    Toggle("Enable Audio", isOn: $settings.settings.enableAudioBriefings)

                    Picker("Speech Rate", selection: $settings.settings.speechRate) {
                        ForEach(NewsMobileSettings.SpeechRate.allCases, id: \.self) { rate in
                            Text(rate.rawValue).tag(rate)
                        }
                    }
                }

                // Personalization
                Section("Personalization") {
                    Toggle("Enable Personalization", isOn: $settings.settings.enablePersonalization)

                    NavigationLink("Keyword Alerts") {
                        KeywordAlertsView()
                    }

                    NavigationLink("Custom Feeds") {
                        CustomFeedsView()
                    }

                    NavigationLink("Local News") {
                        LocalNewsView()
                    }
                }

                // Content Filtering
                Section("Content Filtering") {
                    Toggle("Filter Advertisements", isOn: $settings.settings.filterAds)
                    Toggle("Filter Clickbait", isOn: $settings.settings.filterClickbait)
                }

                // Sync
                Section("iCloud Sync") {
                    Toggle("Enable Sync", isOn: $settings.settings.enableICloudSync)

                    if settings.settings.enableICloudSync {
                        HStack {
                            Text("Last Sync")
                            Spacer()
                            if let date = cloudSync.lastSyncDate {
                                Text(date.formatted(.relative(presentation: .named)))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Never")
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button("Sync Now") {
                            cloudSync.syncToCloud()
                        }
                    }
                }

                // Background Refresh
                Section("Background Refresh") {
                    Toggle("Enable Background Refresh", isOn: $settings.settings.enableBackgroundRefresh)

                    if settings.settings.enableBackgroundRefresh {
                        Picker("Refresh Interval", selection: $settings.settings.refreshInterval) {
                            Text("15 minutes").tag(15)
                            Text("30 minutes").tag(30)
                            Text("1 hour").tag(60)
                            Text("2 hours").tag(120)
                        }
                    }
                }

                // Weather
                Section("Weather") {
                    Toggle("Show Weather Widget", isOn: $settings.settings.enableWeatherWidget)
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Jordan Koch")
                            .foregroundColor(.secondary)
                    }

                    Button("Reset to Defaults", role: .destructive) {
                        settings.resetToDefaults()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager.shared)
}
