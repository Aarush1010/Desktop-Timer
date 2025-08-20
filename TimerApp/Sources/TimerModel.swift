//
//  TimerModel.swift
//  TimerApp
//
//  Created by Desktop Timer on 8/19/25.
//

import Foundation
import Combine
import AppKit

// MARK: - Timer State

enum TimerState: String, CaseIterable {
    case stopped = "stopped"
    case running = "running"
    case paused = "paused"
    case completed = "completed"
    
    var isActive: Bool {
        return self == .running
    }
}

// MARK: - Timer Model

class TimerModel: ObservableObject, Identifiable {
    let id = UUID()
    
    // Published properties for SwiftUI
    @Published var state: TimerState = .stopped
    @Published var remainingTime: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var title: String = "Timer"
    
    // Timer configuration
    @Published var inputMinutes: String = ""
    @Published var inputSeconds: String = ""
    @Published var inputHours: String = ""
    
    // Internal timer properties
    private var timer: Timer?
    private var startTime: CFAbsoluteTime = 0
    private var pausedTime: CFAbsoluteTime = 0
    private var completionHandled = false
    
    // Settings (persisted)
    @Published var soundEnabled: Bool = true
    @Published var notificationEnabled: Bool = true
    @Published var flashEnabled: Bool = false
    @Published var selectedSoundName: String = "Glass"
    
    // Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSettings()
        setupNotificationObservers()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Timer Control
    
    func start() {
        guard state != .running else { return }
        
        if state == .stopped {
            // Starting fresh timer
            guard let time = parseTimeInput() else { return }
            totalTime = time
            remainingTime = time
            completionHandled = false
        }
        
        // Use monotonic time (CFAbsoluteTime) to handle sleep/wake correctly
        startTime = CFAbsoluteTimeGetCurrent()
        if state == .paused {
            // Adjust for paused time
            startTime -= (totalTime - remainingTime)
        }
        
        state = .running
        startTimer()
    }
    
    func pause() {
        guard state == .running else { return }
        
        timer?.invalidate()
        pausedTime = CFAbsoluteTimeGetCurrent()
        state = .paused
    }
    
    func reset() {
        timer?.invalidate()
        state = .stopped
        remainingTime = 0
        totalTime = 0
        completionHandled = false
    }
    
    func toggle() {
        switch state {
        case .stopped, .paused:
            start()
        case .running:
            pause()
        case .completed:
            reset()
        }
    }
    
    // MARK: - Time Input Parsing
    
    private func parseTimeInput() -> TimeInterval? {
        let hours = Double(inputHours) ?? 0
        let minutes = Double(inputMinutes) ?? 0
        let seconds = Double(inputSeconds) ?? 0
        
        let totalSeconds = hours * 3600 + minutes * 60 + seconds
        return totalSeconds > 0 ? totalSeconds : nil
    }
    
    func setTime(hours: Int = 0, minutes: Int = 0, seconds: Int = 0) {
        inputHours = hours > 0 ? String(hours) : ""
        inputMinutes = minutes > 0 ? String(minutes) : ""
        inputSeconds = seconds > 0 ? String(seconds) : ""
    }
    
    // MARK: - Quick Presets
    
    func setPreset(minutes: Int) {
        reset()
        setTime(minutes: minutes)
    }
    
    // MARK: - Timer Implementation
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        guard state == .running else { return }
        
        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsed = currentTime - startTime
        
        remainingTime = max(0, totalTime - elapsed)
        
