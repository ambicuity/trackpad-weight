/**
 * AutoTareManager - Auto-Tare for Touch Start Feature
 * 
 * Implements Feature 3: Auto-Tare for Touch Start
 * - Automatically zero the scale whenever a new pressure session begins
 * - Optional toggle for this behavior
 * - Detects when finger contact is detected and automatically calibrates
 */

#if canImport(Cocoa)
import Foundation
import Cocoa

class AutoTareManager {
    private var isEnabled: Bool = true
    private var lastTouchTime: Date?
    private var touchTimeout: TimeInterval = 5.0 // No touch for 5 seconds = new session
    private var minimumPressureThreshold: Double = 0.05
    private var tareCallback: (() -> Void)?
    
    // Settings
    private let userDefaults = UserDefaults.standard
    private let autoTareEnabledKey = "auto_tare_enabled"
    private let touchTimeoutKey = "auto_tare_timeout"
    
    // State tracking
    private var isInTouchSession = false
    private var sessionStartTime: Date?
    private var hasAutoTaredThisSession = false
    
    init() {
        loadSettings()
    }
    
    // MARK: - Public Interface
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        saveSettings()
        print("AutoTareManager: Auto-tare \(enabled ? "enabled" : "disabled")")
    }
    
    func isAutoTareEnabled() -> Bool {
        return isEnabled
    }
    
    func setTouchTimeout(_ timeout: TimeInterval) {
        touchTimeout = max(1.0, min(timeout, 30.0)) // Clamp between 1-30 seconds
        saveSettings()
        print("AutoTareManager: Touch timeout set to \(touchTimeout)s")
    }
    
    func getTouchTimeout() -> TimeInterval {
        return touchTimeout
    }
    
    func setTareCallback(_ callback: @escaping () -> Void) {
        tareCallback = callback
    }
    
    func processWeightReading(_ weight: Double) {
        guard isEnabled else { return }
        
        let now = Date()
        let hasPressure = weight >= minimumPressureThreshold
        
        if hasPressure {
            handleTouchDetected(at: now)
        } else {
            handleNoTouch(at: now)
        }
        
        lastTouchTime = hasPressure ? now : lastTouchTime
    }
    
    func forceNewSession() {
        print("AutoTareManager: Forcing new session")
        endCurrentSession()
        hasAutoTaredThisSession = false
    }
    
    func getCurrentSessionInfo() -> (isActive: Bool, duration: TimeInterval?) {
        guard let startTime = sessionStartTime else {
            return (false, nil)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return (isInTouchSession, duration)
    }
    
    // MARK: - Private Methods
    
    private func handleTouchDetected(at time: Date) {
        let wasInSession = isInTouchSession
        
        // Check if this is a new session (after timeout)
        if let lastTouch = lastTouchTime {
            let timeSinceLastTouch = time.timeIntervalSince(lastTouch)
            if timeSinceLastTouch > touchTimeout {
                // New session detected
                startNewSession(at: time)
            }
        } else {
            // First touch ever
            startNewSession(at: time)
        }
        
        // Update session state
        if !wasInSession {
            isInTouchSession = true
            if sessionStartTime == nil {
                sessionStartTime = time
            }
        }
    }
    
    private func handleNoTouch(at time: Date) {
        // Keep the session active for a short grace period
        // Only end session if we've been without touch for the full timeout
        guard let lastTouch = lastTouchTime else { return }
        
        let timeSinceLastTouch = time.timeIntervalSince(lastTouch)
        if timeSinceLastTouch > touchTimeout && isInTouchSession {
            endCurrentSession()
        }
    }
    
    private func startNewSession(at time: Date) {
        print("AutoTareManager: New touch session detected")
        
        endCurrentSession()
        
        sessionStartTime = time
        isInTouchSession = true
        hasAutoTaredThisSession = false
        
        // Perform auto-tare if enabled and we haven't already tared this session
        if isEnabled && !hasAutoTaredThisSession {
            performAutoTare()
        }
    }
    
    private func endCurrentSession() {
        if isInTouchSession {
            let duration = sessionStartTime.map { Date().timeIntervalSince($0) } ?? 0
            print("AutoTareManager: Touch session ended (duration: \(String(format: "%.1f", duration))s)")
        }
        
        isInTouchSession = false
        sessionStartTime = nil
        hasAutoTaredThisSession = false
    }
    
    private func performAutoTare() {
        guard !hasAutoTaredThisSession else { return }
        
        print("AutoTareManager: Performing auto-tare")
        hasAutoTaredThisSession = true
        
        // Small delay to ensure the touch is stable
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.tareCallback?()
        }
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        isEnabled = userDefaults.object(forKey: autoTareEnabledKey) as? Bool ?? true
        touchTimeout = userDefaults.object(forKey: touchTimeoutKey) as? TimeInterval ?? 5.0
        touchTimeout = max(1.0, min(touchTimeout, 30.0)) // Ensure valid range
    }
    
    private func saveSettings() {
        userDefaults.set(isEnabled, forKey: autoTareEnabledKey)
        userDefaults.set(touchTimeout, forKey: touchTimeoutKey)
    }
    
    // MARK: - Configuration Helpers
    
    func getStatusDescription() -> String {
        let enabledStatus = isEnabled ? "Enabled" : "Disabled"
        let sessionInfo = getCurrentSessionInfo()
        
        if sessionInfo.isActive, let duration = sessionInfo.duration {
            return "Auto-Tare: \(enabledStatus) • Active session (\(String(format: "%.1f", duration))s)"
        } else {
            return "Auto-Tare: \(enabledStatus) • Timeout: \(String(format: "%.1f", touchTimeout))s"
        }
    }
    
    func getDetailedStatus() -> String {
        let sessionInfo = getCurrentSessionInfo()
        
        return """
        Auto-Tare Status:
        • Enabled: \(isEnabled ? "Yes" : "No")
        • Touch Timeout: \(String(format: "%.1f", touchTimeout))s
        • Current Session: \(sessionInfo.isActive ? "Active" : "Inactive")
        • Session Duration: \(sessionInfo.duration.map { String(format: "%.1f", $0) + "s" } ?? "N/A")
        • Auto-Tared This Session: \(hasAutoTaredThisSession ? "Yes" : "No")
        """
    }
}

