/**
 * CompactWeightWidget - Compact Weight Display Widget
 * 
 * Implements Feature 5: Compact Weight Display Widget
 * - Option to float a minimal, always-on-top weight display window
 * - Especially useful for multitasking or edge-of-screen display during other tasks
 * - Configurable size, position, and transparency
 */

#if canImport(Cocoa)
import Foundation
import Cocoa

class CompactWeightWidget: NSObject {
    private var widgetWindow: NSWindow?
    private var weightLabel: NSTextField?
    private var isVisible: Bool = false
    private var currentWeight: Double = 0.0
    
    // Configuration
    private var widgetSize: NSSize = NSSize(width: 120, height: 40)
    private var widgetOpacity: CGFloat = 0.9
    private var widgetPosition: WidgetPosition = .topRight
    private var autoHide: Bool = false
    private var hideDelay: TimeInterval = 3.0
    private var hideTimer: Timer?
    
    // Settings persistence
    private let userDefaults = UserDefaults.standard
    private let widgetVisibleKey = "compact_widget_visible"
    private let widgetPositionKey = "compact_widget_position"
    private let widgetOpacityKey = "compact_widget_opacity"
    private let widgetSizeKey = "compact_widget_size"
    private let autoHideKey = "compact_widget_auto_hide"
    
