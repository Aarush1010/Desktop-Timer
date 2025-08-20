//
//  AppDelegate.swift
//  TimerApp
//
//  Created by Desktop Timer on 8/19/25.
//

import Cocoa
import Carbon
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var floatingWindowController: FloatingWindowController?
    
    // Global hotkey event handlers
    var hotkeyStartPause: EventHotKeyRef?
    var hotkeyReset: EventHotKeyRef?
    var hotkeyShowHide: EventHotKeyRef?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Hide dock icon - we only want menu bar presence
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize floating window controller
        floatingWindowController = FloatingWindowController()
        
        // Setup global hotkeys
        setupGlobalHotkeys()
        
        // Request accessibility permissions
        requestAccessibilityPermissions()
        
        // Handle wake from sleep
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up hotkeys
        unregisterGlobalHotkeys()
    }
    
    // MARK: - Global Hotkeys Setup
    
    private func setupGlobalHotkeys() {
        // Register hotkeys: Cmd+Shift+T for start/pause, Cmd+Shift+R for reset, Cmd+Shift+H for show/hide
        registerHotkey(keyCode: UInt32(kVK_ANSI_T), modifiers: UInt32(cmdKey | shiftKey), id: 1)
        registerHotkey(keyCode: UInt32(kVK_ANSI_R), modifiers: UInt32(cmdKey | shiftKey), id: 2)
        registerHotkey(keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(cmdKey | shiftKey), id: 3)
    }
    
    private func registerHotkey(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
        var hotKeyRef: EventHotKeyRef?

        // Create an OSType four‑char code like 'TMRA'
        // The UInt32(bitPattern:) keeps the literal unchanged
        let signature: UInt32 =
            (UInt32(Character("T").asciiValue!) << 24) |
            (UInt32(Character("M").asciiValue!) << 16) |
            (UInt32(Character("R").asciiValue!) << 8)  |
            UInt32(Character("A").asciiValue!)

        // EventHotKeyID needs a signature and an id
        var hotKeyID = EventHotKeyID(signature: signature, id: id)

        // Register
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        // Store refs per your switch
        switch id {
        case 1: hotkeyStartPause = hotKeyRef
        case 2: hotkeyReset = hotKeyRef
        case 3: hotkeyShowHide = hotKeyRef
        default: break
        }

        // Install handler once, keep yours as is
        if id == 1 {
            InstallEventHandler(GetApplicationEventTarget(), hotkeyHandler,
                                1, [EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                                  eventKind: UInt32(kEventHotKeyPressed))],
                                UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), nil)
        }
    }

    // Helper to build FourCharCode from string like "TMRA"
    private func fourCharCode(_ s: String) -> UInt32 {
        var result: UInt32 = 0
        for b in s.utf8.prefix(4) {            // take up to 4 bytes
            result = (result << 8) | UInt32(b)  // shift then add byte
        }
        return result
    }
    
    private func unregisterGlobalHotkeys() {
        if let hotkey = hotkeyStartPause {
            UnregisterEventHotKey(hotkey)
        }
        if let hotkey = hotkeyReset {
            UnregisterEventHotKey(hotkey)
        }
        if let hotkey = hotkeyShowHide {
            UnregisterEventHotKey(hotkey)
        }
    }
    
    // MARK: - Accessibility Permissions
    
    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Accessibility access not granted. Please enable in System Preferences > Security & Privacy > Privacy > Accessibility")
        }
    }
    
    // MARK: - Sleep/Wake Handling
    
    @objc private func workspaceDidWake() {
        // Notify all active timers to recalibrate after wake
        NotificationCenter.default.post(name: .didWakeFromSleep, object: nil)
    }
    
    // MARK: - Utility Functions
    
    private func fourCharCodeFrom(_ string: String) -> FourCharCode {
        assert(string.count == 4)
        var result: FourCharCode = 0
        for char in string.utf16 {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}

// MARK: - Global Hotkey Handler

private let hotkeyHandler: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
    guard let userData = userData else { return noErr }
    let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
    
    var hotKeyID = EventHotKeyID()
    GetEventParameter(theEvent, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
    
    switch hotKeyID.id {
    case 1: // Start/Pause
        NotificationCenter.default.post(name: .hotkeyStartPause, object: nil)
    case 2: // Reset
        NotificationCenter.default.post(name: .hotkeyReset, object: nil)
    case 3: // Show/Hide
        NotificationCenter.default.post(name: .hotkeyShowHide, object: nil)
    default:
        break
    }
    
    return noErr
}

// MARK: - Notification Names

extension Notification.Name {
    static let hotkeyStartPause = Notification.Name("hotkeyStartPause")
    static let hotkeyReset = Notification.Name("hotkeyReset")
    static let hotkeyShowHide = Notification.Name("hotkeyShowHide")
    static let didWakeFromSleep = Notification.Name("didWakeFromSleep")
}