// MARK: - Configuration Options

extension AutoTareManager {
    enum TouchSensitivity: Double, CaseIterable {
        case low = 0.1
        case normal = 0.05
        case high = 0.02
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .normal: return "Normal"
            case .high: return "High"
            }
        }
        
        var description: String {
            switch self {
            case .low: return "Requires more pressure to trigger"
            case .normal: return "Balanced sensitivity"
            case .high: return "Triggers with light touch"
            }
        }
    }
    
    enum TimeoutPreset: TimeInterval, CaseIterable {
        case quick = 2.0
        case normal = 5.0
        case relaxed = 10.0
        case extended = 20.0
        
        var displayName: String {
            switch self {
            case .quick: return "Quick (2s)"
            case .normal: return "Normal (5s)"
            case .relaxed: return "Relaxed (10s)"
            case .extended: return "Extended (20s)"
            }
        }
        
        var description: String {
            switch self {
            case .quick: return "New session after 2 seconds"
            case .normal: return "New session after 5 seconds"
            case .relaxed: return "New session after 10 seconds"
            case .extended: return "New session after 20 seconds"
            }
        }
    }
    
    func setSensitivity(_ sensitivity: TouchSensitivity) {
        minimumPressureThreshold = sensitivity.rawValue
        print("AutoTareManager: Sensitivity set to \(sensitivity.displayName)")
    }
    
    func setTimeoutPreset(_ preset: TimeoutPreset) {
        setTouchTimeout(preset.rawValue)
    }
    
    func getCurrentSensitivity() -> TouchSensitivity {
        for sensitivity in TouchSensitivity.allCases {
            if abs(minimumPressureThreshold - sensitivity.rawValue) < 0.001 {
                return sensitivity
            }
        }
        return .normal
    }
    
    func getCurrentTimeoutPreset() -> TimeoutPreset? {
        for preset in TimeoutPreset.allCases {
            if abs(touchTimeout - preset.rawValue) < 0.1 {
                return preset
            }
        }
        return nil
    }
}

#else
// Stub implementation for non-macOS platforms
import Foundation

class AutoTareManager {
    private var isEnabled: Bool = true
    private var touchTimeout: TimeInterval = 5.0
    
    init() {
        print("AutoTareManager: Stub implementation for non-macOS")
    }
    
    func setEnabled(_ enabled: Bool) { isEnabled = enabled }
    func isAutoTareEnabled() -> Bool { return isEnabled }
    func setTouchTimeout(_ timeout: TimeInterval) { touchTimeout = timeout }
    func getTouchTimeout() -> TimeInterval { return touchTimeout }
    func setTareCallback(_ callback: @escaping () -> Void) {}
    func processWeightReading(_ weight: Double) {}
    func forceNewSession() {}
    func getCurrentSessionInfo() -> (isActive: Bool, duration: TimeInterval?) { return (false, nil) }
    func getStatusDescription() -> String { return "Auto-Tare: Stub" }
    func getDetailedStatus() -> String { return "Auto-Tare stub implementation" }
    
    enum TouchSensitivity: Double, CaseIterable {
        case low = 0.1, normal = 0.05, high = 0.02
        var displayName: String { return rawValue.description }
        var description: String { return displayName }
    }
    
    enum TimeoutPreset: TimeInterval, CaseIterable {
        case quick = 2.0, normal = 5.0, relaxed = 10.0, extended = 20.0
        var displayName: String { return rawValue.description }
        var description: String { return displayName }
    }
    
    func setSensitivity(_ sensitivity: TouchSensitivity) {}
    func setTimeoutPreset(_ preset: TimeoutPreset) {}
    func getCurrentSensitivity() -> TouchSensitivity { return .normal }
    func getCurrentTimeoutPreset() -> TimeoutPreset? { return .normal }
}

#endif