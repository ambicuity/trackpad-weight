#if canImport(Cocoa)
import Cocoa
import CoreFoundation
import IOKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var window: NSWindow?
    var trackpadMonitor: ForceTrackpadMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupWindow()
        startTrackpadMonitoring()
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.button?.title = "⚖️ 0.0g"
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Weight Scale", action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Calibrate", action: #selector(calibrate), keyEquivalent: ""))
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
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        trackpadMonitor?.stopMonitoring()
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