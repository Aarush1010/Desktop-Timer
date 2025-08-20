//
//  FloatingWindowController.swift
//  TimerApp
//
//  Created by Desktop Timer on 8/19/25.
//

import Cocoa
import SwiftUI

class FloatingWindowController: ObservableObject {
    private var windows: [UUID: FloatingTimerWindow] = [:]
    @Published var timerModels: [TimerModel] = []
    
    init() {
        setupNotificationObservers()
    }
    
    func createNewTimer() -> UUID {
        let timerModel = TimerModel()
        timerModels.append(timerModel)
        
        // Give timer a unique name based on count
        let timerNumber = timerModels.count
        if timerNumber == 1 {
            timerModel.title = "Timer"
        } else {
            timerModel.title = "Timer \(timerNumber)"
        }
        
        let window = FloatingTimerWindow(timerModel: timerModel, controller: self)
        windows[timerModel.id] = window
        
        window.makeKeyAndOrderFront(nil)
        
        return timerModel.id
    }
    
    func closeTimer(id: UUID) {
        if let window = windows[id] {
            window.close()
            windows.removeValue(forKey: id)
        }
        
        timerModels.removeAll { $0.id == id }
    }
    
    func showTimer(id: UUID) {
        windows[id]?.makeKeyAndOrderFront(nil)
    }
    
    func hideTimer(id: UUID) {
        windows[id]?.orderOut(nil)
    }
    
