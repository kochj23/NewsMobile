//
//  BackgroundRefreshManager.swift
//  NewsMobile
//
//  Background app refresh for news updates
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import BackgroundTasks

class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()

    private let refreshTaskIdentifier = "com.jordankoch.NewsMobile.refresh"

    private init() {}

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleAppRefresh(task: refreshTask)
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh() // Schedule the next refresh

        let refreshTask = Task { @MainActor in
            await NewsAggregator.shared.fetchAllNews()
        }

        task.expirationHandler = {
            refreshTask.cancel()
            // System will reclaim the task; setTaskCompleted called below in
            // the monitoring Task when cancellation propagates.
        }

        Task {
            var success = false
            do {
                _ = await refreshTask.result
                success = !Task.isCancelled
            }
            task.setTaskCompleted(success: success)
        }
    }
}