    enum WidgetPosition: String, CaseIterable {
        case topLeft = "top_left"
        case topRight = "top_right"
        case bottomLeft = "bottom_left"
        case bottomRight = "bottom_right"
        case center = "center"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .topLeft: return "Top Left"
            case .topRight: return "Top Right"
            case .bottomLeft: return "Bottom Left"
            case .bottomRight: return "Bottom Right"
            case .center: return "Center"
            case .custom: return "Custom"
            }
        }
    }
    
    enum WidgetSize: String, CaseIterable {
        case small = "small"
        case medium = "medium"
        case large = "large"
        
        var displayName: String {
            switch self {
            case .small: return "Small"
            case .medium: return "Medium"
            case .large: return "Large"
            }
        }
        
        var size: NSSize {
            switch self {
            case .small: return NSSize(width: 80, height: 30)
            case .medium: return NSSize(width: 120, height: 40)
            case .large: return NSSize(width: 160, height: 50)
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            }
        }
    }
    
    override init() {
        super.init()
        loadSettings()
        setupThemeNotifications()
    }
    
    deinit {
        hideWidget()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Interface
    
    func showWidget() {
        guard !isVisible else { return }
        
        createWidget()
        isVisible = true
        saveSettings()
        
        print("CompactWeightWidget: Widget shown")
    }
    
    func hideWidget() {
        guard isVisible else { return }
        
        hideTimer?.invalidate()
        hideTimer = nil
        
        widgetWindow?.close()
        widgetWindow = nil
        weightLabel = nil
        isVisible = false
        saveSettings()
        
        print("CompactWeightWidget: Widget hidden")
    }
    
    func toggleWidget() {
        if isVisible {
            hideWidget()
        } else {
            showWidget()
        }
    }
    
    func isWidgetVisible() -> Bool {
        return isVisible
    }
    
    func updateWeight(_ weight: Double) {
        currentWeight = weight
        updateDisplay()
        
        // Auto-hide logic
        if autoHide {
            resetHideTimer()
        }
    }
    
    // MARK: - Configuration
    
    func setPosition(_ position: WidgetPosition) {
        widgetPosition = position
        if isVisible {
            positionWidget()
        }
        saveSettings()
    }
    
    func getPosition() -> WidgetPosition {
        return widgetPosition
    }
    
    func setOpacity(_ opacity: CGFloat) {
        widgetOpacity = max(0.1, min(opacity, 1.0))
        if isVisible {
            widgetWindow?.alphaValue = widgetOpacity
        }
        saveSettings()
    }
    
    func getOpacity() -> CGFloat {
        return widgetOpacity
    }
    
    func setSize(_ size: WidgetSize) {
        widgetSize = size.size
        if isVisible {
            updateWidgetSize()
        }
        saveSettings()
    }
    
    func getCurrentSize() -> WidgetSize {
        for size in WidgetSize.allCases {
            if abs(widgetSize.width - size.size.width) < 1.0 && 
               abs(widgetSize.height - size.size.height) < 1.0 {
                return size
            }
        }
        return .medium
    }
    
    func setAutoHide(_ enabled: Bool, delay: TimeInterval = 3.0) {
        autoHide = enabled
        hideDelay = max(1.0, min(delay, 30.0))
        
        if enabled && isVisible {
            resetHideTimer()
        } else {
            hideTimer?.invalidate()
            hideTimer = nil
        }
        
        saveSettings()
    }
    
    func isAutoHideEnabled() -> Bool {
        return autoHide
    }
    
    func getAutoHideDelay() -> TimeInterval {
        return hideDelay
    }
    
    // MARK: - Status and Information
    
    func getStatusDescription() -> String {
        let status = isVisible ? "Visible" : "Hidden"
        let position = widgetPosition.displayName
        let opacity = String(format: "%.0f", widgetOpacity * 100)
        return "Compact Widget: \(status) • Position: \(position) • Opacity: \(opacity)%"
    }
    
    func getDetailedStatus() -> String {
        let currentSize = getCurrentSize()
        
        return """
        Compact Widget Status:
        • Visible: \(isVisible ? "Yes" : "No")
        • Position: \(widgetPosition.displayName)
        • Size: \(currentSize.displayName) (\(Int(widgetSize.width))×\(Int(widgetSize.height)))
        • Opacity: \(String(format: "%.0f", widgetOpacity * 100))%
        • Auto-hide: \(autoHide ? "Yes (\(String(format: "%.1f", hideDelay))s)" : "No")
        • Current Weight: \(formatWeight(currentWeight))
        """
    }
    
    // MARK: - Private Methods
    
    private func createWidget() {
        let windowRect = NSRect(origin: .zero, size: widgetSize)
        
        widgetWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = widgetWindow else { return }
        
        // Configure window properties
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.alphaValue = widgetOpacity
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Create content view
        let contentView = NSView(frame: windowRect)
        contentView.wantsLayer = true
        
        // Setup visual effects
        let blurView = NSVisualEffectView(frame: windowRect)
        blurView.material = .hudWindow
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.layer?.cornerRadius = 8
        blurView.layer?.masksToBounds = true
        
        // Create weight label
        weightLabel = NSTextField(labelWithString: formatWeight(currentWeight))
        guard let label = weightLabel else { return }
        
        let theme = ThemeManager.shared
        label.font = theme.displayFont(size: getCurrentSize().fontSize)
        label.textColor = theme.primaryTextColor()
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure accessibility
        theme.configureAccessibility(for: label, 
                                   label: "Compact weight display", 
                                   hint: "Shows current weight measurement in a floating window")
        
        // Add views
        contentView.addSubview(blurView)
        contentView.addSubview(label)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8)
        ])
        
        window.contentView = contentView
        
        // Position and show
        positionWidget()
        window.orderFrontRegardless()
        
        // Add click handler to toggle auto-hide
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(widgetClicked))
        contentView.addGestureRecognizer(clickGesture)
    }
    
    private func positionWidget() {
        guard let window = widgetWindow, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let margin: CGFloat = 20
        
        let origin: NSPoint
        
        switch widgetPosition {
        case .topLeft:
            origin = NSPoint(
                x: screenFrame.minX + margin,
                y: screenFrame.maxY - windowSize.height - margin
            )
        case .topRight:
            origin = NSPoint(
                x: screenFrame.maxX - windowSize.width - margin,
                y: screenFrame.maxY - windowSize.height - margin
            )
        case .bottomLeft:
            origin = NSPoint(
                x: screenFrame.minX + margin,
                y: screenFrame.minY + margin
            )
        case .bottomRight:
            origin = NSPoint(
                x: screenFrame.maxX - windowSize.width - margin,
                y: screenFrame.minY + margin
            )
        case .center:
            origin = NSPoint(
                x: screenFrame.midX - windowSize.width / 2,
                y: screenFrame.midY - windowSize.height / 2
            )
        case .custom:
            // Keep current position if custom
            return
        }
        
        window.setFrameOrigin(origin)
    }
    
    private func updateWidgetSize() {
        guard let window = widgetWindow, let label = weightLabel else { return }
        
        // Resize window
        var frame = window.frame
        frame.size = widgetSize
        window.setFrame(frame, display: true, animate: true)
        
        // Update content view
        window.contentView?.frame = NSRect(origin: .zero, size: widgetSize)
        
        // Update blur view
        if let blurView = window.contentView?.subviews.first(where: { $0 is NSVisualEffectView }) {
            blurView.frame = NSRect(origin: .zero, size: widgetSize)
        }
        
        // Update font size
        label.font = ThemeManager.shared.displayFont(size: getCurrentSize().fontSize)
        
        // Reposition if needed
        positionWidget()
    }
    
    private func updateDisplay() {
        guard let label = weightLabel else { return }
        
        DispatchQueue.main.async {
            label.stringValue = self.formatWeight(self.currentWeight)
            
            // Update color based on weight
            let theme = ThemeManager.shared
            if self.currentWeight < 0.1 {
                label.textColor = theme.tertiaryTextColor()
            } else {
                label.textColor = theme.primaryTextColor()
            }
            
            // Animate on weight change
            self.animateWeightChange()
        }
    }
    
    private func animateWeightChange() {
        guard let window = widgetWindow else { return }
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.1
        scaleAnimation.duration = 0.15
        scaleAnimation.autoreverses = true
        
        window.contentView?.layer?.add(scaleAnimation, forKey: "scaleAnimation")
    }
    
    private func resetHideTimer() {
        hideTimer?.invalidate()
        
        if currentWeight > 0.1 { // Only hide if there's no weight
            hideTimer = Timer.scheduledTimer(withTimeInterval: hideDelay, repeats: false) { [weak self] _ in
                if self?.currentWeight ?? 0 < 0.1 {
                    self?.hideWidget()
                }
            }
        }
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if weight.isNaN { return "---" }
        if weight.isInfinite { return weight > 0 ? "∞" : "-∞" }
        
        let absWeight = abs(weight)
        let sign = weight < 0 ? "-" : ""
        
        if absWeight < 1.0 {
            return String(format: "%@%.1fg", sign, absWeight)
        } else if absWeight < 100.0 {
            return String(format: "%@%.0fg", sign, absWeight)
        } else {
            return String(format: "%@%.0f", sign, absWeight)
        }
    }
    
    @objc private func widgetClicked() {
        // Toggle auto-hide on click
        setAutoHide(!autoHide)
        print("CompactWeightWidget: Auto-hide \(autoHide ? "enabled" : "disabled")")
    }
    
    private func setupThemeNotifications() {
        NotificationCenter.default.addObserver(
            forName: .themeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTheme()
        }
    }
    
    private func updateTheme() {
        guard let label = weightLabel else { return }
        
        let theme = ThemeManager.shared
        label.font = theme.displayFont(size: getCurrentSize().fontSize)
        label.textColor = currentWeight < 0.1 ? theme.tertiaryTextColor() : theme.primaryTextColor()
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        isVisible = userDefaults.bool(forKey: widgetVisibleKey)
        
        if let positionString = userDefaults.string(forKey: widgetPositionKey),
           let position = WidgetPosition(rawValue: positionString) {
            widgetPosition = position
        }
        
        widgetOpacity = userDefaults.object(forKey: widgetOpacityKey) as? CGFloat ?? 0.9
        widgetOpacity = max(0.1, min(widgetOpacity, 1.0))
        
        if let sizeData = userDefaults.data(forKey: widgetSizeKey),
           let size = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: sizeData) {
            widgetSize = size.sizeValue
        }
        
        autoHide = userDefaults.bool(forKey: autoHideKey)
    }
    
    private func saveSettings() {
        userDefaults.set(isVisible, forKey: widgetVisibleKey)
        userDefaults.set(widgetPosition.rawValue, forKey: widgetPositionKey)
        userDefaults.set(widgetOpacity, forKey: widgetOpacityKey)
        userDefaults.set(autoHide, forKey: autoHideKey)
        
        if let sizeData = try? NSKeyedArchiver.archivedData(withRootObject: NSValue(size: widgetSize), requiringSecureCoding: false) {
            userDefaults.set(sizeData, forKey: widgetSizeKey)
        }
    }
}

