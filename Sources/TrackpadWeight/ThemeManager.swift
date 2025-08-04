/**
 * ThemeManager - Theme Support & Accessibility Features
 * 
 * Implements Feature 6: Theme Support & Accessibility
 * - Light/dark mode switching
 * - High-contrast mode for better visibility  
 * - Support for large fonts and VoiceOver labels
 */

#if canImport(Cocoa)
import Foundation
import Cocoa

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case highContrast = "high_contrast"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark" 
        case .highContrast: return "High Contrast"
        }
    }
}

enum FontSize: String, CaseIterable {
    case normal = "normal"
    case large = "large"
    case extraLarge = "extra_large"
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .normal: return 1.0
        case .large: return 1.25
        case .extraLarge: return 1.5
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            saveThemePreference()
            applyTheme()
        }
    }
    
    @Published var fontSize: FontSize {
        didSet {
            saveFontSizePreference()
            applyTheme()
        }
    }
    
    @Published var isVoiceOverEnabled: Bool {
        didSet {
            saveVoiceOverPreference()
            updateAccessibility()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "app_theme"
    private let fontSizeKey = "font_size"
    private let voiceOverKey = "voice_over_enabled"
    
    // Theme color definitions
    private var colors: [String: NSColor] {
        switch currentTheme {
        case .system:
            return systemColors
        case .light:
            return lightColors
        case .dark:
            return darkColors
        case .highContrast:
            return highContrastColors
        }
    }
    
    private let systemColors: [String: NSColor] = [
        "background": NSColor.controlBackgroundColor,
        "primaryText": NSColor.labelColor,
        "secondaryText": NSColor.secondaryLabelColor,
        "tertiaryText": NSColor.tertiaryLabelColor,
        "accent": NSColor.controlAccentColor,
        "surface": NSColor.controlBackgroundColor,
        "border": NSColor.separatorColor
    ]
    
    private let lightColors: [String: NSColor] = [
        "background": NSColor.white,
        "primaryText": NSColor.black,
        "secondaryText": NSColor.darkGray,
        "tertiaryText": NSColor.gray,
        "accent": NSColor.systemBlue,
        "surface": NSColor(white: 0.98, alpha: 1.0),
        "border": NSColor.lightGray
    ]
    
    private let darkColors: [String: NSColor] = [
        "background": NSColor(white: 0.1, alpha: 1.0),
        "primaryText": NSColor.white,
        "secondaryText": NSColor.lightGray,
        "tertiaryText": NSColor.gray,
        "accent": NSColor.systemBlue,
        "surface": NSColor(white: 0.15, alpha: 1.0),
        "border": NSColor.darkGray
    ]
    
    private let highContrastColors: [String: NSColor] = [
        "background": NSColor.black,
        "primaryText": NSColor.white,
        "secondaryText": NSColor.white,
        "tertiaryText": NSColor.lightGray,
        "accent": NSColor.systemYellow,
        "surface": NSColor(white: 0.05, alpha: 1.0),
        "border": NSColor.white
    ]
    
    private init() {
        // Load saved preferences
        let savedTheme = userDefaults.string(forKey: themeKey) ?? AppTheme.system.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .system
        
        let savedFontSize = userDefaults.string(forKey: fontSizeKey) ?? FontSize.normal.rawValue
        self.fontSize = FontSize(rawValue: savedFontSize) ?? .normal
        
        self.isVoiceOverEnabled = userDefaults.bool(forKey: voiceOverKey)
        
        // Apply initial theme
        applyTheme()
        updateAccessibility()
    }
    
    // MARK: - Public Interface
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
    
    func setFontSize(_ size: FontSize) {
        fontSize = size
    }
    
    func toggleVoiceOver() {
        isVoiceOverEnabled.toggle()
    }
    
    // MARK: - Color Access
    
    func backgroundColor() -> NSColor {
        return colors["background"] ?? NSColor.controlBackgroundColor
    }
    
    func primaryTextColor() -> NSColor {
        return colors["primaryText"] ?? NSColor.labelColor
    }
    
    func secondaryTextColor() -> NSColor {
        return colors["secondaryText"] ?? NSColor.secondaryLabelColor
    }
    
    func tertiaryTextColor() -> NSColor {
        return colors["tertiaryText"] ?? NSColor.tertiaryLabelColor
    }
    
    func accentColor() -> NSColor {
        return colors["accent"] ?? NSColor.controlAccentColor
    }
    
    func surfaceColor() -> NSColor {
        return colors["surface"] ?? NSColor.controlBackgroundColor
    }
    
    func borderColor() -> NSColor {
        return colors["border"] ?? NSColor.separatorColor
    }
    
    // MARK: - Font Access
    
    func primaryFont(size: CGFloat = 16) -> NSFont {
        let scaledSize = size * fontSize.scaleFactor
        let weight: NSFont.Weight = currentTheme == .highContrast ? .semibold : .regular
        return NSFont.systemFont(ofSize: scaledSize, weight: weight)
    }
    
    func titleFont(size: CGFloat = 24) -> NSFont {
        let scaledSize = size * fontSize.scaleFactor
        let weight: NSFont.Weight = currentTheme == .highContrast ? .bold : .medium
        return NSFont.systemFont(ofSize: scaledSize, weight: weight)
    }
    
    func displayFont(size: CGFloat = 48) -> NSFont {
        let scaledSize = size * fontSize.scaleFactor
        let weight: NSFont.Weight = currentTheme == .highContrast ? .bold : .light
        return NSFont.systemFont(ofSize: scaledSize, weight: weight)
    }
    
    func captionFont(size: CGFloat = 12) -> NSFont {
        let scaledSize = size * fontSize.scaleFactor
        let weight: NSFont.Weight = currentTheme == .highContrast ? .medium : .regular
        return NSFont.systemFont(ofSize: scaledSize, weight: weight)
    }
    
    // MARK: - Theme Application
    
    private func applyTheme() {
        DispatchQueue.main.async {
            // Update app appearance
            if self.currentTheme == .dark || self.currentTheme == .highContrast {
                NSApp.appearance = NSAppearance(named: .darkAqua)
            } else if self.currentTheme == .light {
                NSApp.appearance = NSAppearance(named: .aqua)
            } else {
                NSApp.appearance = nil // System default
            }
            
            // Notify all windows to update their appearance
            NotificationCenter.default.post(name: .themeDidChange, object: nil)
        }
    }
    
    private func updateAccessibility() {
        // Configure accessibility features
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .accessibilityDidChange, object: nil)
        }
    }
    
    // MARK: - Persistence
    
    private func saveThemePreference() {
        userDefaults.set(currentTheme.rawValue, forKey: themeKey)
    }
    
    private func saveFontSizePreference() {
        userDefaults.set(fontSize.rawValue, forKey: fontSizeKey)
    }
    
    private func saveVoiceOverPreference() {
        userDefaults.set(isVoiceOverEnabled, forKey: voiceOverKey)
    }
    
    // MARK: - Accessibility Helpers
    
    func configureAccessibility(for view: NSView, label: String, hint: String? = nil) {
        if isVoiceOverEnabled {
            view.setAccessibilityLabel(label)
            if let hint = hint {
                view.setAccessibilityHelp(hint)
            }
            view.setAccessibilityEnabled(true)
        }
    }
    
    func configureAccessibility(for button: NSButton, label: String, hint: String? = nil) {
        if isVoiceOverEnabled {
            button.setAccessibilityLabel(label)
            button.setAccessibilityRole(.button)
            if let hint = hint {
                button.setAccessibilityHelp(hint)
            }
            button.setAccessibilityEnabled(true)
        }
    }
    
    func configureAccessibility(for textField: NSTextField, label: String, hint: String? = nil) {
        if isVoiceOverEnabled {
            textField.setAccessibilityLabel(label)
            textField.setAccessibilityRole(.staticText)
            if let hint = hint {
                textField.setAccessibilityHelp(hint)
            }
            textField.setAccessibilityEnabled(true)
        }
    }
    
    // MARK: - High Contrast Helpers
    
    func isHighContrast() -> Bool {
        return currentTheme == .highContrast
    }
    
    func borderWidth() -> CGFloat {
        return isHighContrast() ? 2.0 : 1.0
    }
    
    func cornerRadius() -> CGFloat {
        return isHighContrast() ? 2.0 : 6.0
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
    static let accessibilityDidChange = Notification.Name("accessibilityDidChange")
}

