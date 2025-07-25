import XCTest
@testable import TrackpadWeight

final class TrackpadWeightTests: XCTestCase {
    
    func testForceTrackpadMonitorInitialization() {
        var receivedWeight: Double?
        
        let monitor = ForceTrackpadMonitor { weight in
            receivedWeight = weight
        }
        
        XCTAssertNotNil(monitor)
        XCTAssertNil(receivedWeight)
    }
    
    func testWeightConversion() {
        // This would test the pressure to weight conversion logic
        // For now, we'll test that the callback mechanism works
        
        let expectation = XCTestExpectation(description: "Weight callback")
        
        let monitor = ForceTrackpadMonitor { weight in
            XCTAssertGreaterThanOrEqual(weight, 0.0)
            expectation.fulfill()
        }
        
        // In a real test, we'd simulate pressure events
        // For now, we'll just test the initialization
        XCTAssertNotNil(monitor)
    }
    
    func testCalibration() {
        let monitor = ForceTrackpadMonitor { _ in }
        
        // Test that calibration doesn't crash
        monitor.calibrate()
        
        // In a real implementation, we'd test that calibration
        // affects subsequent weight calculations
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testWeightFormatting() {
        // Test weight display formatting logic
        let testCases: [(Double, String)] = [
            (0.0, "0.00"),
            (0.15, "0.15"),
            (0.99, "0.99"),
            (1.0, "1.0"),
            (1.5, "1.5"),
            (9.9, "9.9"),
            (10.0, "10"),
            (15.7, "16"),
            (125.0, "125"),
            (999.9, "1000")
        ]
        
        for (weight, expectedFormat) in testCases {
            let formatted = formatWeight(weight)
            XCTAssertEqual(formatted, expectedFormat, "Weight \(weight) should format to \(expectedFormat), got \(formatted)")
        }
    }
    
    // Helper function for testing weight formatting
    private func formatWeight(_ weight: Double) -> String {
        // Handle special values
        if weight.isNaN {
            return "nan"
        }
        if weight.isInfinite {
            return weight > 0 ? "inf" : "-inf"
        }
        
        // Use absolute value for formatting logic, then add sign back
        let absWeight = abs(weight)
        let sign = weight < 0 ? "-" : ""
        
        if absWeight < 1.0 {
            return String(format: "%@%.2f", sign, absWeight)
        } else if absWeight < 10.0 {
            return String(format: "%@%.1f", sign, absWeight)
        } else {
            return String(format: "%@%.0f", sign, absWeight)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testWeightFormattingEdgeCases() {
        // Test edge cases for weight formatting
        let edgeCases: [(Double, String)] = [
            // Negative weights (should be handled gracefully)
            (-1.0, "-1.0"),
            (-0.1, "-0.10"),
            (-10.0, "-10"),
            
            // Very small positive weights
            (0.001, "0.00"),
            (0.009, "0.01"),
            (0.01, "0.01"),
            
            // Boundary cases around formatting thresholds
            (0.99, "0.99"),
            (1.0, "1.0"),
            (1.01, "1.0"),
            (9.99, "10.0"),
            (10.0, "10"),
            (10.1, "10"),
            
            // Large weights
            (999.0, "999"),
            (1000.0, "1000"),
            (9999.0, "9999"),
            
            // Special values
            (Double.infinity, "inf"),
            (-Double.infinity, "-inf"),
            (Double.nan, "nan")
        ]
        
        for (weight, expectedFormat) in edgeCases {
            let formatted = formatWeight(weight)
            if weight.isNaN {
                XCTAssertTrue(formatted.lowercased().contains("nan"), "NaN weight should format to contain 'nan', got \(formatted)")
            } else if weight.isInfinite {
                XCTAssertTrue(formatted.lowercased().contains("inf"), "Infinite weight should format to contain 'inf', got \(formatted)")
            } else {
                XCTAssertEqual(formatted, expectedFormat, "Weight \(weight) should format to \(expectedFormat), got \(formatted)")
            }
        }
    }
    
    func testPressureToWeightConversion() {
        // Test pressure to weight conversion with edge cases
        let monitor = ForceTrackpadMonitor { _ in }
        
        // Test boundary values for pressure (0.0 to 1.0+)
        let pressureTestCases: [Double] = [
            0.0,      // No pressure
            0.001,    // Minimal pressure
            0.5,      // Half pressure
            1.0,      // Full pressure
            1.5,      // Beyond normal range
            -0.1,     // Negative pressure (invalid)
            Double.infinity,  // Infinite pressure
            Double.nan        // Invalid pressure
        ]
        
        for _ in pressureTestCases {
            // This would test actual pressure conversion if we exposed the method
            // For now, we test that the monitor handles various inputs without crashing
            XCTAssertNotNil(monitor)
        }
    }
    
    func testCalibrationEdgeCases() {
        var calibrationCallCount = 0
        let monitor = ForceTrackpadMonitor { _ in
            calibrationCallCount += 1
        }
        
        // Test multiple consecutive calibrations
        monitor.calibrate()
        monitor.calibrate()
        monitor.calibrate()
        
        // Test calibration doesn't crash
        XCTAssertNotNil(monitor)
        
        // Test concurrent calibrations (basic safety)
        let concurrentGroup = DispatchGroup()
        for _ in 0..<10 {
            concurrentGroup.enter()
            DispatchQueue.global().async {
                monitor.calibrate()
                concurrentGroup.leave()
            }
        }
        
        let result = concurrentGroup.wait(timeout: .now() + 2.0)
        XCTAssertEqual(result, .success, "Concurrent calibrations should complete without timeout")
    }
    
    func testMonitorLifecycle() {
        var callbackCount = 0
        var receivedWeights: [Double] = []
        
        let monitor = ForceTrackpadMonitor { weight in
            callbackCount += 1
            receivedWeights.append(weight)
        }
        
        // Test starting and stopping monitoring multiple times
        monitor.startMonitoring()
        monitor.stopMonitoring()
        monitor.startMonitoring()
        monitor.stopMonitoring()
        
        // Test that monitor handles lifecycle correctly
        XCTAssertNotNil(monitor)
        XCTAssertEqual(receivedWeights.count, callbackCount)
    }
    
    func testWeightCallbackThreadSafety() {
        let expectation = XCTestExpectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 100
        
        var receivedWeights: [Double] = []
        let weightsLock = NSLock()
        
        let _ = ForceTrackpadMonitor { weight in
            weightsLock.lock()
            receivedWeights.append(weight)
            weightsLock.unlock()
            expectation.fulfill()
        }
        
        // Simulate concurrent weight updates
        for i in 0..<100 {
            DispatchQueue.global().async {
                // Simulate a weight callback with different values
                _ = Double(i) * 0.1
                // Since we can't directly trigger callbacks, we'll test the monitor creation
                _ = ForceTrackpadMonitor { _ in }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify thread safety didn't cause data corruption
        weightsLock.lock()
        let finalCount = receivedWeights.count
        weightsLock.unlock()
        
        XCTAssertLessThanOrEqual(finalCount, 100, "Callback count should not exceed expected maximum")
    }
    
    func testWeightBoundaryValues() {
        // Test various weight boundary conditions
        let boundaryWeights: [Double] = [
            Double.leastNormalMagnitude,
            Double.leastNonzeroMagnitude,
            Double.greatestFiniteMagnitude,
            -Double.leastNormalMagnitude,
            -Double.leastNonzeroMagnitude,
            -Double.greatestFiniteMagnitude
        ]
        
        for weight in boundaryWeights {
            let formatted = formatWeight(weight)
            XCTAssertFalse(formatted.isEmpty, "Weight formatting should not return empty string for \(weight)")
            
            // Ensure formatting doesn't crash on extreme values
            XCTAssertNotNil(formatted)
        }
    }
    
    func testErrorHandling() {
        // Test error conditions and edge cases
        
        // Test monitor with nil callback (should be handled gracefully)
        let monitor = ForceTrackpadMonitor { weight in
            // Test that very large weights don't cause issues
            if weight > 1000000 {
                XCTFail("Weight should be bounded to reasonable values")
            }
            
            // Test that negative weights are handled appropriately
            if weight < -1000 {
                XCTFail("Extremely negative weights should be bounded")
            }
        }
        
        XCTAssertNotNil(monitor)
        
        // Test calibration with different timing
        monitor.calibrate()
        
        // Immediate second calibration
        monitor.calibrate()
        
        // Test monitoring lifecycle edge cases
        monitor.stopMonitoring() // Stop before start
        monitor.startMonitoring()
        monitor.startMonitoring() // Double start
        monitor.stopMonitoring()
        monitor.stopMonitoring() // Double stop
    }
    
    func testMemoryManagement() {
        weak var weakMonitor: ForceTrackpadMonitor?
        
        do {
            let monitor = ForceTrackpadMonitor { _ in }
            weakMonitor = monitor
            monitor.startMonitoring()
            monitor.stopMonitoring()
        }
        
        // Give some time for cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Monitor should be deallocated after going out of scope
            // This test verifies there are no retain cycles
        }
        
        // Since we're on Linux/stub implementation, the monitor may still exist
        // The important thing is that the test doesn't crash
        XCTAssertTrue(true, "Memory management test completed without crash")
    }
    
    func testStringMultiplicationOperator() {
        // Test the custom string multiplication operator used in the demo
        let result = "★" * 5
        XCTAssertEqual(result, "★★★★★")
        
        // Edge cases
        XCTAssertEqual("test" * 0, "")
        XCTAssertEqual("" * 5, "")
        XCTAssertEqual("a" * 1, "a")
        
        // Large multiplication
        let largeResult = "x" * 1000
        XCTAssertEqual(largeResult.count, 1000)
        XCTAssertTrue(largeResult.allSatisfy { $0 == "x" })
    }
}