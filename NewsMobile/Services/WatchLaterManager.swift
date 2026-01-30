//
//  WatchLaterManager.swift
//  NewsMobile
//
//  Manages watch later queue with iCloud sync
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
class WatchLaterManager: ObservableObject {
    static let shared = WatchLaterManager()

    @Published var items: [WatchLaterItem] = []

    private let storageKey = "WatchLaterItems"
    private let iCloudKey = "WatchLaterItemsCloud"

    private init() {
        loadItems()
        syncFromCloud()
    }

    func add(_ article: NewsArticle) {
        guard !items.contains(where: { $0.article.id == article.id }) else { return }
        let item = WatchLaterItem(article: article)
        items.insert(item, at: 0)
        saveItems()
        syncToCloud()
    }

    func remove(_ article: NewsArticle) {
        items.removeAll { $0.article.id == article.id }
        saveItems()
        syncToCloud()
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
        syncToCloud()
    }

    func markAsRead(_ item: WatchLaterItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isRead = true
            saveItems()
            syncToCloud()
        }
    }

    func isInWatchLater(_ article: NewsArticle) -> Bool {
        items.contains { $0.article.id == article.id }
    }

    func toggle(_ article: NewsArticle) {
        if isInWatchLater(article) {
            remove(article)
        } else {
            add(article)
        }
    }

    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([WatchLaterItem].self, from: data) {
            items = decoded
        }
    }

    private func syncToCloud() {
        guard SettingsManager.shared.settings.enableICloudSync else { return }
        if let encoded = try? JSONEncoder().encode(items) {
            NSUbiquitousKeyValueStore.default.set(encoded, forKey: iCloudKey)
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    private func syncFromCloud() {
        guard SettingsManager.shared.settings.enableICloudSync else { return }
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: iCloudKey),
           let cloudItems = try? JSONDecoder().decode([WatchLaterItem].self, from: data) {
            // Merge cloud items with local
            for cloudItem in cloudItems {
                if !items.contains(where: { $0.article.id == cloudItem.article.id }) {
                    items.append(cloudItem)
                }
            }
            items.sort { $0.addedDate > $1.addedDate }
            saveItems()
        }
    }
}
