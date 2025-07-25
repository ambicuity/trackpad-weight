#if canImport(Cocoa)
import Cocoa
import SwiftUI

class WeightDisplayView: NSView {
    private var weightLabel: NSTextField!
    private var unitLabel: NSTextField!
    private var calibrateButton: NSButton!
    private var statusLabel: NSTextField!
    private var currentWeight: Double = 0.0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        let theme = ThemeManager.shared
        
        // Main weight display
        weightLabel = NSTextField(labelWithString: "0.0")
        weightLabel.font = theme.displayFont(size: 48)
        weightLabel.alignment = .center
        weightLabel.textColor = theme.primaryTextColor()
        
        // Unit label
        unitLabel = NSTextField(labelWithString: "grams")
        unitLabel.font = theme.titleFont(size: 16)
        unitLabel.alignment = .center
        unitLabel.textColor = theme.secondaryTextColor()
        
        // Calibrate button
        calibrateButton = NSButton(title: "Calibrate Scale", target: self, action: #selector(calibratePressed))
        calibrateButton.bezelStyle = .rounded
        calibrateButton.font = theme.primaryFont(size: 14)
        
        // Status label
        statusLabel = NSTextField(labelWithString: "Place items on trackpad to weigh")
        statusLabel.font = theme.captionFont(size: 12)
        statusLabel.alignment = .center
        statusLabel.textColor = theme.tertiaryTextColor()
        
        // Configure accessibility
        theme.configureAccessibility(for: weightLabel, label: "Current weight reading", hint: "The current weight measurement in grams")
        theme.configureAccessibility(for: unitLabel, label: "Weight unit", hint: "Weight is measured in grams")
        theme.configureAccessibility(for: calibrateButton, label: "Calibrate scale", hint: "Press to zero the scale and calibrate for accurate measurements")
        theme.configureAccessibility(for: statusLabel, label: "Status message", hint: "Instructions and current status of the scale")
        
        // Add subviews
        addSubview(weightLabel)
        addSubview(unitLabel)
        addSubview(calibrateButton)
        addSubview(statusLabel)
        
        // Disable autoresizing masks
        [weightLabel, unitLabel, calibrateButton, statusLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        setupConstraints()
        setupThemeNotifications()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Weight label - center and large
            weightLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            weightLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30),
            weightLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            weightLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            
            // Unit label - below weight
            unitLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            unitLabel.topAnchor.constraint(equalTo: weightLabel.bottomAnchor, constant: 5),
            
            // Status label - above weight
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: weightLabel.topAnchor, constant: -20),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            
            // Calibrate button - bottom center
            calibrateButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            calibrateButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30),
            calibrateButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }
    
    func updateWeight(_ weight: Double) {
        currentWeight = weight
        let theme = ThemeManager.shared
        
        // Format weight display with edge case handling
        weightLabel.stringValue = formatWeight(weight)
        
        // Update status based on weight
        if weight < 0.1 {
            statusLabel.stringValue = "Place items on trackpad to weigh"
            weightLabel.textColor = theme.tertiaryTextColor()
        } else {
            statusLabel.stringValue = "Current weight measurement"
            weightLabel.textColor = theme.primaryTextColor()
        }
        
        // Add visual feedback for weight changes
        animateWeightChange()
    }
    
    private func formatWeight(_ weight: Double) -> String {
        // Handle special values
        if weight.isNaN {
            return "---"
        }
        if weight.isInfinite {
            return weight > 0 ? "∞" : "-∞"
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
    
    private func animateWeightChange() {
        // Subtle scale animation to indicate change
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.05
        scaleAnimation.duration = 0.1
        scaleAnimation.autoreverses = true
        
        weightLabel.layer?.add(scaleAnimation, forKey: "scaleAnimation")
    }
    
    @objc private func calibratePressed() {
        // Send calibration request to parent
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.trackpadMonitor?.calibrate()
        }
        
        // Show calibration feedback
        statusLabel.stringValue = "Calibrating... Remove all weight from trackpad"
        calibrateButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.statusLabel.stringValue = "Calibration complete"
            self.calibrateButton.isEnabled = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.currentWeight < 0.1 {
                    self.statusLabel.stringValue = "Place items on trackpad to weigh"
                } else {
                    self.statusLabel.stringValue = "Current weight measurement"
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        applyCurrentTheme()
    }
    
    private func setupThemeNotifications() {
        NotificationCenter.default.addObserver(
            forName: .themeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyCurrentTheme()
        }
    }
    
    private func applyCurrentTheme() {
        let theme = ThemeManager.shared
        
        // Update background
        layer?.backgroundColor = theme.backgroundColor().cgColor
        
        // Update fonts and colors
        weightLabel.font = theme.displayFont(size: 48)
        weightLabel.textColor = currentWeight < 0.1 ? theme.tertiaryTextColor() : theme.primaryTextColor()
        
        unitLabel.font = theme.titleFont(size: 16)
        unitLabel.textColor = theme.secondaryTextColor()
        
        statusLabel.font = theme.captionFont(size: 12)
        statusLabel.textColor = theme.tertiaryTextColor()
        
        calibrateButton.font = theme.primaryFont(size: 14)
        calibrateButton.applyTheme()
        
        // Update border and corner radius for high contrast
        if theme.isHighContrast() {
            layer?.borderColor = theme.borderColor().cgColor
            layer?.borderWidth = theme.borderWidth()
            layer?.cornerRadius = theme.cornerRadius()
        } else {
            layer?.borderWidth = 0
        }
    }
}

// Alternative SwiftUI implementation for modern macOS
@available(macOS 13.0, *)
struct WeightDisplaySwiftUIView: View {
    @State private var weight: Double = 0.0
    @State private var isCalibrating: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 5) {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formattedWeight)
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(weight < 0.1 ? .secondary : .primary)
                    .scaleEffect(weight > 0.1 ? 1.0 : 0.95)
                    .animation(.easeInOut(duration: 0.2), value: weight)
                
                Text("grams")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: calibrate) {
                Text("Calibrate Scale")
                    .frame(minWidth: 120)
            }
            .disabled(isCalibrating)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var formattedWeight: String {
        // Handle special values
        if weight.isNaN {
            return "---"
        }
        if weight.isInfinite {
            return weight > 0 ? "∞" : "-∞"
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
    
    private var statusText: String {
        if isCalibrating {
            return "Calibrating... Remove all weight from trackpad"
        } else if weight < 0.1 {
            return "Place items on trackpad to weigh"
        } else {
            return "Current weight measurement"
        }
    }
    
    private func calibrate() {
        isCalibrating = true
        
        // Send calibration request
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.trackpadMonitor?.calibrate()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isCalibrating = false
        }
    }
    
    func updateWeight(_ newWeight: Double) {
        weight = newWeight
    }
}

#else
// Stub implementation for non-macOS platforms
import Foundation

class WeightDisplayView {
    private var currentWeight: Double = 0.0
    
    init() {
        print("WeightDisplayView: macOS Cocoa UI required")
    }
    
    func updateWeight(_ weight: Double) {
        currentWeight = weight
        print("Weight Display: \(formatWeight(weight))")
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if weight < 1.0 {
            return String(format: "%.2fg", weight)
        } else if weight < 10.0 {
            return String(format: "%.1fg", weight)
        } else {
            return String(format: "%.0fg", weight)
        }
    }
}
#endif