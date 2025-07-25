/**
 * WeightLogger - Historical Weight Logging & Data Management
 * 
 * Implements Feature 1: Historical Weight Logging & Graphs
 * - Automatically logs weight readings over time
 * - Provides data export capabilities (CSV/JSON)
 * - Manages weight history with timestamps
 */

#if canImport(Cocoa)
import Foundation
import Cocoa

struct WeightReading: Codable {
    let timestamp: Date
    let weight: Double
    let sessionId: UUID
    let calibrationOffset: Double?
    
    init(weight: Double, sessionId: UUID = UUID(), calibrationOffset: Double? = nil) {
        self.timestamp = Date()
        self.weight = weight
        self.sessionId = sessionId
        self.calibrationOffset = calibrationOffset
    }
}

struct WeightSession: Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let readings: [WeightReading]
    let averageWeight: Double
    let maxWeight: Double
    let minWeight: Double
    
    init(readings: [WeightReading]) {
        self.id = readings.first?.sessionId ?? UUID()
        self.startTime = readings.first?.timestamp ?? Date()
        self.endTime = readings.last?.timestamp
        self.readings = readings
        
        let weights = readings.map { $0.weight }
        self.averageWeight = weights.isEmpty ? 0.0 : weights.reduce(0, +) / Double(weights.count)
        self.maxWeight = weights.max() ?? 0.0
        self.minWeight = weights.min() ?? 0.0
    }
}

class WeightLogger {
    private var currentSession: UUID = UUID()
    private var readings: [WeightReading] = []
    private let maxReadings: Int
    private let minWeightThreshold: Double
    private let sessionTimeout: TimeInterval
    private var lastReadingTime: Date?
    private var isLoggingEnabled: Bool = true
    
    // Configuration
    private let logDirectory: URL
    private let autoSaveInterval: TimeInterval = 60.0 // Auto-save every minute
    private var autoSaveTimer: Timer?
    
    // Statistics
    private(set) var totalSessions: Int = 0
    private(set) var totalReadings: Int = 0
    
    init(maxReadings: Int = 10000, 
         minWeightThreshold: Double = 0.1,
         sessionTimeout: TimeInterval = 30.0) {
        self.maxReadings = maxReadings
        self.minWeightThreshold = minWeightThreshold
        self.sessionTimeout = sessionTimeout
        
        // Create logs directory in user's Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                    in: .userDomainMask).first!
        self.logDirectory = documentsPath.appendingPathComponent("TrackpadWeight/Logs")
        
        setupLogDirectory()
        startAutoSave()
        loadExistingData()
    }
    
    deinit {
        stopAutoSave()
        saveToFile()
    }
    
    // MARK: - Public Interface
    
    func logWeight(_ weight: Double, calibrationOffset: Double? = nil) {
        guard isLoggingEnabled else { return }
        
        let now = Date()
        
        // Check if we need to start a new session
        if shouldStartNewSession(at: now, weight: weight) {
            finalizeCurrentSession()
            currentSession = UUID()
        }
        
        // Only log significant weight changes or if weight is above threshold
        if weight >= minWeightThreshold || shouldLogZeroWeight(weight) {
            let reading = WeightReading(weight: weight, 
                                      sessionId: currentSession,
                                      calibrationOffset: calibrationOffset)
            readings.append(reading)
            totalReadings += 1
            
            // Maintain maximum readings limit
            if readings.count > maxReadings {
                let excess = readings.count - maxReadings
                readings.removeFirst(excess)
            }
        }
        
        lastReadingTime = now
    }
    
    func startNewSession() {
        finalizeCurrentSession()
        currentSession = UUID()
        print("WeightLogger: Started new session \(currentSession)")
    }
    
    func getRecentReadings(count: Int = 100) -> [WeightReading] {
        return Array(readings.suffix(count))
    }
    
    func getCurrentSessionReadings() -> [WeightReading] {
        return readings.filter { $0.sessionId == currentSession }
    }
    
    func getAllSessions() -> [WeightSession] {
        let groupedReadings = Dictionary(grouping: readings) { $0.sessionId }
        return groupedReadings.values.map { WeightSession(readings: Array($0)) }
            .sorted { $0.startTime > $1.startTime }
    }
    
    func getSessionStatistics() -> (total: Int, averageReadings: Double, averageDuration: TimeInterval) {
        let sessions = getAllSessions()
        let totalSessions = sessions.count
        let averageReadings = sessions.isEmpty ? 0.0 : Double(sessions.map { $0.readings.count }.reduce(0, +)) / Double(totalSessions)
        
        let durations = sessions.compactMap { session -> TimeInterval? in
            guard let endTime = session.endTime else { return nil }
            return endTime.timeIntervalSince(session.startTime)
        }
        let averageDuration = durations.isEmpty ? 0.0 : durations.reduce(0, +) / Double(durations.count)
        
        return (totalSessions, averageReadings, averageDuration)
    }
    
