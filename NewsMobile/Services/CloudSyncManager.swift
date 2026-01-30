//
//  CloudSyncManager.swift
//  NewsMobile
//
//  iCloud sync for settings and data
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

@MainActor
class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private let settingsKey = "CloudSettings"
    private let watchLaterKey = "CloudWatchLater"

    private init() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleCloudUpdate()
            }
        }

        NSUbiquitousKeyValueStore.default.synchronize()
    }

    func syncToCloud() {
        guard SettingsManager.shared.settings.enableICloudSync else { return }

        isSyncing = true

        // Sync settings
        if let encoded = try? JSONEncoder().encode(SettingsManager.shared.settings) {
            NSUbiquitousKeyValueStore.default.set(encoded, forKey: settingsKey)
        }

        NSUbiquitousKeyValueStore.default.synchronize()

        lastSyncDate = Date()
        isSyncing = false
    }

    func syncFromCloud() {
        guard SettingsManager.shared.settings.enableICloudSync else { return }

        isSyncing = true

        // Sync settings
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(NewsMobileSettings.self, from: data) {
            SettingsManager.shared.settings = settings
        }

        lastSyncDate = Date()
        isSyncing = false
    }

    private func handleCloudUpdate() {
        syncFromCloud()
    }

    func clearCloudData() {
        NSUbiquitousKeyValueStore.default.removeObject(forKey: settingsKey)
        NSUbiquitousKeyValueStore.default.removeObject(forKey: watchLaterKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}
