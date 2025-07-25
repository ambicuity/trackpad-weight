/**
 * ComparisonManager - Item Comparison Mode Feature
 * 
 * Implements Feature 2: Item Comparison Mode
 * - Allow users to tare/reset weight and compare subsequent items
 * - Useful for portioning or batching similar items (e.g., herbs, coffee beans)
 * - Track multiple items with individual tare points and comparisons
 */

#if canImport(Cocoa)
import Foundation
import Cocoa

struct WeightComparison: Codable {
    let id: UUID
    let name: String
    let referenceWeight: Double
    let currentWeight: Double
    let difference: Double
    let timestamp: Date
    let tarePoint: Double
    
    init(name: String, referenceWeight: Double, currentWeight: Double, tarePoint: Double = 0.0) {
        self.id = UUID()
        self.name = name
        self.referenceWeight = referenceWeight
        self.currentWeight = currentWeight
        self.difference = currentWeight - referenceWeight
        self.timestamp = Date()
        self.tarePoint = tarePoint
    }
    
    var percentDifference: Double {
        guard referenceWeight > 0 else { return 0 }
        return (difference / referenceWeight) * 100
    }
    
    var isWithinTolerance: Bool {
        return abs(percentDifference) <= 5.0 // 5% tolerance by default
    }
}

class ComparisonManager {
    private var isComparisonMode: Bool = false
    private var currentTarePoint: Double = 0.0
    private var referenceItems: [String: Double] = [:]
    private var comparisonHistory: [WeightComparison] = []
    private var currentItemName: String = ""
    private var tolerancePercentage: Double = 5.0
    
    // Settings
    private let userDefaults = UserDefaults.standard
    private let comparisonModeKey = "comparison_mode_enabled"
    private let toleranceKey = "comparison_tolerance"
    private let referenceItemsKey = "reference_items"
    
    // Callbacks
    private var comparisonCallback: ((WeightComparison?) -> Void)?
    private var statusCallback: ((String) -> Void)?
    
    init() {
        loadSettings()
    }
    
    // MARK: - Public Interface
    
    func setComparisonMode(_ enabled: Bool) {
        isComparisonMode = enabled
        if !enabled {
            clearCurrentComparison()
        }
        saveSettings()
        updateStatus()
        print("ComparisonManager: Comparison mode \(enabled ? "enabled" : "disabled")")
    }
    
    func isInComparisonMode() -> Bool {
        return isComparisonMode
    }
    
    func setTolerance(_ percentage: Double) {
        tolerancePercentage = max(0.1, min(percentage, 50.0)) // Clamp between 0.1% and 50%
        saveSettings()
        print("ComparisonManager: Tolerance set to \(tolerancePercentage)%")
    }
    
    func getTolerance() -> Double {
        return tolerancePercentage
    }
    
    func setComparisonCallback(_ callback: @escaping (WeightComparison?) -> Void) {
        comparisonCallback = callback
    }
    
    func setStatusCallback(_ callback: @escaping (String) -> Void) {
        statusCallback = callback
    }
    
    func tareForComparison(name: String = "Item") {
        currentTarePoint = 0.0 // Will be set when weight is next processed
        currentItemName = name.isEmpty ? "Item \(referenceItems.count + 1)" : name
        clearCurrentComparison()
        updateStatus()
        print("ComparisonManager: Tared for comparison of '\(currentItemName)'")
    }
    
    func setReferenceWeight(name: String, weight: Double) {
        guard weight > 0 else { return }
        
        referenceItems[name] = weight
        saveSettings()
        updateStatus()
        print("ComparisonManager: Set reference weight for '\(name)': \(weight)g")
    }
    
    func removeReferenceItem(name: String) {
        referenceItems.removeValue(forKey: name)
        saveSettings()
        updateStatus()
        print("ComparisonManager: Removed reference item '\(name)'")
    }
    
    func getReferenceItems() -> [String: Double] {
        return referenceItems
    }
    
    func processWeight(_ weight: Double) {
        guard isComparisonMode else { return }
        
        // Set tare point if this is the first reading after tare
        if currentTarePoint == 0.0 && weight > 0.1 {
            currentTarePoint = weight
            updateStatus()
            return
        }
        
        let adjustedWeight = max(0, weight - currentTarePoint)
        
        // Find the best matching reference item
        if let comparison = findBestComparison(for: adjustedWeight) {
            comparisonCallback?(comparison)
            
            // Add to history if it's a significant change
            if comparisonHistory.isEmpty || 
               abs(comparisonHistory.last?.currentWeight ?? 0 - adjustedWeight) > 0.5 {
                comparisonHistory.append(comparison)
                
                // Limit history size
                if comparisonHistory.count > 100 {
                    comparisonHistory.removeFirst(50)
                }
            }
        } else {
            comparisonCallback?(nil)
        }
        
        updateStatus()
    }
    