// MARK: - Theme-Aware UI Helpers

extension NSView {
    @objc func applyTheme() {
        let theme = ThemeManager.shared
        
        // Apply background color if this is a container view
        if let layer = self.layer {
            layer.backgroundColor = theme.backgroundColor().cgColor
        }
        
        // Apply theme to subviews recursively
        for subview in subviews {
            subview.applyTheme()
        }
    }
}

extension NSTextField {
    override func applyTheme() {
        let theme = ThemeManager.shared
        
        // Apply text color based on current settings
        if isEditable {
            textColor = theme.primaryTextColor()
            backgroundColor = theme.surfaceColor()
        } else {
            // For labels, choose appropriate text color based on context
            if font?.pointSize ?? 0 > 24 {
                textColor = theme.primaryTextColor()
            } else if font?.pointSize ?? 0 > 16 {
                textColor = theme.secondaryTextColor()
            } else {
                textColor = theme.tertiaryTextColor()
            }
        }
        
        // Update font size if needed
        if let currentFont = font {
            font = theme.primaryFont(size: currentFont.pointSize)
        }
    }
}

extension NSButton {
    override func applyTheme() {
        let theme = ThemeManager.shared
        
        // Update button appearance based on theme
        if bezelStyle == .rounded {
            layer?.borderColor = theme.borderColor().cgColor
            layer?.borderWidth = theme.borderWidth()
            layer?.cornerRadius = theme.cornerRadius()
        }
        
        // Update font
        if let currentFont = font {
            font = theme.primaryFont(size: currentFont.pointSize)
        }
    }
}

#else
// Stub implementation for non-macOS platforms
import Foundation

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case highContrast = "high_contrast"
    
    var displayName: String { return rawValue }
}

enum FontSize: String, CaseIterable {
    case normal = "normal"
    case large = "large"
    case extraLarge = "extra_large"
    
    var displayName: String { return rawValue }
    var scaleFactor: CGFloat { return 1.0 }
}

class ThemeManager {
    static let shared = ThemeManager()
    
    var currentTheme: AppTheme = .system
    var fontSize: FontSize = .normal
    var isVoiceOverEnabled: Bool = false
    
    private init() {}
    
    func setTheme(_ theme: AppTheme) { currentTheme = theme }
    func setFontSize(_ size: FontSize) { fontSize = size }
    func toggleVoiceOver() { isVoiceOverEnabled.toggle() }
    func isHighContrast() -> Bool { return false }
}

#endif