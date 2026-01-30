//
//  SettingsManager.swift
//  NewsMobile
//
//  Manages user settings with persistence
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var settings: NewsMobileSettings {
        didSet {
            saveSettings()
        }
    }

    private let settingsKey = "NewsMobileSettings"

    private init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(NewsMobileSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = NewsMobileSettings()
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    func resetToDefaults() {
        settings = NewsMobileSettings()
    }
}
