//
//  PreferencesView.swift
//  TimerApp
//
//  Created by Desktop Timer on 8/19/25.
//

import SwiftUI
import ServiceManagement
import UserNotifications

struct PreferencesView: View {
    @AppStorage("launch_at_login") private var launchAtLogin: Bool = false
    @AppStorage("timer_opacity") private var windowOpacity: Double = 1.0
    @AppStorage("position_lock") private var positionLock: Bool = false
    @AppStorage("timer_theme") private var selectedTheme: String = "system"
    @AppStorage("sound_enabled") private var soundEnabled: Bool = true
    @AppStorage("notification_enabled") private var notificationEnabled: Bool = true
    @AppStorage("flash_enabled") private var flashEnabled: Bool = false
    @AppStorage("selected_sound") private var selectedSound: String = "Glass"
    @AppStorage("keep_on_top") private var keepOnTop: Bool = true
    @AppStorage("snap_to_corners") private var snapToCorners: Bool = true
    @AppStorage("compact_mode") private var compactMode: Bool = false
    @AppStorage("show_in_dock") private var showInDock: Bool = false
    
    @State private var showingPermissionsAlert = false
    @State private var showingSoundTest = false
    
    private let themes = [
        ("system", "System"),
        ("light", "Light"),
        ("dark", "Dark"),
        ("high-contrast", "High Contrast")
    ]
    
    private let sounds = [
        "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
        "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"
    ]
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            behaviorTab
                .tabItem {
                    Label("Behavior", systemImage: "rectangle.3.offgrid")
                }
            
            notificationsTab
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
            
            hotkeyTab
                .tabItem {
                    Label("Hotkeys", systemImage: "keyboard")
                }
        }
        .frame(width: 500, height: 600)
    }
    
    // MARK: - General Tab
    
    private var generalTab: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        configureLaunchAtLogin(newValue)
                    }
                
                Toggle("Show in Dock", isOn: $showInDock)
                    .onChange(of: showInDock) { newValue in
                        NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                    }
            }
            
            Section("Window Behavior") {
                Toggle("Keep windows on top", isOn: $keepOnTop)
                Toggle("Lock window positions", isOn: $positionLock)
                Toggle("Snap to screen corners", isOn: $snapToCorners)
                Toggle("Compact mode by default", isOn: $compactMode)
            }
            
            Section("Accessibility") {
                HStack {
                    Text("Accessibility permissions")
                    Spacer()
                    Button("Check Status") {
                        checkAccessibilityPermissions()
                    }
                }
                
                Text("Required for global hotkeys and click-through functionality")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .alert("Accessibility Permissions", isPresented: $showingPermissionsAlert) {
            Button("Open System Preferences") {
                openAccessibilityPreferences()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("TimerApp needs accessibility permissions to register global hotkeys. Please enable TimerApp in System Preferences > Security & Privacy > Privacy > Accessibility.")
        }
    }
    
    // MARK: - Appearance Tab
    
    private var appearanceTab: some View {
        Form {
            Section("Theme") {
                Picker("Color scheme", selection: $selectedTheme) {
                    ForEach(themes, id: \.0) { theme in
                        Text(theme.1).tag(theme.0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section("Transparency") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Window opacity")
                        Spacer()
                        Text("\(Int(windowOpacity * 100))%")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $windowOpacity, in: 0.3...1.0, step: 0.1)
                        .accentColor(.blue)
                }
            }
            
            Section("Preview") {
                TimerPreviewView(
                    theme: selectedTheme,
                    opacity: windowOpacity,
                    compact: compactMode
                )
                .frame(height: 120)
            }
        }
        .padding()
    }
    
    // MARK: - Behavior Tab
    
    private var behaviorTab: some View {
        Form {
            Section("Timer Behavior") {
                Toggle("Pause on sleep", isOn: .constant(true))
                    .disabled(true)
                
                Text("Timers automatically handle sleep/wake correctly using monotonic time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Multiple Timers") {
                Text("Smart positioning: New timers automatically position to avoid overlap")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Menu bar management: Access all active timers from the menu bar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Persistence") {
                Text("Window positions and timer settings are automatically saved")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Reset All Positions") {
                    resetWindowPositions()
                }
                .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    // MARK: - Notifications Tab
    
    private var notificationsTab: some View {
        Form {
            Section("Completion Alerts") {
                Toggle("Play sound", isOn: $soundEnabled)
                Toggle("Show notification", isOn: $notificationEnabled)
                Toggle("Flash screen", isOn: $flashEnabled)
            }
            
            Section("Sound Selection") {
                Picker("Alert sound", selection: $selectedSound) {
                    ForEach(sounds, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                .disabled(!soundEnabled)
                
                HStack {
                    Button("Test Sound") {
                        testSelectedSound()
                    }
                    .disabled(!soundEnabled)
                    
                    Spacer()
                }
            }
            
            Section("Notification Permissions") {
                Text("Make sure notifications are enabled in System Preferences > Notifications > TimerApp")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Request Permission") {
                    requestNotificationPermission()
                }
            }
        }
        .padding()
    }
    
    // MARK: - Hotkey Tab
    
    private var hotkeyTab: some View {
        Form {
            Section("Global Hotkeys") {
                HStack {
                    Text("Start/Pause Timer")
                    Spacer()
                    Text("⌘⇧T")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Reset Timer")
                    Spacer()
                    Text("⌘⇧R")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Show/Hide Timers")
                    Spacer()
                    Text("⌘⇧H")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Requirements") {
                Text("Global hotkeys require accessibility permissions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Check Accessibility Permissions") {
                    checkAccessibilityPermissions()
                }
            }
            
            Section("Menu Bar Shortcuts") {
                Text("⌘N - New Timer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("⌘A - Show All Timers")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("⌘H - Hide All Timers")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("⌘, - Preferences")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("⌘Q - Quit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private func configureLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to configure launch at login: \(error)")
            }
        }
    }
    
    private func checkAccessibilityPermissions() {
        let accessEnabled = AXIsProcessTrusted()
        if !accessEnabled {
            showingPermissionsAlert = true
        }
    }
    
    private func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func testSelectedSound() {
        if let sound = NSSound(named: selectedSound) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func resetWindowPositions() {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys
        
        for key in keys {
            if key.hasPrefix("WindowFrame_") {
                defaults.removeObject(forKey: key)
            }
        }
    }
}

// MARK: - Timer Preview View

struct TimerPreviewView: View {
    let theme: String
    let opacity: Double
    let compact: Bool
    
    @State private var previewTime: TimeInterval = 1234
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Preview")
                .font(.headline)
            
            Text(formattedTime)
                .font(.system(compact ? .title2 : .largeTitle, design: .monospaced))
                .fontWeight(.medium)
            
            HStack {
                Button(action: {}) {
                    Image(systemName: "play.fill")
                        .frame(width: 32, height: 24)
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 32, height: 24)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        )
        .opacity(opacity)
        .preferredColorScheme(colorScheme)
    }
    
    private var formattedTime: String {
        let minutes = Int(previewTime) / 60
        let seconds = Int(previewTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var colorScheme: ColorScheme? {
        switch theme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}

/*
#Preview {
    PreferencesView()
}
*/
