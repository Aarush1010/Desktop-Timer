//
//  LaunchAtLoginHelper.swift
//  LaunchAtLoginHelper
//
//  Created by Desktop Timer on 8/19/25.
//

import Cocoa

@main
struct LaunchAtLoginHelper {
    static func main() {
        let mainAppIdentifier = "com.timerapp.TimerApp"
        
        // Check if main app is already running
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { app in
            app.bundleIdentifier == mainAppIdentifier
        }
        
        if !isRunning {
            // Launch the main app
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: mainAppIdentifier) {
                NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
                    // Helper's job is done, terminate
                    NSApp.terminate(nil)
                }
            }
        } else {
            // Main app is already running, just terminate helper
            NSApp.terminate(nil)
        }
    }
}
