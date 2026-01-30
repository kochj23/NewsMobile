//
//  NewsMobileApp.swift
//  NewsMobile
//
//  AI-Powered News Reader for iPhone and iPad
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI
import BackgroundTasks

@main
struct NewsMobileApp: App {
    @StateObject private var newsAggregator = NewsAggregator.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var watchLaterManager = WatchLaterManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

    init() {
        // Register background tasks
        BackgroundRefreshManager.shared.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(newsAggregator)
                .environmentObject(settingsManager)
                .environmentObject(watchLaterManager)
                .preferredColorScheme(settingsManager.settings.darkModeEnabled ? .dark : nil)
                .onAppear {
                    notificationManager.requestPermission()
                    Task {
                        await newsAggregator.fetchAllNews()
                    }
                }
        }
    }
}