    // MARK: - Export Functions
    
    func exportToCSV() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "trackpad_weight_log_\(timestamp).csv"
        let fileURL = logDirectory.appendingPathComponent(filename)
        
        var csvContent = "Timestamp,Weight (g),Session ID,Calibration Offset\n"
        
        for reading in readings {
            let timestampStr = ISO8601DateFormatter().string(from: reading.timestamp)
            let calibrationStr = reading.calibrationOffset.map { String($0) } ?? ""
            csvContent += "\(timestampStr),\(reading.weight),\(reading.sessionId),\(calibrationStr)\n"
        }
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("WeightLogger: Exported \(readings.count) readings to \(fileURL.path)")
            return fileURL
        } catch {
            print("WeightLogger: Failed to export CSV: \(error)")
            return nil
        }
    }
    
    func exportToJSON() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "trackpad_weight_log_\(timestamp).json"
        let fileURL = logDirectory.appendingPathComponent(filename)
        
        let exportData = [
            "exported_at": ISO8601DateFormatter().string(from: Date()),
            "total_readings": readings.count,
            "total_sessions": getAllSessions().count,
            "readings": readings
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            print("WeightLogger: Exported \(readings.count) readings to \(fileURL.path)")
            return fileURL
        } catch {
            print("WeightLogger: Failed to export JSON: \(error)")
            return nil
        }
    }
    
    func exportSessionsToJSON() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "trackpad_weight_sessions_\(timestamp).json"
        let fileURL = logDirectory.appendingPathComponent(filename)
        
        let sessions = getAllSessions()
        let statistics = getSessionStatistics()
        
        let exportData = [
            "exported_at": ISO8601DateFormatter().string(from: Date()),
            "statistics": [
                "total_sessions": statistics.total,
                "average_readings_per_session": statistics.averageReadings,
                "average_session_duration_seconds": statistics.averageDuration
            ],
            "sessions": sessions
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            print("WeightLogger: Exported \(sessions.count) sessions to \(fileURL.path)")
            return fileURL
        } catch {
            print("WeightLogger: Failed to export sessions JSON: \(error)")
            return nil
        }
    }
    
    // MARK: - Configuration
    
    func setLoggingEnabled(_ enabled: Bool) {
        isLoggingEnabled = enabled
        print("WeightLogger: Logging \(enabled ? "enabled" : "disabled")")
    }
    
    func isLogging() -> Bool {
        return isLoggingEnabled
    }
    
    func clearAllData() {
        readings.removeAll()
        currentSession = UUID()
        totalSessions = 0
        totalReadings = 0
        
        // Clear saved files
        clearLogDirectory()
        print("WeightLogger: Cleared all data")
    }
    
    func getLogDirectory() -> URL {
        return logDirectory
    }
    
    // MARK: - Private Methods
    
    private func shouldStartNewSession(at date: Date, weight: Double) -> Bool {
        guard let lastTime = lastReadingTime else { return false }
        
        // Start new session if:
        // 1. Timeout has passed since last reading
        // 2. Weight goes from zero to significant value (new object placed)
        let timeSinceLastReading = date.timeIntervalSince(lastTime)
        let isTimeout = timeSinceLastReading > sessionTimeout
        
        let lastSignificantWeight = readings.last?.weight ?? 0.0
        let isNewWeightEvent = lastSignificantWeight < minWeightThreshold && weight >= minWeightThreshold
        
        return isTimeout || isNewWeightEvent
    }
    
    private func shouldLogZeroWeight(_ weight: Double) -> Bool {
        // Log zero weights only if the previous reading was significant
        // This helps capture when items are removed
        guard let lastReading = readings.last else { return true }
        return lastReading.weight >= minWeightThreshold && weight < minWeightThreshold
    }
    
    private func finalizeCurrentSession() {
        let currentSessionReadings = getCurrentSessionReadings()
        if !currentSessionReadings.isEmpty {
            totalSessions += 1
            print("WeightLogger: Finalized session \(currentSession) with \(currentSessionReadings.count) readings")
        }
    }
    
    private func setupLogDirectory() {
        do {
            try FileManager.default.createDirectory(at: logDirectory, 
                                                  withIntermediateDirectories: true, 
                                                  attributes: nil)
        } catch {
            print("WeightLogger: Failed to create log directory: \(error)")
        }
    }
    
    private func clearLogDirectory() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: logDirectory, 
                                                                   includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("WeightLogger: Failed to clear log directory: \(error)")
        }
    }
    
    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { _ in
            self.saveToFile()
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func saveToFile() {
        let filename = "current_session.json"
        let fileURL = logDirectory.appendingPathComponent(filename)
        
        let saveData = [
            "currentSession": currentSession.uuidString,
            "lastReadingTime": lastReadingTime?.timeIntervalSince1970 ?? 0,
            "totalSessions": totalSessions,
            "totalReadings": totalReadings,
            "readings": readings
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: saveData, options: [])
            try jsonData.write(to: fileURL)
        } catch {
            print("WeightLogger: Failed to auto-save: \(error)")
        }
    }
    
    private func loadExistingData() {
        let filename = "current_session.json"
        let fileURL = logDirectory.appendingPathComponent(filename)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let sessionString = json?["currentSession"] as? String,
               let sessionUUID = UUID(uuidString: sessionString) {
                currentSession = sessionUUID
            }
            
            if let timestamp = json?["lastReadingTime"] as? TimeInterval, timestamp > 0 {
                lastReadingTime = Date(timeIntervalSince1970: timestamp)
            }
            
            if let total = json?["totalSessions"] as? Int {
                totalSessions = total
            }
            
            if let total = json?["totalReadings"] as? Int {
                totalReadings = total
            }
            
            if let readingsData = json?["readings"] as? [[String: Any]] {
                readings = readingsData.compactMap { dict in
                    guard let timestamp = dict["timestamp"] as? String,
                          let weight = dict["weight"] as? Double,
                          let sessionIdString = dict["sessionId"] as? String,
                          let sessionId = UUID(uuidString: sessionIdString),
                          let date = ISO8601DateFormatter().date(from: timestamp) else {
                        return nil
                    }
                    
                    let calibrationOffset = dict["calibrationOffset"] as? Double
                    
                    return WeightReading(weight: weight, sessionId: sessionId, calibrationOffset: calibrationOffset)
                }
            }
            
            print("WeightLogger: Loaded \(readings.count) existing readings")
        } catch {
            print("WeightLogger: Failed to load existing data: \(error)")
        }
    }
}