        if remainingTime <= 0 && !completionHandled {
            timerCompleted()
        }
    }
    
    private func timerCompleted() {
        completionHandled = true
        timer?.invalidate()
        state = .completed
        
        // Play completion sound
        if soundEnabled {
            playCompletionSound()
        }
        
        // Show notification
        if notificationEnabled {
            showCompletionNotification()
        }
        
        // Flash screen
        if flashEnabled {
            flashScreen()
        }
    }
    
    // MARK: - Completion Actions
    
    private func playCompletionSound() {
        if let sound = NSSound(named: selectedSoundName) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    private func showCompletionNotification() {
        let notification = NSUserNotification()
        notification.title = "Timer Completed"
        notification.subtitle = title
        notification.informativeText = "Your timer has finished!"
        notification.soundName = soundEnabled ? selectedSoundName : nil
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func flashScreen() {
        // Create a fullscreen flash overlay
        DispatchQueue.main.async {
            FlashOverlayWindow.shared.flash()
        }
    }
    
    // MARK: - Formatted Time Display
    
    var formattedTime: String {
        let time = remainingTime
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var compactFormattedTime: String {
        let time = remainingTime
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        
        if time >= 3600 {
            let hours = Int(time) / 3600
            return String(format: "%dh %dm", hours, minutes % 60)
        } else if time >= 60 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    // MARK: - Progress Calculation
    
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return max(0, min(1, (totalTime - remainingTime) / totalTime))
    }
    
    // MARK: - Sleep/Wake Handling
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .didWakeFromSleep)
            .sink { [weak self] _ in
                self?.handleWakeFromSleep()
            }
            .store(in: &cancellables)
    }
    
    private func handleWakeFromSleep() {
        guard state == .running else { return }
        
        // Recalibrate timer after sleep - use monotonic time
        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsed = currentTime - startTime
        
        remainingTime = max(0, totalTime - elapsed)
        
        if remainingTime <= 0 && !completionHandled {
            timerCompleted()
        }
    }
    
    // MARK: - Persistence
    
    private func loadSettings() {
        soundEnabled = UserDefaults.standard.bool(forKey: "timer_sound_enabled")
        notificationEnabled = UserDefaults.standard.bool(forKey: "timer_notification_enabled")
        flashEnabled = UserDefaults.standard.bool(forKey: "timer_flash_enabled")
        selectedSoundName = UserDefaults.standard.string(forKey: "timer_sound_name") ?? "Glass"
        
        // Set defaults if first launch
        if !UserDefaults.standard.bool(forKey: "timer_settings_initialized") {
            soundEnabled = true
            notificationEnabled = true
            flashEnabled = false
            saveSettings()
            UserDefaults.standard.set(true, forKey: "timer_settings_initialized")
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(soundEnabled, forKey: "timer_sound_enabled")
        UserDefaults.standard.set(notificationEnabled, forKey: "timer_notification_enabled")
        UserDefaults.standard.set(flashEnabled, forKey: "timer_flash_enabled")
        UserDefaults.standard.set(selectedSoundName, forKey: "timer_sound_name")
    }
}

// MARK: - Flash Overlay Window

class FlashOverlayWindow: NSWindow {
    static let shared = FlashOverlayWindow()
    
    private init() {
        super.init(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.backgroundColor = NSColor.white.withAlphaComponent(0.8)
        self.level = .screenSaver
        self.ignoresMouseEvents = true
        self.isOpaque = false
        self.hasShadow = false
    }
    
    func flash() {
        // Show on all screens
        if let screens = NSScreen.screens as? [NSScreen] {
            for screen in screens {
                let flashWindow = NSWindow(
                    contentRect: screen.frame,
                    styleMask: [.borderless],
                    backing: .buffered,
                    defer: false
                )
                
                flashWindow.backgroundColor = NSColor.white.withAlphaComponent(0.8)
                flashWindow.level = .screenSaver
                flashWindow.ignoresMouseEvents = true
                flashWindow.isOpaque = false
                flashWindow.hasShadow = false
                flashWindow.alphaValue = 0.0
                
                flashWindow.makeKeyAndOrderFront(nil)
                
                // Animate flash
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.1
                    flashWindow.animator().alphaValue = 1.0
                } completionHandler: {
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.3
                        flashWindow.animator().alphaValue = 0.0
                    } completionHandler: {
                        flashWindow.close()
                    }
                }
            }
        }
    }
}
