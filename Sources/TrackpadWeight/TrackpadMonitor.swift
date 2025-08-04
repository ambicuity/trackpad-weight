#if canImport(Cocoa)
import Foundation
import IOKit
import IOKit.hid
import CoreFoundation
import Cocoa

/**
 * Enhanced TrackpadMonitor using Open Multi-Touch Support library
 * Provides precise pressure readings from trackpad multitouch data
 */
class TrackpadMonitor {
    private var multitouchManager: MultitouchManager?
    private let weightCallback: (Double) -> Void
    private var isMonitoring = false
    
    init(weightCallback: @escaping (Double) -> Void) {
        self.weightCallback = weightCallback
        
        // Create multitouch manager with our weight callback
        multitouchManager = MultitouchManager(pressureCallback: weightCallback)
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        if let success = multitouchManager?.startMonitoring(), success {
            isMonitoring = true
            print("TrackpadMonitor: Started multitouch monitoring successfully")
        } else {
            print("TrackpadMonitor: Failed to start multitouch monitoring")
            
            // Fallback to Force Touch monitoring if multitouch fails
            print("TrackpadMonitor: Falling back to Force Touch monitoring")
            startForceTouch()
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        multitouchManager?.stopMonitoring()
        isMonitoring = false
        print("TrackpadMonitor: Stopped monitoring")
    }
    
    func calibrate() {
        multitouchManager?.calibrate()
    }
    
    // MARK: - Force Touch Fallback
    
    private var eventMonitor: Any?
    private var calibrationOffset: Double = 0.0
    
    private func startForceTouch() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.pressure, .leftMouseDown, .leftMouseUp]) { [weak self] event in
            self?.handlePressureEvent(event)
        }
        
        // Also monitor local events
        NSEvent.addLocalMonitorForEvents(matching: [.pressure, .leftMouseDown, .leftMouseUp]) { [weak self] event in
            self?.handlePressureEvent(event)
            return event
        }
        
        isMonitoring = true
        print("TrackpadMonitor: Force Touch fallback monitoring started")
    }
    
    private func handlePressureEvent(_ event: NSEvent) {
        let pressure = event.pressure
        let weight = convertPressureToWeight(Double(pressure))
        weightCallback(weight)
    }
    
    private func convertPressureToWeight(_ pressure: Double) -> Double {
        // Handle invalid pressure values
        if pressure.isNaN || pressure.isInfinite {
            return 0.0
        }
        
        // Clamp pressure to reasonable bounds (Force Touch pressure can exceed 1.0)
        let clampedPressure = max(0.0, min(pressure, 3.0))
        
        // Force Touch pressure ranges from 0.0 to 1.0+
        // Scale to weight in grams - this is a fallback calibration
        let baseWeight = clampedPressure * 300.0
        let calibratedWeight = (baseWeight - calibrationOffset)
        
        return max(0.0, calibratedWeight)
    }
}

// Enhanced approach using MultitouchSupport with NSEvent fallback
class ForceTrackpadMonitor {
    private var multitouchManager: MultitouchManager?
    private var eventMonitor: Any?
    private let weightCallback: (Double) -> Void
    private var calibrationOffset: Double = 0.0
    private var isUsingMultitouch = false
    private var hasReceivedMultitouchData = false
    private var fallbackTimer: Timer?
    
    init(weightCallback: @escaping (Double) -> Void) {
        self.weightCallback = weightCallback
        
        // Try to create multitouch manager first
        multitouchManager = MultitouchManager(pressureCallback: { [weak self] weight in
            self?.hasReceivedMultitouchData = true
            self?.fallbackTimer?.invalidate()
            self?.fallbackTimer = nil
            weightCallback(weight)
        })
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        // First try multitouch support for better precision
        if let multitouchManager = multitouchManager,
           multitouchManager.startMonitoring() {
            isUsingMultitouch = true
            print("ForceTrackpadMonitor: Using enhanced multitouch support")
            
            // Set up fallback timer in case multitouch doesn't work
            fallbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                if self?.hasReceivedMultitouchData != true {
                    print("ForceTrackpadMonitor: No multitouch data received after 3 seconds, falling back to NSEvent")
                    self?.multitouchManager?.stopMonitoring()
                    self?.isUsingMultitouch = false
                    self?.startNSEventMonitoring()
                }
            }
            return
        }
        