    func getCurrentComparison(for weight: Double) -> WeightComparison? {
        guard isComparisonMode else { return nil }
        let adjustedWeight = max(0, weight - currentTarePoint)
        return findBestComparison(for: adjustedWeight)
    }
    
    func getComparisonHistory() -> [WeightComparison] {
        return comparisonHistory
    }
    
    func clearHistory() {
        comparisonHistory.removeAll()
        print("ComparisonManager: Cleared comparison history")
    }
    
    func clearCurrentComparison() {
        currentTarePoint = 0.0
        currentItemName = ""
        comparisonCallback?(nil)
    }
    
    // MARK: - Quick Actions
    
    func quickTareAndReference(name: String, weight: Double) {
        tareForComparison(name: name)
        setReferenceWeight(name: name, weight: weight)
    }
    
    func duplicateLastReference() {
        guard let lastComparison = comparisonHistory.last else { return }
        let name = "Copy of \(lastComparison.name)"
        setReferenceWeight(name: name, weight: lastComparison.currentWeight)
    }
    
    // MARK: - Status and Information
    
    func getStatusDescription() -> String {
        if !isComparisonMode {
            return "Comparison Mode: Disabled"
        }
        
        if currentTarePoint == 0.0 {
            return "Comparison Mode: Ready to tare"
        }
        
        let itemName = currentItemName.isEmpty ? "Current item" : currentItemName
        return "Comparing: \(itemName) (±\(String(format: "%.1f", tolerancePercentage))%)"
    }
    
    func getDetailedStatus() -> String {
        let referenceCount = referenceItems.count
        let historyCount = comparisonHistory.count
        
        return """
        Comparison Mode Status:
        • Mode: \(isComparisonMode ? "Active" : "Inactive")
        • Tolerance: ±\(String(format: "%.1f", tolerancePercentage))%
        • Reference Items: \(referenceCount)
        • Comparison History: \(historyCount) entries
        • Current Tare: \(currentTarePoint > 0 ? String(format: "%.1fg", currentTarePoint) : "Not set")
        • Current Item: \(currentItemName.isEmpty ? "None" : currentItemName)
        """
    }
    
    func getComparisonSummary() -> String {
        let recent = Array(comparisonHistory.suffix(5))
        guard !recent.isEmpty else { return "No recent comparisons" }
        
        var summary = "Recent Comparisons:\n"
        for comparison in recent.reversed() {
            let status = comparison.isWithinTolerance ? "✓" : "!"
            let diff = comparison.difference >= 0 ? "+\(String(format: "%.1f", comparison.difference))" : String(format: "%.1f", comparison.difference)
            summary += "• \(comparison.name): \(diff)g (\(String(format: "%.1f", comparison.percentDifference))%) \(status)\n"
        }
        
        return summary
    }
    
    // MARK: - Private Methods
    
    private func findBestComparison(for weight: Double) -> WeightComparison? {
        guard !referenceItems.isEmpty else { return nil }
        
        var bestMatch: (name: String, weight: Double, difference: Double)?
        var smallestDifference: Double = Double.infinity
        
        for (name, referenceWeight) in referenceItems {
            let difference = abs(weight - referenceWeight)
            let percentDifference = referenceWeight > 0 ? (difference / referenceWeight) * 100 : Double.infinity
            
            if percentDifference <= tolerancePercentage && difference < smallestDifference {
                smallestDifference = difference
                bestMatch = (name, referenceWeight, weight - referenceWeight)
            }
        }
        
        if let match = bestMatch {
            return WeightComparison(
                name: match.name,
                referenceWeight: match.weight,
                currentWeight: weight,
                tarePoint: currentTarePoint
            )
        }
        
        // If no match within tolerance, return closest match
        let closest = referenceItems.min { abs(weight - $0.value) < abs(weight - $1.value) }
        if let (name, referenceWeight) = closest {
            return WeightComparison(
                name: name,
                referenceWeight: referenceWeight,
                currentWeight: weight,
                tarePoint: currentTarePoint
            )
        }
        
        return nil
    }
    
    private func updateStatus() {
        statusCallback?(getStatusDescription())
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        isComparisonMode = userDefaults.bool(forKey: comparisonModeKey)
        tolerancePercentage = userDefaults.object(forKey: toleranceKey) as? Double ?? 5.0
        tolerancePercentage = max(0.1, min(tolerancePercentage, 50.0))
        
        if let data = userDefaults.data(forKey: referenceItemsKey),
           let items = try? JSONDecoder().decode([String: Double].self, from: data) {
            referenceItems = items
        }
    }
    
