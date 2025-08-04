/**
 * Open Multi-Touch Support Integration for TrackWeight
 * Based on the Open Multi-Touch Support library by Takuto Nakamura (@Kyome22)
 * 
 * Provides access to private multitouch APIs for detailed trackpad pressure sensing
 */

#if canImport(Cocoa)
import Foundation
import CoreFoundation

// MARK: - Private MultitouchSupport Framework Types

typealias MTDeviceRef = UnsafeMutableRawPointer
typealias MTContactCallbackFunction = (MTDeviceRef, UnsafeMutablePointer<MTTouch>, Int32, Double, Int32) -> Int32

// Touch data structure matching the private MultitouchSupport framework
struct MTTouch {
    var frame: Int32
    var timestamp: Double
    var identifier: Int32
    var state: Int32           // Touch state (touching, not touching, etc.)
    var unknown1: Int32
    var unknown2: Int32
    var normalized: MTPoint    // Normalized coordinates (0.0 - 1.0)
    var size: Float           // Touch size
    var unknown3: Int32
    var angle: Float          // Touch angle
    var majorAxis: Float      // Major axis of ellipse
    var minorAxis: Float      // Minor axis of ellipse
    var absolute: MTPoint     // Absolute coordinates
    var unknown4: Int32
    var unknown5: Int32
    var density: Float        // Touch density/pressure
    var pressure: Float       // Touch pressure - this is key for weight calculation
    var unknown6: [Float]     // Additional unknown fields
    
    init() {
        frame = 0
        timestamp = 0
        identifier = 0
        state = 0
        unknown1 = 0
        unknown2 = 0
        normalized = MTPoint()
        size = 0
        unknown3 = 0
        angle = 0
        majorAxis = 0
        minorAxis = 0
        absolute = MTPoint()
        unknown4 = 0
        unknown5 = 0
        density = 0
        pressure = 0
        unknown6 = Array(repeating: 0, count: 16) // Estimated size for remaining fields
    }
}

struct MTPoint {
    var x: Float
    var y: Float
    
    init(x: Float = 0, y: Float = 0) {
        self.x = x
        self.y = y
    }
}

// MARK: - Private MultitouchSupport Framework Functions

@_silgen_name("MTDeviceCreateDefault")
private func MTDeviceCreateDefault() -> MTDeviceRef?

@_silgen_name("MTRegisterContactFrameCallback")
private func MTRegisterContactFrameCallback(_ device: MTDeviceRef, _ callback: MTContactCallbackFunction?) -> Void

@_silgen_name("MTDeviceStart")
private func MTDeviceStart(_ device: MTDeviceRef, _ unknown: Int32) -> Void

@_silgen_name("MTDeviceStop")
private func MTDeviceStop(_ device: MTDeviceRef) -> Void

@_silgen_name("MTDeviceRelease")
private func MTDeviceRelease(_ device: MTDeviceRef) -> Void

@_silgen_name("MTDeviceIsBuiltIn")
private func MTDeviceIsBuiltIn(_ device: MTDeviceRef) -> Bool

@_silgen_name("MTDeviceGetDeviceID")
private func MTDeviceGetDeviceID(_ device: MTDeviceRef) -> UInt64

// MARK: - MultitouchManager Class

/**
 * Manages multitouch input from trackpad using private MultitouchSupport framework
 * Provides detailed pressure and touch data for weight calculation
 */
class MultitouchManager {
    private var device: MTDeviceRef?
    private var isRunning = false
    private let pressureCallback: (Double) -> Void
    private var calibrationOffset: Double = 0.0
    private var activeTouches: [Int32: MTTouch] = [:]
    
    // Configuration
    private let pressureMultiplier: Double = 100.0  // Increase multiplier for better sensitivity
    private let minimumPressureThreshold: Double = 0.05  // Lower threshold for better detection
    
    init(pressureCallback: @escaping (Double) -> Void) {
        self.pressureCallback = pressureCallback
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Interface
    
    func startMonitoring() -> Bool {
        guard !isRunning else { return true }
        
        print("MultitouchManager: Attempting to start multitouch monitoring...")
        
        // Create default multitouch device
        guard let device = MTDeviceCreateDefault() else {
            print("MultitouchManager: Failed to create default multitouch device")
            return false
        }
        
        print("MultitouchManager: Created multitouch device successfully")
        
        // Verify this is a built-in trackpad
        guard MTDeviceIsBuiltIn(device) else {
            print("MultitouchManager: Device is not a built-in trackpad")
            MTDeviceRelease(device)
            return false
        }
        
        print("MultitouchManager: Verified device is built-in trackpad")
        
        self.device = device
        
        // Set this as the global manager before registering callback
        MultitouchManager.setGlobalManager(self)
        
        // Register callback for touch events
        print("MultitouchManager: Registering touch callback...")
        MTRegisterContactFrameCallback(device, touchCallback)
        
        print("MultitouchManager: Starting device monitoring...")
        MTDeviceStart(device, 0)
        
        isRunning = true
        print("MultitouchManager: Started monitoring trackpad touches")
        
        // Test with a small delay to see if callbacks start working
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("MultitouchManager: Monitoring active for 1 second, callbacks should be working now")
        }
        
        return true
    }
    