    func toggleVisibility(id: UUID) {
        guard let window = windows[id] else { return }
        
        if window.isVisible && !window.isMiniaturized {
            window.orderOut(nil)
        } else {
            // Restore window if minimized
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func restoreAllWindows() {
        for (_, window) in windows {
            if window.isMiniaturized {
                window.deminiaturize(nil)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .hotkeyShowHide,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleShowHideHotkey()
        }
    }
    
    private func handleShowHideHotkey() {
        // Toggle visibility of the most recently used timer, or create new if none exist
        if let lastTimer = timerModels.last {
            toggleVisibility(id: lastTimer.id)
        } else {
            _ = createNewTimer()
        }
    }
}

// MARK: - Floating Timer Window

class FloatingTimerWindow: NSPanel {
    private let timerModel: TimerModel
    private weak var controller: FloatingWindowController?
    private var isDragging = false
    private var initialLocation: NSPoint = .zero
    private var isClickThrough = false
    
    init(timerModel: TimerModel, controller: FloatingWindowController) {
        self.timerModel = timerModel
        self.controller = controller
        
        // Create window with specific properties for floating behavior
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 300, height: 220),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupContent()
        setupNotificationObservers()
    }
    
    private func setupWindow() {
        // Window behavior
        self.level = .floating  // Always on top
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        
        // Allow window to accept input for text fields
        self.acceptsMouseMovedEvents = true
        
        // Make window draggable
        self.isMovableByWindowBackground = true
        
        // Rounded corners
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.cornerRadius = 12
        self.contentView?.layer?.masksToBounds = true
        
        // Initial position (smart positioning to avoid other timers)
        positionWindow()
    }
    
    private func setupContent() {
        let timerView = TimerView(
            timerModel: timerModel, 
            isFloating: true,
            onCompactStateChange: { [weak self] isCompact in
                self?.handleCompactStateChange(isCompact)
            },
            onSizeChange: { [weak self] size in
                self?.handleSizeChange(size)
            },
            onDelete: { [weak self] in
                self?.deleteTimer()
            }
        )
        let hostingView = NSHostingView(rootView: timerView)
        
        self.contentView = hostingView
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup constraints
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: self.contentView!.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: self.contentView!.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: self.contentView!.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: self.contentView!.bottomAnchor)
        ])
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .hotkeyStartPause,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.timerModel.toggle()
        }
        
        NotificationCenter.default.addObserver(
            forName: .hotkeyReset,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.timerModel.reset()
        }
    }
    
    private func positionWindow() {
        // Smart positioning to avoid overlap with existing timers
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = self.frame.size
        
        // Try to position away from other timers
        var x = screenFrame.maxX - windowSize.width - 20
        var y = screenFrame.maxY - windowSize.height - 20
        
        // Simple offset for multiple timers
        let timerCount = FloatingWindowController().timerModels.count
        let offset = CGFloat(timerCount * 30)
        
        x -= offset
        y -= offset
        
        // Ensure window stays on screen
        x = max(screenFrame.minX + 20, min(x, screenFrame.maxX - windowSize.width - 20))
        y = max(screenFrame.minY + 20, min(y, screenFrame.maxY - windowSize.height - 20))
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    // MARK: - Compact State Handling
    
    private func handleCompactStateChange(_ isCompact: Bool) {
        let targetSize: NSSize
        
        if isCompact {
            // Compact mode: small fixed size (running timer)
            targetSize = NSSize(width: 120, height: 50)
            // Disable click-through when compact (running timer needs to be clickable to pause)
            self.ignoresMouseEvents = false
        } else {
            // Full mode: dynamic size based on content (stopped, paused, or completed)
            targetSize = NSSize(width: 220, height: 140) // Slightly larger default
            self.ignoresMouseEvents = isClickThrough
        }
        
        resizeWindowToSize(targetSize, centered: true)
    }
    
    private func handleSizeChange(_ size: CGSize) {
        // Only resize for content changes when not in compact mode
        guard timerModel.state != .running else { return }
        
        let targetSize = NSSize(
            width: max(size.width, 200), // Minimum width
            height: max(size.height, 120) // Minimum height
        )
        
        // Smooth resize to accommodate content
        resizeWindowToSize(targetSize, centered: true)
    }
    
    private func resizeWindowToSize(_ newSize: NSSize, centered: Bool) {
        let currentFrame = self.frame
        let newOrigin: NSPoint
        
        if centered {
            // Calculate new origin to keep window centered around the same point
            newOrigin = NSPoint(
                x: currentFrame.origin.x + (currentFrame.width - newSize.width) / 2,
                y: currentFrame.origin.y + (currentFrame.height - newSize.height) / 2
            )
        } else {
            newOrigin = currentFrame.origin
        }
        
        let newFrame = NSRect(origin: newOrigin, size: newSize)
        
        // Animate the size change with spring timing
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2 // 200ms as requested
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.5, 0.0, 0.2, 1.0) // Spring-like easing
            self.animator().setFrame(newFrame, display: true, animate: true)
        }
        
        // Ensure window stays on screen after resize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.ensureOnScreen()
        }
    }
    
    private func ensureOnScreen() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        var windowFrame = self.frame
        
        // Adjust if window is off screen
        if windowFrame.maxX > screenFrame.maxX {
            windowFrame.origin.x = screenFrame.maxX - windowFrame.width - 10
        }
        if windowFrame.minX < screenFrame.minX {
            windowFrame.origin.x = screenFrame.minX + 10
        }
        if windowFrame.maxY > screenFrame.maxY {
            windowFrame.origin.y = screenFrame.maxY - windowFrame.height - 10
        }
        if windowFrame.minY < screenFrame.minY {
            windowFrame.origin.y = screenFrame.minY + 10
        }
        
        if !NSEqualRects(windowFrame, self.frame) {
            self.setFrame(windowFrame, display: true)
        }
    }
    
    // MARK: - Click-through Toggle
    
    func toggleClickThrough() {
        // Only allow click-through when not in compact mode (not running)
        guard timerModel.state != .running else { return }
        
        isClickThrough.toggle()
        
        if isClickThrough {
            self.ignoresMouseEvents = true
            self.level = .screenSaver
            // Visual indicator for click-through mode
            self.alphaValue = 0.7
        } else {
            self.ignoresMouseEvents = false
            self.level = .floating
            self.alphaValue = 1.0
        }
    }
    
    // MARK: - Snap to Corners
    
    private func snapToCorner() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = self.frame
        let snapDistance: CGFloat = 50
        
        var newX = windowFrame.origin.x
        var newY = windowFrame.origin.y
        
        // Check for snap to corners
        let leftDistance = windowFrame.origin.x - screenFrame.minX
        let rightDistance = screenFrame.maxX - windowFrame.maxX
        let topDistance = screenFrame.maxY - windowFrame.maxY
        let bottomDistance = windowFrame.origin.y - screenFrame.minY
        
        // Snap to left/right
        if leftDistance < snapDistance {
            newX = screenFrame.minX + 10
        } else if rightDistance < snapDistance {
            newX = screenFrame.maxX - windowFrame.width - 10
        }
        
        // Snap to top/bottom
        if topDistance < snapDistance {
            newY = screenFrame.maxY - windowFrame.height - 10
        } else if bottomDistance < snapDistance {
            newY = screenFrame.minY + 10
        }
        
        if newX != windowFrame.origin.x || newY != windowFrame.origin.y {
            self.setFrameOrigin(NSPoint(x: newX, y: newY))
        }
    }
    
    // MARK: - Window Events
    
    override func mouseDown(with event: NSEvent) {
        initialLocation = event.locationInWindow
        isDragging = true
        super.mouseDown(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        
        let currentLocation = event.locationInWindow
        let deltaX = currentLocation.x - initialLocation.x
        let deltaY = currentLocation.y - initialLocation.y
        
        let newOrigin = NSPoint(
            x: self.frame.origin.x + deltaX,
            y: self.frame.origin.y + deltaY
        )
        
        self.setFrameOrigin(newOrigin)
        super.mouseDragged(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        if isDragging {
            isDragging = false
            snapToCorner()  // Snap to corners after drag
        }
        super.mouseUp(with: event)
    }
    
    // MARK: - Timer Management
    
    private func deleteTimer() {
        // Use direct controller reference to close this timer
        controller?.closeTimer(id: timerModel.id)
    }
    
    // MARK: - Window Lifecycle
    
    override var canBecomeKey: Bool {
        return true // Allow window to become key for text input
    }
    
    override var acceptsFirstResponder: Bool {
        return true // Allow text field focus
    }
    
    override func becomeKey() {
        super.becomeKey()
        // Make sure window is visible when it becomes key
        self.makeKeyAndOrderFront(nil)
    }
    
    override func miniaturize(_ sender: Any?) {
        // Prevent minimization - floating timers should stay visible
        // Just ignore the miniaturize request
    }
    
    override func close() {
        NotificationCenter.default.removeObserver(self)
        super.close()
    }
}

// MARK: - Extensions

extension NSWindow {
    func setFrameAutosaveName(_ name: String) {
        // Custom implementation for frame autosaving
        self.identifier = NSUserInterfaceItemIdentifier(name)
        
        if let savedFrame = UserDefaults.standard.string(forKey: "WindowFrame_\(name)") {
            let rect = NSRectFromString(savedFrame)
            if !rect.isEmpty {
                self.setFrame(rect, display: true)
            }
        }
        
        // Save frame on close
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: self,
            queue: .main
        ) { _ in
            UserDefaults.standard.set(NSStringFromRect(self.frame), forKey: "WindowFrame_\(name)")
        }
    }
}
