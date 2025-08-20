//
//  TimerModelTests.swift
//  TimerAppTests
//
//  Created by Desktop Timer on 8/19/25.
//

import XCTest
@testable import TimerApp

final class TimerModelTests: XCTestCase {
    var timerModel: TimerModel!
    
    override func setUpWithError() throws {
        timerModel = TimerModel()
    }
    
    override func tearDownWithError() throws {
        timerModel = nil
    }
    
    // MARK: - Time Input Parsing Tests
    
    func testTimeInputParsing() throws {
        // Test valid inputs
        timerModel.setTime(hours: 1, minutes: 30, seconds: 45)
        let expectedTime: TimeInterval = 1 * 3600 + 30 * 60 + 45 // 5445 seconds
        
        // Access private method through a test helper
        let parsedTime = timerModel.parseTimeInputForTesting()
        XCTAssertEqual(parsedTime, expectedTime, accuracy: 0.1)
    }
    
    func testZeroTimeInput() throws {
        timerModel.setTime(hours: 0, minutes: 0, seconds: 0)
        let parsedTime = timerModel.parseTimeInputForTesting()
        XCTAssertNil(parsedTime)
    }
    
    func testMinutesOnlyInput() throws {
        timerModel.setTime(minutes: 25)
        let expectedTime: TimeInterval = 25 * 60 // 1500 seconds
        let parsedTime = timerModel.parseTimeInputForTesting()
        XCTAssertEqual(parsedTime, expectedTime, accuracy: 0.1)
    }
    
    func testSecondsOnlyInput() throws {
        timerModel.setTime(seconds: 90)
        let expectedTime: TimeInterval = 90
        let parsedTime = timerModel.parseTimeInputForTesting()
        XCTAssertEqual(parsedTime, expectedTime, accuracy: 0.1)
    }
    
    // MARK: - Timer State Tests
    
    func testInitialState() throws {
        XCTAssertEqual(timerModel.state, .stopped)
        XCTAssertEqual(timerModel.remainingTime, 0)
        XCTAssertEqual(timerModel.totalTime, 0)
    }
    
    func testTimerStart() throws {
        timerModel.setTime(minutes: 5)
        timerModel.start()
        
        XCTAssertEqual(timerModel.state, .running)
        XCTAssertEqual(timerModel.totalTime, 300, accuracy: 0.1) // 5 minutes
        XCTAssertEqual(timerModel.remainingTime, 300, accuracy: 1.0) // Allow 1 second tolerance
    }
    
    func testTimerPause() throws {
        timerModel.setTime(minutes: 5)
        timerModel.start()
        
        // Wait a short time then pause
        let expectation = XCTestExpectation(description: "Timer runs briefly")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.timerModel.pause()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(timerModel.state, .paused)
        XCTAssertLessThan(timerModel.remainingTime, 300) // Should have decreased
    }
    
    func testTimerReset() throws {
        timerModel.setTime(minutes: 5)
        timerModel.start()
        
        // Wait then reset
        let expectation = XCTestExpectation(description: "Timer runs briefly")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.timerModel.reset()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(timerModel.state, .stopped)
        XCTAssertEqual(timerModel.remainingTime, 0)
        XCTAssertEqual(timerModel.totalTime, 0)
    }
    
    // MARK: - Quick Presets Tests
    
    func testQuickPresets() throws {
        let presets = [5, 10, 25, 50]
        
        for preset in presets {
            timerModel.setPreset(minutes: preset)
            let parsedTime = timerModel.parseTimeInputForTesting()
            XCTAssertEqual(parsedTime, TimeInterval(preset * 60), accuracy: 0.1)
        }
    }
    
    // MARK: - Time Formatting Tests
    