    func stopMonitoring() {
        guard isRunning, let device = device else { return }
        
        MTDeviceStop(device)
        MTDeviceRelease(device)
        
        // Clear global manager
        MultitouchManager.setGlobalManager(nil)
        
        self.device = nil
        isRunning = false
        activeTouches.removeAll()
        
        print("MultitouchManager: Stopped monitoring trackpad touches")
    }
    
    func calibrate() {
        // Calculate current total pressure as baseline
        let currentPressure = calculateTotalPressure()
        calibrationOffset = currentPressure
        
        print("MultitouchManager: Calibrated with offset \(calibrationOffset)g")
    }
    
    func isMonitoring() -> Bool {
        return isRunning
    }
    
    // MARK: - Private Methods
    
    private func calculateTotalPressure() -> Double {
        var totalPressure: Double = 0.0
        
        for touch in activeTouches.values {
            // Debug: Log touch state and pressure values
            #if DEBUG
            print("MultitouchManager: Touch ID \(touch.identifier), State: \(touch.state), Pressure: \(touch.pressure), Density: \(touch.density)")
            #endif
            
            // Accept multiple touch states that indicate actual contact
            // State 4 = MT_TOUCH_STATE_TOUCHING, but other states might also have valid pressure
            if touch.state >= 3 && touch.state <= 7 { // More inclusive state range
                // Pressure from MultitouchSupport is already in grams according to requirements
                let touchPressure = Double(touch.pressure) * pressureMultiplier
                
                // Also try using density as an alternative pressure source
                let densityPressure = Double(touch.density) * pressureMultiplier
                
                // Use whichever gives a higher reading
                let effectivePressure = max(touchPressure, densityPressure)
                totalPressure += max(0, effectivePressure)
                
                #if DEBUG
                print("MultitouchManager: Added pressure: \(effectivePressure)g (from pressure: \(touchPressure), density: \(densityPressure))")
                #endif
            }
        }
        
        #if DEBUG
        if !activeTouches.isEmpty {
            print("MultitouchManager: Total active touches: \(activeTouches.count), Total pressure: \(totalPressure)g")
        }
        #endif
        
        return totalPressure
    }
    
    internal func processTouchFrame(touches: UnsafePointer<MTTouch>, numTouches: Int32, timestamp: Double) {
        // Update active touches
        var currentTouchIds: Set<Int32> = []
        
        for i in 0..<Int(numTouches) {
            let touch = touches[i]
            currentTouchIds.insert(touch.identifier)
            activeTouches[touch.identifier] = touch
        }
        
        // Remove touches that are no longer present
        let touchesToRemove = activeTouches.keys.filter { !currentTouchIds.contains($0) }
        for touchId in touchesToRemove {
            activeTouches.removeValue(forKey: touchId)
        }
        
        // Calculate total weight and notify callback
        let totalPressure = calculateTotalPressure()
        let calibratedWeight = max(0, totalPressure - calibrationOffset)
        
        // Apply minimum threshold to reduce noise
        let finalWeight = calibratedWeight < minimumPressureThreshold ? 0.0 : calibratedWeight
        
        #if DEBUG
        if totalPressure > 0 || numTouches > 0 {
            print("MultitouchManager: Frame - Touches: \(numTouches), Total pressure: \(totalPressure)g, Calibrated: \(calibratedWeight)g, Final: \(finalWeight)g")
        }
        #endif
        
        pressureCallback(finalWeight)
    }
}

// MARK: - Global Callback Function

// Global callback function for multitouch events
// This needs to be a global C function for the private API
private var globalMultitouchManager: MultitouchManager?

private let touchCallback: MTContactCallbackFunction = { device, touchData, numTouches, timestamp, frame in
    #if DEBUG
    print("MultitouchSupport: Global callback received - Device: \(device), Touches: \(numTouches), Timestamp: \(timestamp)")
    #endif
    
    guard let manager = globalMultitouchManager,
          numTouches >= 0 else {
        #if DEBUG
        print("MultitouchSupport: No global manager or invalid touch count")
        #endif
        return 0
    }
    
    manager.processTouchFrame(touches: touchData, numTouches: numTouches, timestamp: timestamp)
    return 0
}

// MARK: - MultitouchManager Extension for Global Callback

extension MultitouchManager {
    static func setGlobalManager(_ manager: MultitouchManager?) {
        globalMultitouchManager = manager
    }
}

#else
// MARK: - Stub Implementation for Non-macOS Platforms

class MultitouchManager {
    private let pressureCallback: (Double) -> Void
    
    init(pressureCallback: @escaping (Double) -> Void) {
        self.pressureCallback = pressureCallback
    }
    
    func startMonitoring() -> Bool {
        print("MultitouchManager: macOS required for multitouch support")
        return false
    }
    
    func stopMonitoring() {
        print("MultitouchManager: Stopped (stub)")
    }
    
    func calibrate() {
        print("MultitouchManager: Calibration (stub)")
    }
    
    func isMonitoring() -> Bool {
        return false
    }
    
    static func setGlobalManager(_ manager: MultitouchManager?) {
        // Stub
    }
}

#endif