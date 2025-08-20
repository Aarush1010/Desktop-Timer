//
//  MenuBarView.swift
//  TimerApp
//
//  Created by Desktop Timer on 8/19/25.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var windowController: FloatingWindowController
    @State private var showingPreferences = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Active Timers Section
            if !windowController.timerModels.isEmpty {
                Section("Active Timers") {
                    ForEach(windowController.timerModels) { timer in
                        MenuBarTimerItem(timer: timer, windowController: windowController)
                    }
                }
                
                Divider()
            }
            
            // Quick Actions
            Button("New Timer") {
                _ = windowController.createNewTimer()
            }
            .keyboardShortcut("n", modifiers: .command)
            
            if !windowController.timerModels.isEmpty {
                Button("Show All Timers") {
                    for timer in windowController.timerModels {
                        windowController.showTimer(id: timer.id)
                    }
                }
                .keyboardShortcut("a", modifiers: .command)
                
                Button("Hide All Timers") {
                    for timer in windowController.timerModels {
                        windowController.hideTimer(id: timer.id)
                    }
                }
                .keyboardShortcut("h", modifiers: .command)
            }
            
            Divider()
            
            // Preferences and About
            Button("Preferences...") {
                showingPreferences = true
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Button("About TimerApp") {
                NSApp.orderFrontStandardAboutPanel(nil)
            }
            
            Divider()
            
            // Quit
            Button("Quit TimerApp") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

struct MenuBarTimerItem: View {
    @ObservedObject var timer: TimerModel
    let windowController: FloatingWindowController
    
    var body: some View {
        Menu {
            // Timer actions submenu
            Button(timer.state == .running ? "Pause" : "Start") {
                timer.toggle()
            }
            
            Button("Reset") {
                timer.reset()
            }
            
            Button("Show Window") {
                windowController.showTimer(id: timer.id)
            }
            
            Divider()
            
            Button("Close Timer") {
                windowController.closeTimer(id: timer.id)
            }
        } label: {
            HStack {
                // State indicator
                Image(systemName: stateIcon)
                    .foregroundColor(stateColor)
                    .font(.caption)
                
                // Timer title and time
                VStack(alignment: .leading, spacing: 1) {
                    Text(timer.title)
                        .font(.system(.body))
                    Text(timer.formattedTime)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private var stateIcon: String {
        switch timer.state {
        case .running:
            return "play.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .stopped:
            return "stop.circle"
        }
    }
    
    private var stateColor: Color {
        switch timer.state {
        case .running:
            return .green
        case .paused:
            return .orange
        case .completed:
            return .red
        case .stopped:
            return .gray
        }
    }
}

/*
#Preview {
    MenuBarView()
}
*/
