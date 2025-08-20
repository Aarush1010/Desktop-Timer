//
//  TimerView.swift
//  TimerApp
//
//  Created by Desktop Timer on 8/19/25.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var timerModel: TimerModel
    let isFloating: Bool
    
    @AppStorage("timer_theme") private var selectedTheme: String = "system"
    @AppStorage("timer_opacity") private var windowOpacity: Double = 1.0
    
    @State private var showingControls = true
    @State private var hoveringOverWindow = false
    @State private var isCompact = false
    @State private var needsWindowResize = false
    @State private var manuallyExpanded = false // Track manual expansion
    @State private var isEditingTitle = false // Track title editing
    @State private var editingTitle = "" // Temporary title while editing
    
    // Closure to notify parent window of size changes
    var onCompactStateChange: ((Bool) -> Void)?
    var onSizeChange: ((CGSize) -> Void)?
    var onDelete: (() -> Void)?
    
    init(timerModel: TimerModel, isFloating: Bool = false, onCompactStateChange: ((Bool) -> Void)? = nil, onSizeChange: ((CGSize) -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.timerModel = timerModel
        self.isFloating = isFloating
        self.onCompactStateChange = onCompactStateChange
        self.onSizeChange = onSizeChange
        self.onDelete = onDelete
    }
    
    var body: some View {
        Group {
            if isFloating && isCompact {
                // Compact mode: only countdown text, centered
                compactTimerView
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            } else {
                // Full mode: all controls
                fullTimerView
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isCompact)
        .opacity(windowOpacity)
        .preferredColorScheme(colorScheme)
        .onChange(of: timerModel.state) { newState in
            updateCompactState(for: newState)
        }
        .onAppear {
            // Start in expanded form for new timers
            isCompact = false
            showingControls = true
            manuallyExpanded = false
            updateCompactState(for: timerModel.state)
        }
    }
    
    // MARK: - Compact Timer View
    
    private var compactTimerView: some View {
        Text(timerModel.formattedTime)
            .font(.system(.title2, design: .monospaced))
            .fontWeight(.medium)
            .foregroundColor(timeColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(compactBackgroundView)
            .contentShape(Rectangle()) // Makes entire area draggable and clickable
            .frame(width: 120, height: 50)
            .contentTransition(.numericText())
            .onTapGesture(count: 2) {
                // Double-click to expand to full view
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    manuallyExpanded = true
                    isCompact = false
                    showingControls = true
                }
                
                // Notify parent window
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    onCompactStateChange?(false)
                }
            }
            .onTapGesture {
                // Single click to pause when in compact mode
                if timerModel.state == .running {
                    timerModel.pause()
                }
            }
            .help("Click to pause • Double-click to expand")
    }
    
    // MARK: - Full Timer View
    
    private var fullTimerView: some View {
        VStack(spacing: isFloating ? 8 : 12) {
            // Always show header for floating windows so users can edit title
            if isFloating {
                headerView
            }
            
            timeDisplayView
            
            // Controls section with consistent spacing
            if showingControls {
                if isCompact && isFloating {
                    compactControlsView
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                } else {
                    fullControlsView
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
            }
            
            // Always show presets when in expanded view (not auto-compact)
            if !isCompact {
                presetsView
            }
        }
        .padding(isFloating ? 12 : 16)
        .background(backgroundView)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: showingControls)
        .onHover { hovering in
            handleHoverChange(hovering)
        }
        .background(
            // Invisible background to capture size changes
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        notifySizeChange(geometry.size)
                    }
                    .onChange(of: geometry.size) { newSize in
                        notifySizeChange(newSize)
                    }
                    .onChange(of: showingControls) { _ in
                        // Trigger size update when controls visibility changes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            notifySizeChange(geometry.size)
                        }
                    }
            }
        )
    }
    
    private func handleHoverChange(_ hovering: Bool) {
        if isFloating && !isCompact {
            // For floating windows, always show controls when expanded - no hover hiding
            let newShowingControls = true
            
            if newShowingControls != showingControls {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    showingControls = newShowingControls
                    hoveringOverWindow = hovering
                }
            }
        }
    }
    
    private func notifySizeChange(_ size: CGSize) {
        // Add padding to the measured size
        let paddedSize = CGSize(
            width: size.width + (isFloating ? 24 : 32), // Account for padding
            height: size.height + (isFloating ? 24 : 32)
        )
        onSizeChange?(paddedSize)
    }
    
    // MARK: - Compact State Management
    
    private func updateCompactState(for state: TimerState) {
        // Only be compact when floating AND (running OR completed) AND not manually expanded
        // Stay compact when completed to show the red attention-grabbing bubble
        let shouldBeCompact = isFloating && (state == .running || state == .completed) && !manuallyExpanded
        
        if shouldBeCompact != isCompact {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isCompact = shouldBeCompact
                
                // When expanding from compact, ensure controls are shown
                if !shouldBeCompact && isFloating {
                    showingControls = true
                }
            }
            
            // Notify parent window of state change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                onCompactStateChange?(shouldBeCompact)
            }
        }
        
        // Reset manual expansion when timer is stopped/reset (allow auto-compact on next run)
        if state == .stopped {
            manuallyExpanded = false
            // Ensure expanded view for stopped timers
            if isFloating {
                showingControls = true
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            // Editable title
            if isEditingTitle {
                TextField("Timer Name", text: $editingTitle)
                    .font(.headline)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        finishEditingTitle()
                    }
                    .onAppear {
                        editingTitle = timerModel.title
                    }
            } else {
                Text(timerModel.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .onTapGesture {
                        startEditingTitle()
                    }
                    .help("Click to rename timer")
            }
            
            Spacer()
            
            // No minimize button - timer auto-compacts when running
        }
    }
    
    // MARK: - Title Editing Methods
    
    private func startEditingTitle() {
        editingTitle = timerModel.title
        isEditingTitle = true
    }
    
    private func finishEditingTitle() {
        let trimmedTitle = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            timerModel.title = trimmedTitle
        }
        isEditingTitle = false
    }
    
    private func cancelEditingTitle() {
        isEditingTitle = false
        editingTitle = ""
    }
    
    // MARK: - Time Display
    
    private var timeDisplayView: some View {
        VStack(spacing: 4) {
            if timerModel.state == .stopped {
                timeInputView
            } else {
                runningTimeView
            }
            
            // Progress indicator
            if timerModel.totalTime > 0 {
                ProgressView(value: timerModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .frame(height: 4)
            }
        }
    }
    
    private var timeInputView: some View {
        HStack(spacing: 8) {
            TimeInputField(value: $timerModel.inputHours, placeholder: "00", label: "h")
            Text(":")
            TimeInputField(value: $timerModel.inputMinutes, placeholder: "00", label: "m")
            Text(":")
            TimeInputField(value: $timerModel.inputSeconds, placeholder: "00", label: "s")
        }
        .font(.system(.title, design: .monospaced))
    }
    
    private var runningTimeView: some View {
        Text(isCompact && isFloating ? timerModel.compactFormattedTime : timerModel.formattedTime)
            .font(.system(isFloating && isCompact ? .title2 : .largeTitle, design: .monospaced))
            .fontWeight(.medium)
            .foregroundColor(timeColor)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.3), value: timerModel.remainingTime)
    }
    
    // MARK: - Controls
    
    private var fullControlsView: some View {
        HStack(spacing: 12) {
            // Start/Pause/Resume button
            Button(action: timerModel.toggle) {
                Image(systemName: startPauseIcon)
                    .font(.title2)
                    .frame(width: 44, height: 32)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(timerModel.state == .stopped && !hasValidInput)
            .help(startPauseHelpText)
            
            // Reset button
            Button(action: timerModel.reset) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .frame(width: 44, height: 32)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(timerModel.state == .stopped)
            .help("Reset Timer")
            
            // Delete button
            if isFloating {
                Button(action: {
                    onDelete?()
                }) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .frame(width: 44, height: 32)
                }
                .buttonStyle(DeleteButtonStyle())
                .help("Delete Timer")
            }
        }
    }
    
    private var compactControlsView: some View {
        HStack(spacing: 8) {
            Button(action: timerModel.toggle) {
                Image(systemName: startPauseIcon)
                    .font(.caption)
            }
            .buttonStyle(CompactButtonStyle())
            .disabled(timerModel.state == .stopped && !hasValidInput)
            
            Button(action: timerModel.reset) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(CompactButtonStyle())
            .disabled(timerModel.state == .stopped)
            
            // Delete button for compact view
            if isFloating {
                Button(action: {
                    onDelete?()
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(CompactDeleteButtonStyle())
            }
        }
    }
    
    // MARK: - Quick Presets
    
    private var presetsView: some View {
        HStack(spacing: 8) {
            ForEach([5, 10, 25, 50], id: \.self) { minutes in
                Button("\(minutes)m") {
                    timerModel.setPreset(minutes: minutes)
                }
                .buttonStyle(PresetButtonStyle())
                .disabled(timerModel.state != .stopped)
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: isFloating ? 12 : 8)
            .fill(backgroundMaterial)
            .shadow(
                color: shadowColor,
                radius: isFloating ? 8 : 4,
                x: 0,
                y: isFloating ? 4 : 2
            )
    }
    
    // MARK: - Computed Properties
    
    private var hasValidInput: Bool {
        let hours = Double(timerModel.inputHours) ?? 0
        let minutes = Double(timerModel.inputMinutes) ?? 0
        let seconds = Double(timerModel.inputSeconds) ?? 0
        return hours + minutes + seconds > 0
    }
    
    private var startPauseIcon: String {
        switch timerModel.state {
        case .stopped, .paused:
            return "play.fill"
        case .running:
            return "pause.fill"
        case .completed:
            return "arrow.clockwise"
        }
    }
    
    private var startPauseHelpText: String {
        switch timerModel.state {
        case .stopped:
            return "Start Timer"
        case .paused:
            return "Resume Timer"
        case .running:
            return "Pause Timer"
        case .completed:
            return "Reset Timer"
        }
    }
    
    private var timeColor: Color {
        switch timerModel.state {
        case .running:
            return timerModel.remainingTime < 60 ? .orange : .primary
        case .paused:
            return .orange
        case .completed:
            // White text on red background in compact mode, red text otherwise
            return isCompact ? .white : .red
        default:
            return .primary
        }
    }
    
    private var progressColor: Color {
        switch timerModel.state {
        case .running:
            return timerModel.remainingTime < 60 ? .orange : .blue
        case .paused:
            return .orange
        case .completed:
            return .red
        default:
            return .blue
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
    
    private var backgroundMaterial: Material {
        switch selectedTheme {
        case "light":
            return .regularMaterial
        case "dark":
            return .ultraThickMaterial
        default:
            return .regularMaterial
        }
    }
    
    private var shadowColor: Color {
        selectedTheme == "dark" ? .white.opacity(0.1) : .black.opacity(0.2)
    }
    
    // MARK: - Compact Background
    
    private var compactBackgroundView: some View {
        RoundedRectangle(cornerRadius: 25) // More rounded for compact mode
            .fill(compactBackgroundFill)
            .shadow(
                color: shadowColor,
                radius: 6,
                x: 0,
                y: 3
            )
    }
    
    // Background fill that changes to bright red when timer completes
    private var compactBackgroundFill: AnyShapeStyle {
        if timerModel.state == .completed {
            // Bright red background when completed to grab attention
            return AnyShapeStyle(Color.red.opacity(0.8))
        } else {
            return AnyShapeStyle(backgroundMaterial)
        }
    }
}

// MARK: - Time Input Field

struct TimeInputField: View {
    @Binding var value: String
    let placeholder: String
    let label: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            TextField(placeholder, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.center)
                .frame(width: 50)
                .font(.system(.title, design: .monospaced))
                .focused($isFocused)
                .onTapGesture {
                    isFocused = true
                }
                .onChange(of: value) { newValue in
                    // Limit input to 2 digits for minutes/seconds, 3 for hours
                    let maxLength = label == "h" ? 3 : 2
                    if newValue.count > maxLength {
                        value = String(newValue.prefix(maxLength))
                    }
                    // Only allow digits
                    value = value.filter { $0.isNumber }
                }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CompactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .frame(width: 24, height: 20)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PresetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.1))
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DeleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CompactDeleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(width: 24, height: 20)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.red)
                    .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview (disabled for SPM build compatibility)

/*
#Preview {
    let timerModel = TimerModel()
    return TimerView(timerModel: timerModel)
        .frame(width: 300, height: 400)
}
*/
