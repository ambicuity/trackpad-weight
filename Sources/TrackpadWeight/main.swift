#if canImport(Cocoa)
import Cocoa
import CoreFoundation
import IOKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var window: NSWindow?
    var trackpadMonitor: ForceTrackpadMonitor?
    var weightLogger: WeightLogger?
    var autoTareManager: AutoTareManager?
    var comparisonManager: ComparisonManager?
    var compactWidget: CompactWeightWidget?
    var apiServer: APIServer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWeightLogger()
        setupAutoTare()
        setupComparisonManager()
        setupCompactWidget()
        setupAPIServer()
        setupStatusBar()
        setupWindow()
        setupThemeNotifications()
        setupAPINotifications()
        startTrackpadMonitoring()
    }
    
    private func setupWeightLogger() {
        weightLogger = WeightLogger()
        print("WeightLogger initialized with directory: \(weightLogger?.getLogDirectory().path ?? "unknown")")
    }
    
    private func setupAutoTare() {
        autoTareManager = AutoTareManager()
        autoTareManager?.setTareCallback { [weak self] in
            self?.trackpadMonitor?.calibrate()
        }
        print("AutoTareManager initialized: \(autoTareManager?.getStatusDescription() ?? "unknown")")
    }
    
    private func setupComparisonManager() {
        comparisonManager = ComparisonManager()
        comparisonManager?.setStatusCallback { _ in
            // Update UI with comparison status if needed
            print("Comparison Status: \(status)")
        }
        print("ComparisonManager initialized: \(comparisonManager?.getStatusDescription() ?? "unknown")")
    }
    
    private func setupCompactWidget() {
        compactWidget = CompactWeightWidget()
        
        // Show widget if it was visible when app was last closed
        if compactWidget?.isWidgetVisible() == true {
            compactWidget?.showWidget()
        }
        
        print("CompactWeightWidget initialized: \(compactWidget?.getStatusDescription() ?? "unknown")")
    }
    
    private func setupAPIServer() {
        apiServer = APIServer()
        apiServer?.setDataProviders(
            weightLogger: weightLogger,
            comparisonManager: comparisonManager,
            autoTareManager: autoTareManager,
            compactWidget: compactWidget
        )
        
        print("APIServer initialized: \(apiServer?.getStatusDescription() ?? "unknown")")
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.button?.title = "⚖️ 0.0g"
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Weight Scale", action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Calibrate", action: #selector(calibrate), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Add logging menu items
        menu.addItem(NSMenuItem(title: "Export Weight Log (CSV)", action: #selector(exportCSV), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Export Weight Log (JSON)", action: #selector(exportJSON), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "View Log Summary", action: #selector(showLogSummary), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Add theme submenu
        let themeSubmenu = NSMenu()
        for theme in AppTheme.allCases {
            let item = NSMenuItem(title: theme.displayName, action: #selector(selectTheme(_:)), keyEquivalent: "")
            item.representedObject = theme
            item.state = ThemeManager.shared.currentTheme == theme ? .on : .off
            themeSubmenu.addItem(item)
        }
        let themeMenuItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeMenuItem.submenu = themeSubmenu
        menu.addItem(themeMenuItem)
        
        // Add font size submenu
        let fontSubmenu = NSMenu()
        for fontSize in FontSize.allCases {
            let item = NSMenuItem(title: fontSize.displayName, action: #selector(selectFontSize(_:)), keyEquivalent: "")
            item.representedObject = fontSize
            item.state = ThemeManager.shared.fontSize == fontSize ? .on : .off
            fontSubmenu.addItem(item)
        }
        let fontMenuItem = NSMenuItem(title: "Font Size", action: nil, keyEquivalent: "")
        fontMenuItem.submenu = fontSubmenu
        menu.addItem(fontMenuItem)
        
        // Add accessibility toggle
        let voiceOverItem = NSMenuItem(title: "VoiceOver Support", action: #selector(toggleVoiceOver), keyEquivalent: "")
        voiceOverItem.state = ThemeManager.shared.isVoiceOverEnabled ? .on : .off
        menu.addItem(voiceOverItem)
        menu.addItem(NSMenuItem.separator())
        
        // Add auto-tare menu items
        let autoTareToggleItem = NSMenuItem(title: "Auto-Tare", action: #selector(toggleAutoTare), keyEquivalent: "")
        autoTareToggleItem.state = autoTareManager?.isAutoTareEnabled() == true ? .on : .off
        menu.addItem(autoTareToggleItem)
        
        let autoTareStatusItem = NSMenuItem(title: "Auto-Tare Settings...", action: #selector(showAutoTareSettings), keyEquivalent: "")
        menu.addItem(autoTareStatusItem)
        menu.addItem(NSMenuItem.separator())
        
        // Add comparison mode menu items
        let comparisonToggleItem = NSMenuItem(title: "Comparison Mode", action: #selector(toggleComparisonMode), keyEquivalent: "")
        comparisonToggleItem.state = comparisonManager?.isInComparisonMode() == true ? .on : .off
        menu.addItem(comparisonToggleItem)
        
        let comparisonSubmenu = NSMenu()
        comparisonSubmenu.addItem(NSMenuItem(title: "Tare for Comparison", action: #selector(tareForComparison), keyEquivalent: ""))
        comparisonSubmenu.addItem(NSMenuItem(title: "Set Reference Weight", action: #selector(setReferenceWeight), keyEquivalent: ""))
        comparisonSubmenu.addItem(NSMenuItem(title: "Export Comparisons", action: #selector(exportComparisons), keyEquivalent: ""))
        comparisonSubmenu.addItem(NSMenuItem(title: "Comparison Status...", action: #selector(showComparisonStatus), keyEquivalent: ""))
        let comparisonMenuItem = NSMenuItem(title: "Comparison Tools", action: nil, keyEquivalent: "")
        comparisonMenuItem.submenu = comparisonSubmenu
        menu.addItem(comparisonMenuItem)
        menu.addItem(NSMenuItem.separator())
        
        // Add compact widget menu items
        let widgetToggleItem = NSMenuItem(title: "Show Compact Widget", action: #selector(toggleCompactWidget), keyEquivalent: "")
        widgetToggleItem.state = compactWidget?.isWidgetVisible() == true ? .on : .off
        menu.addItem(widgetToggleItem)
        
        let widgetSubmenu = NSMenu()
        
        // Position submenu
        let positionSubmenu = NSMenu()
        for position in CompactWeightWidget.WidgetPosition.allCases {
            let item = NSMenuItem(title: position.displayName, action: #selector(selectWidgetPosition(_:)), keyEquivalent: "")
            item.representedObject = position
            item.state = compactWidget?.getPosition() == position ? .on : .off
            positionSubmenu.addItem(item)
        }
        let positionMenuItem = NSMenuItem(title: "Position", action: nil, keyEquivalent: "")
        positionMenuItem.submenu = positionSubmenu
        widgetSubmenu.addItem(positionMenuItem)
        
        // Size submenu
        let sizeSubmenu = NSMenu()
        for size in CompactWeightWidget.WidgetSize.allCases {
            let item = NSMenuItem(title: size.displayName, action: #selector(selectWidgetSize(_:)), keyEquivalent: "")
            item.representedObject = size
            item.state = compactWidget?.getCurrentSize() == size ? .on : .off
            sizeSubmenu.addItem(item)
        }
        let sizeMenuItem = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        sizeMenuItem.submenu = sizeSubmenu
        widgetSubmenu.addItem(sizeMenuItem)
        
        widgetSubmenu.addItem(NSMenuItem.separator())
        widgetSubmenu.addItem(NSMenuItem(title: "Widget Settings...", action: #selector(showWidgetSettings), keyEquivalent: ""))
        
        let widgetMenuItem = NSMenuItem(title: "Widget Options", action: nil, keyEquivalent: "")
        widgetMenuItem.submenu = widgetSubmenu
        menu.addItem(widgetMenuItem)
        menu.addItem(NSMenuItem.separator())
        
        // Add API server menu items
        let apiToggleItem = NSMenuItem(title: "API Server", action: #selector(toggleAPIServer), keyEquivalent: "")
        apiToggleItem.state = apiServer?.isServerRunning() == true ? .on : .off
        menu.addItem(apiToggleItem)
        
        let apiStatusItem = NSMenuItem(title: "API Settings...", action: #selector(showAPISettings), keyEquivalent: "")
        menu.addItem(apiStatusItem)
        menu.addItem(NSMenuItem.separator())
        
        let loggingToggleItem = NSMenuItem(title: "Enable Logging", action: #selector(toggleLogging), keyEquivalent: "")
        loggingToggleItem.state = weightLogger?.isLogging() == true ? .on : .off
        menu.addItem(loggingToggleItem)
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    private func setupWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "Trackpad Weight Scale"
        window?.center()
        
        let contentView = WeightDisplayView()
        window?.contentView = contentView
        
        // Set up the trackpad monitor callback
        // Using Force Touch monitor for better macOS integration
        trackpadMonitor = ForceTrackpadMonitor { [weak self] weight in
            DispatchQueue.main.async {
                self?.updateWeight(weight)
                contentView.updateWeight(weight)
                
                // Process weight for auto-tare
                self?.autoTareManager?.processWeightReading(weight)
                
                // Process weight for comparison
                self?.comparisonManager?.processWeight(weight)
                
                // Update compact widget
                self?.compactWidget?.updateWeight(weight)
                
                // Update API server
                self?.apiServer?.updateWeight(weight)
                
                // Log the weight reading
                self?.weightLogger?.logWeight(weight)
            }
        }
    }
    
    private func startTrackpadMonitoring() {
        trackpadMonitor?.startMonitoring()
    }
    
    private func updateWeight(_ weight: Double) {
        statusBarItem?.button?.title = String(format: "⚖️ %.1fg", weight)
    }
    
    @objc private func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func calibrate() {
        trackpadMonitor?.calibrate()
        weightLogger?.startNewSession() // Start a new logging session after calibration
    }
    
    @objc private func exportCSV() {
        guard let url = weightLogger?.exportToCSV() else {
            showAlert(title: "Export Failed", message: "Could not export weight log to CSV.")
            return
        }
        
        showExportSuccess(url: url, format: "CSV")
    }
    
    @objc private func exportJSON() {
        guard let url = weightLogger?.exportToJSON() else {
            showAlert(title: "Export Failed", message: "Could not export weight log to JSON.")
            return
        }
        
        showExportSuccess(url: url, format: "JSON")
    }
    
    @objc private func showLogSummary() {
        let summary = weightLogger?.getSessionSummary() ?? "Weight logging not available"
        showAlert(title: "Weight Log Summary", message: summary)
    }
    
    @objc private func toggleLogging() {
        let isCurrentlyLogging = weightLogger?.isLogging() ?? false
        weightLogger?.setLoggingEnabled(!isCurrentlyLogging)
        
        // Update the menu item
        if let menu = statusBarItem?.menu,
           let loggingItem = menu.items.first(where: { $0.action == #selector(toggleLogging) }) {
            loggingItem.state = weightLogger?.isLogging() == true ? .on : .off
            loggingItem.title = weightLogger?.isLogging() == true ? "Disable Logging" : "Enable Logging"
        }
        
        let status = weightLogger?.isLogging() == true ? "enabled" : "disabled"
        showAlert(title: "Logging \(status.capitalized)", message: "Weight logging has been \(status).")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showExportSuccess(url: URL, format: String) {
        let alert = NSAlert()
        alert.messageText = "\(format) Export Successful"
        alert.informativeText = "Weight log exported to:\n\(url.path)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Reveal in Finder")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
        }
    }
    
    private func setupThemeNotifications() {
        NotificationCenter.default.addObserver(
            forName: .themeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateUIForThemeChange()
        }
    }
    
    private func setupAPINotifications() {
        NotificationCenter.default.addObserver(
            forName: .apiCalibrateRequest,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.trackpadMonitor?.calibrate()
        }
        
        NotificationCenter.default.addObserver(
            forName: .apiTareRequest,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let itemName = notification.object as? String ?? "API Item"
            self?.comparisonManager?.tareForComparison(name: itemName)
        }
    }
    
    private func updateUIForThemeChange() {
        // Update window appearance
        window?.contentView?.applyTheme()
        
        // Update menu checkmarks
        updateMenuCheckmarks()
    }
    
    private func updateMenuCheckmarks() {
        guard let menu = statusBarItem?.menu else { return }
        
        // Update theme submenu
        for item in menu.items {
            if item.title == "Theme", let submenu = item.submenu {
                for themeItem in submenu.items {
                    if let theme = themeItem.representedObject as? AppTheme {
                        themeItem.state = ThemeManager.shared.currentTheme == theme ? .on : .off
                    }
                }
            }
            
            if item.title == "Font Size", let submenu = item.submenu {
                for fontItem in submenu.items {
                    if let fontSize = fontItem.representedObject as? FontSize {
                        fontItem.state = ThemeManager.shared.fontSize == fontSize ? .on : .off
                    }
                }
            }
            
            if item.title == "VoiceOver Support" || item.title == "Disable VoiceOver Support" {
                item.state = ThemeManager.shared.isVoiceOverEnabled ? .on : .off
                item.title = ThemeManager.shared.isVoiceOverEnabled ? "Disable VoiceOver Support" : "VoiceOver Support"
            }
            
            if item.title == "Auto-Tare" {
                item.state = autoTareManager?.isAutoTareEnabled() == true ? .on : .off
            }
            
            if item.title == "Comparison Mode" {
                item.state = comparisonManager?.isInComparisonMode() == true ? .on : .off
            }
            
            if item.title == "Show Compact Widget" || item.title == "Hide Compact Widget" {
                item.state = compactWidget?.isWidgetVisible() == true ? .on : .off
                item.title = compactWidget?.isWidgetVisible() == true ? "Hide Compact Widget" : "Show Compact Widget"
            }
            
            // Update widget submenu checkmarks
            if item.title == "Widget Options", let submenu = item.submenu {
                for subItem in submenu.items {
                    if subItem.title == "Position", let positionSubmenu = subItem.submenu {
                        for positionItem in positionSubmenu.items {
                            if let position = positionItem.representedObject as? CompactWeightWidget.WidgetPosition {
                                positionItem.state = compactWidget?.getPosition() == position ? .on : .off
                            }
                        }
                    }
                    
                    if subItem.title == "Size", let sizeSubmenu = subItem.submenu {
                        for sizeItem in sizeSubmenu.items {
                            if let size = sizeItem.representedObject as? CompactWeightWidget.WidgetSize {
                                sizeItem.state = compactWidget?.getCurrentSize() == size ? .on : .off
                            }
                        }
                    }
                }
            }
            
            if item.title == "API Server" {
                item.state = apiServer?.isServerRunning() == true ? .on : .off
            }
        }
    }
    
    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? AppTheme else { return }
        ThemeManager.shared.setTheme(theme)
    }
    
    @objc private func selectFontSize(_ sender: NSMenuItem) {
        guard let fontSize = sender.representedObject as? FontSize else { return }
        ThemeManager.shared.setFontSize(fontSize)
    }
    
    @objc private func toggleVoiceOver() {
        ThemeManager.shared.toggleVoiceOver()
        updateMenuCheckmarks()
    }
    
    @objc private func toggleAutoTare() {
        let currentState = autoTareManager?.isAutoTareEnabled() ?? false
        autoTareManager?.setEnabled(!currentState)
        updateMenuCheckmarks()
        
        let status = autoTareManager?.isAutoTareEnabled() == true ? "enabled" : "disabled"
        showAlert(title: "Auto-Tare \(status.capitalized)", 
                 message: "Auto-tare has been \(status). The scale will \(status == "enabled" ? "automatically zero when a new touch session is detected" : "no longer automatically zero").")
    }
    
    @objc private func showAutoTareSettings() {
        let status = autoTareManager?.getDetailedStatus() ?? "Auto-tare not available"
        showAlert(title: "Auto-Tare Settings", message: status)
    }
    
    @objc private func toggleComparisonMode() {
        let currentState = comparisonManager?.isInComparisonMode() ?? false
        comparisonManager?.setComparisonMode(!currentState)
        updateMenuCheckmarks()
        
        let status = comparisonManager?.isInComparisonMode() == true ? "enabled" : "disabled"
        showAlert(title: "Comparison Mode \(status.capitalized)", 
                 message: "Comparison mode has been \(status). \(status == "enabled" ? "You can now tare and compare weights with reference items." : "Weight comparison features are disabled.")")
    }
    
    @objc private func tareForComparison() {
        guard comparisonManager?.isInComparisonMode() == true else {
            showAlert(title: "Comparison Mode Disabled", message: "Please enable comparison mode first.")
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Tare for Comparison"
        alert.informativeText = "Enter a name for the item you want to compare:"
        alert.addButton(withTitle: "Tare")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = "Item \(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1000))"
        alert.accessoryView = textField
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let itemName = textField.stringValue.isEmpty ? "Unnamed Item" : textField.stringValue
            comparisonManager?.tareForComparison(name: itemName)
            showAlert(title: "Tared for Comparison", message: "Scale tared for '\(itemName)'. Place the item on the scale to compare.")
        }
    }
    
    @objc private func setReferenceWeight() {
        guard comparisonManager?.isInComparisonMode() == true else {
            showAlert(title: "Comparison Mode Disabled", message: "Please enable comparison mode first.")
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Set Reference Weight"
        alert.informativeText = "Enter item name and reference weight:"
        alert.addButton(withTitle: "Set Reference")
        alert.addButton(withTitle: "Cancel")
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 8
        
        let nameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        nameField.placeholderString = "Item name"
        
        let weightField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        weightField.placeholderString = "Weight in grams"
        
        stackView.addArrangedSubview(NSTextField(labelWithString: "Item Name:"))
        stackView.addArrangedSubview(nameField)
        stackView.addArrangedSubview(NSTextField(labelWithString: "Weight (grams):"))
        stackView.addArrangedSubview(weightField)
        
        alert.accessoryView = stackView
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let itemName = nameField.stringValue.isEmpty ? "Reference Item" : nameField.stringValue
            if let weight = Double(weightField.stringValue), weight > 0 {
                comparisonManager?.setReferenceWeight(name: itemName, weight: weight)
                showAlert(title: "Reference Set", message: "Reference weight for '\(itemName)' set to \(weight)g")
            } else {
                showAlert(title: "Invalid Weight", message: "Please enter a valid weight greater than 0.")
            }
        }
    }
    
    @objc private func exportComparisons() {
        guard let url = comparisonManager?.exportComparisonsToCSV() else {
            showAlert(title: "Export Failed", message: "No comparison data to export or export failed.")
            return
        }
        
        showExportSuccess(url: url, format: "Comparison CSV")
    }
    
    @objc private func showComparisonStatus() {
        let status = comparisonManager?.getDetailedStatus() ?? "Comparison manager not available"
        let summary = comparisonManager?.getComparisonSummary() ?? ""
        let fullStatus = status + "\n\n" + summary
        showAlert(title: "Comparison Status", message: fullStatus)
    }
    
    @objc private func toggleCompactWidget() {
        compactWidget?.toggleWidget()
        updateMenuCheckmarks()
        
        let status = compactWidget?.isWidgetVisible() == true ? "shown" : "hidden"
        showAlert(title: "Compact Widget \(status.capitalized)", 
                 message: "The compact weight display widget has been \(status).")
    }
    
    @objc private func selectWidgetPosition(_ sender: NSMenuItem) {
        guard let position = sender.representedObject as? CompactWeightWidget.WidgetPosition else { return }
        compactWidget?.setPosition(position)
        updateMenuCheckmarks()
    }
    
    @objc private func selectWidgetSize(_ sender: NSMenuItem) {
        guard let size = sender.representedObject as? CompactWeightWidget.WidgetSize else { return }
        compactWidget?.setSize(size)
        updateMenuCheckmarks()
    }
    
    @objc private func showWidgetSettings() {
        let status = compactWidget?.getDetailedStatus() ?? "Compact widget not available"
        
        let alert = NSAlert()
        alert.messageText = "Widget Settings"
        alert.informativeText = status
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Toggle Auto-Hide")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            let currentAutoHide = compactWidget?.isAutoHideEnabled() ?? false
            compactWidget?.setAutoHide(!currentAutoHide)
            
            let newStatus = compactWidget?.isAutoHideEnabled() == true ? "enabled" : "disabled"
            showAlert(title: "Auto-Hide \(newStatus.capitalized)", 
                     message: "Widget auto-hide has been \(newStatus).")
        }
    }
    
    @objc private func toggleAPIServer() {
        let isCurrentlyRunning = apiServer?.isServerRunning() ?? false
        
        if isCurrentlyRunning {
            apiServer?.stopServer()
        } else {
            let success = apiServer?.startServer() ?? false
            if !success {
                showAlert(title: "API Server Failed", message: "Could not start API server. Port may be in use.")
                return
            }
        }
        
        updateMenuCheckmarks()
        
        let status = apiServer?.isServerRunning() == true ? "started" : "stopped"
        let port = apiServer?.getPort() ?? 8080
        showAlert(title: "API Server \(status.capitalized)", 
                 message: "API server has been \(status).\(status == "started" ? " Available at http://localhost:\(port)" : "")")
    }
    
    @objc private func showAPISettings() {
        let status = apiServer?.getDetailedStatus() ?? "API server not available"
        
        let alert = NSAlert()
        alert.messageText = "API Server Settings"
        alert.informativeText = status
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open in Browser")
        alert.addButton(withTitle: "Configure Webhook")
        
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn {
            // Open API in browser
            let port = apiServer?.getPort() ?? 8080
            if let url = URL(string: "http://localhost:\(port)") {
                NSWorkspace.shared.open(url)
            }
        } else if response == .alertThirdButtonReturn {
            // Configure webhook
            let webhookAlert = NSAlert()
            webhookAlert.messageText = "Configure Webhook"
            webhookAlert.informativeText = "Enter webhook URL (leave empty to disable):"
            webhookAlert.addButton(withTitle: "Set")
            webhookAlert.addButton(withTitle: "Cancel")
            
            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
            textField.stringValue = apiServer?.getWebhookURL() ?? ""
            textField.placeholderString = "https://example.com/webhook"
            webhookAlert.accessoryView = textField
            
            let webhookResponse = webhookAlert.runModal()
            if webhookResponse == .alertFirstButtonReturn {
                let url = textField.stringValue.isEmpty ? nil : textField.stringValue
                apiServer?.setWebhookURL(url)
                
                let message = url != nil ? "Webhook URL set successfully" : "Webhook disabled"
                showAlert(title: "Webhook Configured", message: message)
            }
        }
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        trackpadMonitor?.stopMonitoring()
        apiServer?.stopServer()
        weightLogger = nil // Triggers cleanup and auto-save
    }
}

// macOS app entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

#else
// Cross-platform demonstration version for non-macOS systems
import Foundation

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

class WeightScaleDemo {
    private var isRunning = true
    private var currentWeight: Double = 0.0
    private var calibrationOffset: Double = 0.0
    
    func run() {
        print("\n⚖️  Simulated Trackpad Weight Scale")
        print("Commands: 'w' = add weight, 'r' = remove weight, 'c' = calibrate, 'q' = quit")
        print("Current weight: \(formatWeight(currentWeight))")
        
        while isRunning {
            print("\n> ", terminator: "")
            if let input = readLine()?.lowercased() {
                handleCommand(input)
            }
        }
    }
    
    private func handleCommand(_ command: String) {
        switch command {
        case "w":
            addWeight()
        case "r":
            removeWeight()
        case "c":
            calibrate()
        case "q":
            quit()
        default:
            print("Unknown command. Use 'w', 'r', 'c', or 'q'")
        }
    }
    
    private func addWeight() {
        let additionalWeight = Double.random(in: 5.0...50.0)
        currentWeight += additionalWeight
        
        // Prevent extremely large weights
        currentWeight = min(currentWeight, 10000.0)
        
        print("Added \(formatWeight(additionalWeight)) - Total: \(formatWeight(currentWeight))")
    }
    
    private func removeWeight() {
        if currentWeight > 0 {
            let removedWeight = min(currentWeight, Double.random(in: 5.0...25.0))
            currentWeight -= removedWeight
            currentWeight = max(0, currentWeight)
            print("Removed \(formatWeight(removedWeight)) - Total: \(formatWeight(currentWeight))")
        } else {
            print("No weight to remove")
        }
    }
    
    private func calibrate() {
        calibrationOffset = currentWeight
        currentWeight = 0.0
        print("Calibrated! Zero point set. Current weight: \(formatWeight(currentWeight))")
    }
    
    private func quit() {
        print("Goodbye! 👋")
        isRunning = false
    }
    
    private func formatWeight(_ weight: Double) -> String {
        // Handle special values
        if weight.isNaN {
            return "---g"
        }
        if weight.isInfinite {
            return weight > 0 ? "∞g" : "-∞g"
        }
        
        return String(format: "%.1fg", weight)
    }
}

// Non-macOS entry point
print("🍎 TrackPad Weight Scale for macOS")
print("=" * 40)
print("This application requires macOS with Force Touch trackpad support.")
print("Currently running on: \(ProcessInfo.processInfo.operatingSystemVersionString)")
print("")
print("📋 Features when running on macOS:")
print("• Real-time weight measurement using Force Touch")
print("• Menu bar integration with live weight display")
print("• Calibration support for accurate measurements")
print("• Native macOS UI with Cocoa framework")
print("")
print("🔧 To build and run on macOS:")
print("1. Clone this repository on a Mac")
print("2. Run: swift build -c release")
print("3. Run: ./.build/release/TrackpadWeight")
print("")
print("🧪 Running demonstration simulation...")

let demo = WeightScaleDemo()
demo.run()
#endif