// MARK: - Statistics and Visualization Helpers

extension WeightLogger {
    func getWeightTrendData(timeRange: TimeInterval = 3600) -> [(Date, Double)] {
        let cutoffTime = Date().addingTimeInterval(-timeRange)
        return readings
            .filter { $0.timestamp >= cutoffTime }
            .map { ($0.timestamp, $0.weight) }
    }
    
    func getSessionSummary() -> String {
        let statistics = getSessionStatistics()
        let currentReadings = getCurrentSessionReadings()
        
        return """
        Weight Logging Summary:
        • Total Sessions: \(statistics.total)
        • Total Readings: \(totalReadings)
        • Current Session: \(currentReadings.count) readings
        • Average Readings/Session: \(String(format: "%.1f", statistics.averageReadings))
        • Average Session Duration: \(String(format: "%.1f", statistics.averageDuration))s
        """
    }
}

#else
// Stub implementation for non-macOS platforms
import Foundation

struct WeightReading: Codable {
    let timestamp: Date
    let weight: Double
    let sessionId: UUID
    let calibrationOffset: Double?
    
    init(weight: Double, sessionId: UUID = UUID(), calibrationOffset: Double? = nil) {
        self.timestamp = Date()
        self.weight = weight
        self.sessionId = sessionId
        self.calibrationOffset = calibrationOffset
    }
}

struct WeightSession: Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let readings: [WeightReading]
    let averageWeight: Double
    let maxWeight: Double
    let minWeight: Double
    
    init(readings: [WeightReading]) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.readings = []
        self.averageWeight = 0.0
        self.maxWeight = 0.0
        self.minWeight = 0.0
    }
}

class WeightLogger {
    private(set) var totalSessions: Int = 0
    private(set) var totalReadings: Int = 0
    
    init(maxReadings: Int = 10000, minWeightThreshold: Double = 0.1, sessionTimeout: TimeInterval = 30.0) {
        print("WeightLogger: Stub implementation for non-macOS")
    }
    
    func logWeight(_ weight: Double, calibrationOffset: Double? = nil) {
        print("WeightLogger: Logged weight \(weight)g (stub)")
    }
    
    func startNewSession() {
        print("WeightLogger: Started new session (stub)")
    }
    
    func getRecentReadings(count: Int = 100) -> [WeightReading] { return [] }
    func getCurrentSessionReadings() -> [WeightReading] { return [] }
    func getAllSessions() -> [WeightSession] { return [] }
    func exportToCSV() -> URL? { return nil }
    func exportToJSON() -> URL? { return nil }
    func exportSessionsToJSON() -> URL? { return nil }
    func setLoggingEnabled(_ enabled: Bool) {}
    func isLogging() -> Bool { return false }
    func clearAllData() {}
    func getLogDirectory() -> URL { return URL(fileURLWithPath: "/tmp") }
    func getSessionSummary() -> String { return "Stub implementation" }
}

#endif