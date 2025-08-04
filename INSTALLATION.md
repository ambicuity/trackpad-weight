# Installation Guide

Complete step-by-step installation guide for TrackPad Weight Scale on macOS.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Pre-Installation Checks](#pre-installation-checks)
3. [Installation Methods](#installation-methods)
4. [Post-Installation Setup](#post-installation-setup)
5. [Troubleshooting Installation Issues](#troubleshooting-installation-issues)
6. [Uninstallation](#uninstallation)

## System Requirements

### Minimum Requirements

- **Operating System**: macOS 13.0 (Ventura) or later
- **Hardware**: MacBook with Force Touch trackpad (see [COMPATIBILITY.md](COMPATIBILITY.md))
- **Memory**: 50MB available RAM
- **Storage**: 10MB available disk space
- **Development Tools**: Xcode Command Line Tools (for building from source)

### Recommended Requirements

- **Operating System**: macOS 14.0 (Sonoma) or later
- **Memory**: 100MB available RAM
- **Storage**: 50MB available disk space (for logs and exports)
- **Network**: Internet connection (for API features)

### Supported MacBook Models

✅ **Fully Supported**:
- MacBook Pro (2015 and later)
- MacBook Air (2018 and later)
- MacBook 12-inch (2016-2017)

❌ **Not Supported**:
- MacBook Pro (2014 and earlier)
- MacBook Air (2017 and earlier)
- iMac, Mac Mini, Mac Pro (no Force Touch trackpad)

## Pre-Installation Checks

### 1. Verify Force Touch Capability

```bash
# Method 1: System Information
Apple Menu → About This Mac → System Report → Hardware → Trackpad

# Method 2: System Preferences
System Preferences → Trackpad → Point & Click → Force Click and haptic feedback
```

**Expected Result**: Force Click option should be available and enabled.

### 2. Check macOS Version

```bash
# Terminal command
sw_vers

# Expected output (minimum):
ProductName:    macOS
ProductVersion: 13.0
BuildVersion:   22A380
```

### 3. Verify Xcode Command Line Tools

```bash
# Check if installed
xcode-select --print-path

# If not installed, install with:
xcode-select --install
```

### 4. Test Swift Installation

```bash
# Check Swift version
swift --version

# Expected output (minimum):
swift-driver version: 1.87.1
Target: x86_64-apple-macosx13.0
```

## Installation Methods

### Method 1: Quick Install (Recommended)

This is the fastest way to get started.

```bash
# 1. Clone the repository
git clone https://github.com/ambicuity/trackpad-weight.git

# 2. Navigate to directory
cd trackpad-weight

# 3. Build and run
swift run TrackpadWeight
```

**Installation Time**: 1-2 minutes

### Method 2: Release Build Install

For better performance and permanent installation.

```bash
# 1. Clone the repository
git clone https://github.com/ambicuity/trackpad-weight.git

# 2. Navigate to directory
cd trackpad-weight

# 3. Build release version
swift build -c release

# 4. Create application directory
mkdir -p ~/Applications/TrackpadWeight

# 5. Copy executable
cp ./.build/release/TrackpadWeight ~/Applications/TrackpadWeight/

# 6. Create launch script
cat > ~/Applications/TrackpadWeight/TrackpadWeight.command << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
./TrackpadWeight
EOF

# 7. Make executable
chmod +x ~/Applications/TrackpadWeight/TrackpadWeight.command
```

**Installation Time**: 2-3 minutes

### Method 3: Xcode Development Install

For developers who want to modify the code.

```bash
# 1. Clone the repository
git clone https://github.com/ambicuity/trackpad-weight.git

# 2. Navigate to directory
cd trackpad-weight

# 3. Generate Xcode project
swift package generate-xcodeproj

# 4. Open in Xcode
open TrackpadWeight.xcodeproj
```

Then in Xcode:
1. Select TrackpadWeight scheme
2. Choose your Mac as the destination
3. Press Cmd+R to build and run

**Installation Time**: 3-5 minutes

### Method 4: App Bundle Creation

Create a proper macOS app bundle.

```bash
# 1. Clone and build
git clone https://github.com/ambicuity/trackpad-weight.git
cd trackpad-weight
swift build -c release

# 2. Create app bundle structure
mkdir -p TrackpadWeight.app/Contents/MacOS
mkdir -p TrackpadWeight.app/Contents/Resources

# 3. Copy executable
cp ./.build/release/TrackpadWeight TrackpadWeight.app/Contents/MacOS/

# 4. Create Info.plist
cat > TrackpadWeight.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TrackpadWeight</string>
    <key>CFBundleIdentifier</key>
    <string>com.ambicuity.trackpadweight</string>
    <key>CFBundleName</key>
    <string>TrackPad Weight Scale</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>© 2025 TrackPad Weight Scale</string>
</dict>
</plist>
EOF

# 5. Move to Applications
mv TrackpadWeight.app /Applications/
```

**Installation Time**: 3-4 minutes

## Post-Installation Setup

### 1. Grant Necessary Permissions

#### Accessibility Permissions

The app needs accessibility permissions to access trackpad data.

```bash
# System Preferences → Security & Privacy → Privacy → Accessibility
# Click lock to make changes (enter admin password)
# Click '+' and add TrackpadWeight
```

**Why needed**: To access low-level trackpad pressure data.

#### Input Monitoring (if required)

Some macOS versions may require additional permissions.

```bash
# System Preferences → Security & Privacy → Privacy → Input Monitoring
# Add TrackpadWeight if prompted
```

### 2. Configure Force Touch Settings

```bash
# System Preferences → Trackpad → Point & Click
# ✓ Force Click and haptic feedback: ON
# Click pressure: Medium (recommended)
```

### 3. Initial Calibration

1. **Launch the application**
   ```bash
   # If using Method 1 or 2:
   ~/Applications/TrackpadWeight/TrackpadWeight.command
   
   # If using app bundle:
   open /Applications/TrackpadWeight.app
   ```

2. **Look for menu bar icon** (⚖️)

3. **Calibrate the scale**
   ```
   Click menu bar icon → "Calibrate"
   ```

4. **Test with known weight**
   ```
   Place a US quarter (5.67g) on trackpad while maintaining finger contact
   Reading should show approximately 5.5-6.0g
   ```

### 4. Optional Features Setup

#### Enable Logging

```bash
# Click menu bar icon → "Enable Logging"
# Logs saved to: ~/Documents/TrackpadWeight/
```

#### Configure API Server

```bash
# Click menu bar icon → "API Server" → Enable
# Server available at: http://localhost:8080
# API documentation: http://localhost:8080/docs
```

#### Set Up Auto-Start (Optional)

To start TrackpadWeight automatically on login:

```bash
# Method 1: System Preferences
# System Preferences → Users & Groups → Login Items
# Click '+' and add TrackpadWeight.app

# Method 2: Terminal
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/TrackpadWeight.app", hidden:false}'
```

## Troubleshooting Installation Issues

### Issue: "Command not found: swift"

**Problem**: Swift toolchain not installed.

**Solution**:
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Or install full Xcode from App Store
```

### Issue: "No such module 'Cocoa'"

**Problem**: Building on non-macOS system.

**Solution**: TrackpadWeight requires macOS. The app will show a demo mode on other platforms.

### Issue: Permission Denied Errors

**Problem**: Insufficient permissions to build or run.

**Solution**:
```bash
# Make sure you have write access to the directory
chmod -R 755 trackpad-weight/

# If copying to Applications folder:
sudo cp -R TrackpadWeight.app /Applications/
```

### Issue: "No devices available" or Build Errors

**Problem**: Xcode project configuration issues.

**Solution**:
```bash
# Clean and rebuild
swift package clean
swift build -c release

# Or reset Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/TrackpadWeight-*
```

### Issue: App Doesn't Appear in Menu Bar

**Problem**: Application launched but no menu bar icon.

**Solution**:
```bash
# Check if app is running
ps aux | grep TrackpadWeight

# Force quit if running
pkill -f TrackpadWeight

# Restart application
swift run TrackpadWeight
```

### Issue: Force Touch Not Working

**Problem**: Trackpad not responding to pressure.

**Solution**:
```bash
# 1. Check Force Touch is enabled
# System Preferences → Trackpad → Force Click and haptic feedback

# 2. Reset trackpad settings
# System Preferences → Trackpad → Reset to Defaults

# 3. Restart Mac if issues persist
```

### Issue: Build Takes Very Long

**Problem**: Slow compilation on older Macs.

**Solution**:
```bash
# Build with fewer parallel jobs
swift build -c release --jobs 2

# Or build debug version (faster)
swift build
```

### Issue: "App is damaged" Error

**Problem**: Gatekeeper blocking the application.

**Solution**:
```bash
# Remove quarantine attribute
xattr -rd com.apple.quarantine /Applications/TrackpadWeight.app

# Or allow in System Preferences
# System Preferences → Security & Privacy → General → Allow apps downloaded from: App Store and identified developers
```

### Issue: High CPU Usage

**Problem**: Application using too much CPU.

**Solution**:
```bash
# Check monitoring frequency settings
# Reduce API polling rate if enabled
# Disable logging if not needed
# Close other resource-intensive applications
```

### Issue: Network/API Server Problems

**Problem**: API server won't start or is inaccessible.

**Solution**:
```bash
# Check port availability
lsof -i :8080

# Try different port
# Menu Bar → API Settings → Change port to 8081

# Check firewall settings
# System Preferences → Security & Privacy → Firewall
```

## Uninstallation

### Complete Uninstallation

```bash
# 1. Quit the application
pkill -f TrackpadWeight

# 2. Remove application files
rm -rf ~/Applications/TrackpadWeight/
rm -rf /Applications/TrackpadWeight.app

# 3. Remove user data (optional)
rm -rf ~/Documents/TrackpadWeight/
rm -rf ~/Library/Preferences/com.ambicuity.trackpadweight.*

# 4. Remove from login items (if added)
osascript -e 'tell application "System Events" to delete every login item whose path contains "TrackpadWeight"'

# 5. Remove source code (if cloned)
rm -rf ~/trackpad-weight/  # or wherever you cloned it
```

### Partial Uninstallation (Keep Data)

```bash
# Only remove application, keep logs and settings
pkill -f TrackpadWeight
rm -rf ~/Applications/TrackpadWeight/
rm -rf /Applications/TrackpadWeight.app
```

### Reset to Default Settings

```bash
# Keep app installed but reset all settings
pkill -f TrackpadWeight
rm -rf ~/Library/Preferences/com.ambicuity.trackpadweight.*

# Restart application to recreate default settings
swift run TrackpadWeight
```

## Verification and Testing

### Post-Installation Checklist

After installation, verify everything works:

- [ ] Application launches without errors
- [ ] Menu bar icon appears (⚖️)
- [ ] Main window opens when clicking "Show Weight Scale"
- [ ] Calibration function works
- [ ] Weight readings appear when placing objects on trackpad
- [ ] No permission dialogs appear (after initial setup)

### Performance Test

```bash
# Test basic functionality
# 1. Calibrate scale
# 2. Place known weight (coin) on trackpad
# 3. Verify reading is within expected range
# 4. Remove weight, verify returns to near zero
# 5. Test multiple weights
```

### Stress Test

```bash
# Test stability
# 1. Run application for 30+ minutes
# 2. Perform frequent calibrations
# 3. Test with various weights
# 4. Monitor CPU and memory usage
# 5. Check for memory leaks or crashes
```

## Advanced Configuration

### Custom Build Options

```bash
# Build with debug symbols
swift build -c debug

# Build for specific architecture
swift build -c release --arch arm64

# Build with optimizations
swift build -c release -Xswiftc -O
```

### Environment Variables

```bash
# Set custom log level
export TRACKPAD_WEIGHT_LOG_LEVEL=debug

# Set custom API port
export TRACKPAD_WEIGHT_API_PORT=8080

# Disable auto-updates
export TRACKPAD_WEIGHT_AUTO_UPDATE=false
```

### Developer Options

```bash
# Enable development mode
export TRACKPAD_WEIGHT_DEV_MODE=true

# Enable verbose logging
export TRACKPAD_WEIGHT_VERBOSE=true

# Set custom data directory
export TRACKPAD_WEIGHT_DATA_DIR=~/CustomTrackpadData
```

---

## Support and Documentation

- **Examples**: See [EXAMPLES.md](EXAMPLES.md) for detailed usage examples
- **Compatibility**: See [COMPATIBILITY.md](COMPATIBILITY.md) for model-specific information
- **API Documentation**: Start API server and visit http://localhost:8080/docs
- **Issues**: Report bugs at https://github.com/ambicuity/trackpad-weight/issues
- **Discussions**: Community support at https://github.com/ambicuity/trackpad-weight/discussions

---

**Last Updated**: January 2025
**Installation Guide Version**: 2.0