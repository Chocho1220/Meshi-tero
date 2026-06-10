//
//  MeshiTeroApp.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/26.
//

import SwiftUI
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

@main
struct MeshiTeroApp: App {
    private let notificationDelegate = NotificationDelegate()
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState: AppState

    init() {
        _appState = State(initialValue: AppState())
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                appState.flushPersistence()
            }
        }
    }
}