    func testFormattedTimeDisplay() throws {
        // Test hours, minutes, seconds
        timerModel.remainingTime = 3661 // 1:01:01
        XCTAssertEqual(timerModel.formattedTime, "1:01:01")
        
        // Test minutes, seconds only
        timerModel.remainingTime = 125 // 2:05
        XCTAssertEqual(timerModel.formattedTime, "02:05")
        
        // Test zero time
        timerModel.remainingTime = 0
        XCTAssertEqual(timerModel.formattedTime, "00:00")
    }
    
    func testCompactFormattedTime() throws {
        // Test hours
        timerModel.remainingTime = 3661 // 1:01:01
        XCTAssertEqual(timerModel.compactFormattedTime, "1h 1m")
        
        // Test minutes
        timerModel.remainingTime = 125 // 2:05
        XCTAssertEqual(timerModel.compactFormattedTime, "2m 5s")
        
        // Test seconds only
        timerModel.remainingTime = 30
        XCTAssertEqual(timerModel.compactFormattedTime, "30s")
    }
    
    // MARK: - Progress Calculation Tests
    
    func testProgressCalculation() throws {
        timerModel.totalTime = 100
        timerModel.remainingTime = 75
        
        let expectedProgress = 0.25 // 25% complete
        XCTAssertEqual(timerModel.progress, expectedProgress, accuracy: 0.01)
    }
    
    func testProgressBounds() throws {
        timerModel.totalTime = 100
        
        // Test 0% progress (full time remaining)
        timerModel.remainingTime = 100
        XCTAssertEqual(timerModel.progress, 0.0, accuracy: 0.01)
        
        // Test 100% progress (no time remaining)
        timerModel.remainingTime = 0
        XCTAssertEqual(timerModel.progress, 1.0, accuracy: 0.01)
        
        // Test invalid case (more time remaining than total)
        timerModel.remainingTime = 150
        XCTAssertEqual(timerModel.progress, 0.0, accuracy: 0.01)
    }
    
    // MARK: - Settings Persistence Tests
    
    func testSettingsPersistence() throws {
        // Set custom settings
        timerModel.soundEnabled = false
        timerModel.notificationEnabled = false
        timerModel.flashEnabled = true
        timerModel.selectedSoundName = "Ping"
        
        // Save settings
        timerModel.saveSettings()
        
        // Create new instance and verify persistence
        let newTimerModel = TimerModel()
        XCTAssertEqual(newTimerModel.soundEnabled, false)
        XCTAssertEqual(newTimerModel.notificationEnabled, false)
        XCTAssertEqual(newTimerModel.flashEnabled, true)
        XCTAssertEqual(newTimerModel.selectedSoundName, "Ping")
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "timer_sound_enabled")
        UserDefaults.standard.removeObject(forKey: "timer_notification_enabled")
        UserDefaults.standard.removeObject(forKey: "timer_flash_enabled")
        UserDefaults.standard.removeObject(forKey: "timer_sound_name")
    }
    
    // MARK: - Timer Completion Tests
    
    func testTimerCompletion() throws {
        // Set a very short timer for testing
        timerModel.setTime(seconds: 1)
        timerModel.start()
        
        let expectation = XCTestExpectation(description: "Timer completes")
        
        // Wait for timer to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.timerModel.state, .completed)
            XCTAssertEqual(self.timerModel.remainingTime, 0, accuracy: 0.1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Performance Tests
    
    func testTimerUpdatePerformance() throws {
        timerModel.setTime(minutes: 10)
        
        measure {
            // Simulate many timer updates
            for _ in 0..<1000 {
                timerModel.remainingTime = Double.random(in: 0...600)
                _ = timerModel.formattedTime
                _ = timerModel.progress
            }
        }
    }
}

// MARK: - Test Helpers

extension TimerModel {
    func parseTimeInputForTesting() -> TimeInterval? {
        let hours = Double(inputHours) ?? 0
        let minutes = Double(inputMinutes) ?? 0
        let seconds = Double(inputSeconds) ?? 0
        
        let totalSeconds = hours * 3600 + minutes * 60 + seconds
        return totalSeconds > 0 ? totalSeconds : nil
    }
}