    private func saveSettings() {
        userDefaults.set(isComparisonMode, forKey: comparisonModeKey)
        userDefaults.set(tolerancePercentage, forKey: toleranceKey)
        
        if let data = try? JSONEncoder().encode(referenceItems) {
            userDefaults.set(data, forKey: referenceItemsKey)
        }
    }
}

// MARK: - Preset Configurations

extension ComparisonManager {
    enum TolerancePreset: Double, CaseIterable {
        case precise = 1.0
        case normal = 5.0
        case relaxed = 10.0
        case loose = 20.0
        
        var displayName: String {
            switch self {
            case .precise: return "Precise (±1%)"
            case .normal: return "Normal (±5%)"
            case .relaxed: return "Relaxed (±10%)"
            case .loose: return "Loose (±20%)"
            }
        }
    }
    
    func setTolerancePreset(_ preset: TolerancePreset) {
        setTolerance(preset.rawValue)
    }
    
    func getCurrentTolerancePreset() -> TolerancePreset? {
        for preset in TolerancePreset.allCases {
            if abs(tolerancePercentage - preset.rawValue) < 0.1 {
                return preset
            }
        }
        return nil
    }
}

// MARK: - Export Functionality

extension ComparisonManager {
    func exportComparisonsToCSV() -> URL? {
        guard !comparisonHistory.isEmpty else { return nil }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logsDirectory = documentsPath.appendingPathComponent("TrackpadWeight/Logs")
        
        do {
            try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ComparisonManager: Failed to create directory: \(error)")
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "comparison_history_\(timestamp).csv"
        let fileURL = logsDirectory.appendingPathComponent(filename)
        
        var csvContent = "Timestamp,Item Name,Reference Weight (g),Current Weight (g),Difference (g),Percent Difference (%),Within Tolerance,Tare Point (g)\n"
        
        for comparison in comparisonHistory {
            let timestampStr = ISO8601DateFormatter().string(from: comparison.timestamp)
            let withinTolerance = comparison.isWithinTolerance ? "Yes" : "No"
            csvContent += "\(timestampStr),\(comparison.name),\(comparison.referenceWeight),\(comparison.currentWeight),\(comparison.difference),\(String(format: "%.2f", comparison.percentDifference)),\(withinTolerance),\(comparison.tarePoint)\n"
        }
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("ComparisonManager: Exported \(comparisonHistory.count) comparisons to \(fileURL.path)")
            return fileURL
        } catch {
            print("ComparisonManager: Failed to export CSV: \(error)")
            return nil
        }
    }
}

#else
// Stub implementation for non-macOS platforms
import Foundation

struct WeightComparison: Codable {
    let id: UUID = UUID()
    let name: String = ""
    let referenceWeight: Double = 0
    let currentWeight: Double = 0
    let difference: Double = 0
    let timestamp: Date = Date()
    let tarePoint: Double = 0
    var percentDifference: Double { return 0 }
    var isWithinTolerance: Bool { return true }
}

class ComparisonManager {
    private var isComparisonMode: Bool = false
    private var tolerancePercentage: Double = 5.0
    
    init() {
        print("ComparisonManager: Stub implementation for non-macOS")
    }
    
    func setComparisonMode(_ enabled: Bool) { isComparisonMode = enabled }
    func isInComparisonMode() -> Bool { return isComparisonMode }
    func setTolerance(_ percentage: Double) { tolerancePercentage = percentage }
    func getTolerance() -> Double { return tolerancePercentage }
    func setComparisonCallback(_ callback: @escaping (WeightComparison?) -> Void) {}
    func setStatusCallback(_ callback: @escaping (String) -> Void) {}
    func tareForComparison(name: String = "Item") {}
    func setReferenceWeight(name: String, weight: Double) {}
    func removeReferenceItem(name: String) {}
    func getReferenceItems() -> [String: Double] { return [:] }
    func processWeight(_ weight: Double) {}
    func getCurrentComparison(for weight: Double) -> WeightComparison? { return nil }
    func getComparisonHistory() -> [WeightComparison] { return [] }
    func clearHistory() {}
    func clearCurrentComparison() {}
    func getStatusDescription() -> String { return "Comparison Mode: Stub" }
    func getDetailedStatus() -> String { return "Comparison stub implementation" }
    func getComparisonSummary() -> String { return "No comparisons (stub)" }
    func exportComparisonsToCSV() -> URL? { return nil }
    
    enum TolerancePreset: Double, CaseIterable {
        case precise = 1.0, normal = 5.0, relaxed = 10.0, loose = 20.0
        var displayName: String { return rawValue.description }
    }
    
    func setTolerancePreset(_ preset: TolerancePreset) {}
    func getCurrentTolerancePreset() -> TolerancePreset? { return .normal }
}

#endif