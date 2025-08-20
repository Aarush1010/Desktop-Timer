//
//  TimerApp.swift
//  TimerApp
//
//  Created by Desktop Timer on 8/19/25.
//

import SwiftUI

@main
struct TimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var windowController = FloatingWindowController()
    
    var body: some Scene {
        // Main menu bar with native menu styling
        MenuBarExtra {
            MenuBarView()
                .environmentObject(windowController)
        } label: {
            Image(systemName: "timer")
                .foregroundColor(.primary)
        }
        .menuBarExtraStyle(.menu)
        
        // Preferences window
        Window("Preferences", id: "preferences") {
            PreferencesView()
                .frame(width: 500, height: 600)
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