        // Fallback to NSEvent Force Touch monitoring
        print("ForceTrackpadMonitor: Multitouch failed, falling back to NSEvent Force Touch")
        isUsingMultitouch = false
        startNSEventMonitoring()
    }
    
    private func startNSEventMonitoring() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.pressure, .leftMouseDown, .leftMouseUp]) { [weak self] event in
            self?.handlePressureEvent(event)
        }
        
        // Also monitor local events
        NSEvent.addLocalMonitorForEvents(matching: [.pressure, .leftMouseDown, .leftMouseUp]) { [weak self] event in
            self?.handlePressureEvent(event)
            return event
        }
        
        print("ForceTrackpadMonitor: Using Force Touch monitoring (fallback)")
    }
    
    func stopMonitoring() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        
        if isUsingMultitouch {
            multitouchManager?.stopMonitoring()
        } else {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
        print("ForceTrackpadMonitor: Stopped monitoring")
    }
    
    private func handlePressureEvent(_ event: NSEvent) {
        let pressure = event.pressure
        let stage = event.stage
        
        #if DEBUG
        print("ForceTrackpadMonitor: NSEvent - Pressure: \(pressure), Stage: \(stage)")
        #endif
        
        // Convert pressure to weight
        let weight = convertPressureToWeight(Double(pressure))
        weightCallback(weight)
    }
    
    private func convertPressureToWeight(_ pressure: Double) -> Double {
        // Handle invalid pressure values
        if pressure.isNaN || pressure.isInfinite {
            return 0.0
        }
        
        // Clamp pressure to reasonable bounds (Force Touch pressure can exceed 1.0)
        let clampedPressure = max(0.0, min(pressure, 3.0))
        
        // Force Touch pressure ranges from 0.0 to 1.0+
        // Scale to weight in grams - improved scaling for better sensitivity
        let baseWeight = clampedPressure * 500.0  // Increased from 300.0 for better detection
        let calibratedWeight = (baseWeight - calibrationOffset)
        
        let finalWeight = max(0.0, calibratedWeight)
        
        #if DEBUG
        if pressure > 0 {
            print("ForceTrackpadMonitor: Pressure \(pressure) -> Weight \(finalWeight)g (base: \(baseWeight), offset: \(calibrationOffset))")
        }
        #endif
        
        return finalWeight
    }
    
    func calibrate() {
        if isUsingMultitouch {
            multitouchManager?.calibrate()
        } else {
            calibrationOffset = 0.0
        }
        print("ForceTrackpadMonitor: Calibration complete")
    }
}

#else
// Stub implementations for non-macOS platforms
import Foundation

class TrackpadMonitor {
    private let weightCallback: (Double) -> Void
    
    init(weightCallback: @escaping (Double) -> Void) {
        self.weightCallback = weightCallback
    }
    
    func startMonitoring() {
        print("TrackpadMonitor: macOS required for actual trackpad monitoring")
    }
    
    func stopMonitoring() {
        print("TrackpadMonitor: Stopped (stub)")
    }
    
    func calibrate() {
        print("TrackpadMonitor: Calibration (stub)")
    }
}

class ForceTrackpadMonitor {
    private let weightCallback: (Double) -> Void
    
    init(weightCallback: @escaping (Double) -> Void) {
        self.weightCallback = weightCallback
    }
    
    func startMonitoring() {
        print("ForceTrackpadMonitor: macOS required for Force Touch monitoring")
    }
    
    func stopMonitoring() {
        print("ForceTrackpadMonitor: Stopped (stub)")
    }
    
    func calibrate() {
        print("ForceTrackpadMonitor: Calibration (stub)")
    }
}
#endif