#else
// Stub implementation for non-macOS platforms
import Foundation

class CompactWeightWidget {
    private var isVisible: Bool = false
    private var currentWeight: Double = 0.0
    
    enum WidgetPosition: String, CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight, center, custom
        var displayName: String { return rawValue }
    }
    
    enum WidgetSize: String, CaseIterable {
        case small, medium, large
        var displayName: String { return rawValue }
    }
    
    init() {
        print("CompactWeightWidget: Stub implementation for non-macOS")
    }
    
    func showWidget() { isVisible = true }
    func hideWidget() { isVisible = false }
    func toggleWidget() { isVisible.toggle() }
    func isWidgetVisible() -> Bool { return isVisible }
    func updateWeight(_ weight: Double) { currentWeight = weight }
    
    func setPosition(_ position: WidgetPosition) {}
    func getPosition() -> WidgetPosition { return .topRight }
    func setOpacity(_ opacity: CGFloat) {}
    func getOpacity() -> CGFloat { return 0.9 }
    func setSize(_ size: WidgetSize) {}
    func getCurrentSize() -> WidgetSize { return .medium }
    func setAutoHide(_ enabled: Bool, delay: TimeInterval = 3.0) {}
    func isAutoHideEnabled() -> Bool { return false }
    func getAutoHideDelay() -> TimeInterval { return 3.0 }
    
    func getStatusDescription() -> String { return "Compact Widget: Stub" }
    func getDetailedStatus() -> String { return "Stub implementation" }
}

#endif