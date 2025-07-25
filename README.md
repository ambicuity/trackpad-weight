# TrackPad Weight Scale

A macOS application that turns your trackpad into a digital weighing scale using the Open Multi-Touch Support library for precise Force Touch pressure sensing.

## Features

- **Enhanced Pressure Sensing**: Uses Open Multi-Touch Support library for direct access to trackpad multitouch data
- **Real-time Weight Measurement**: Precise pressure readings converted directly to weight in grams
- **Menu Bar Integration**: Convenient access from the system menu bar
- **Advanced Calibration**: Zero-point calibration with multitouch pressure data for accurate measurements
- **Native macOS UI**: Clean, native interface that fits with macOS design
- **Multi-Touch Support**: Aggregates pressure from multiple touch points for comprehensive weight calculation

## How It Works

TrackWeight utilizes a custom fork of the Open Multi-Touch Support library by Takuto Nakamura to gain private access to all mouse and trackpad events on macOS. This library provides detailed touch data including pressure readings that are normally inaccessible to standard applications.

The key insight is that trackpad pressure events are only generated when there's capacitance detected on the trackpad surface - meaning your finger (or another conductive object) must be in contact with the trackpad. When this condition is met, the trackpad's Force Touch sensors provide precise pressure readings that can be calibrated and converted into weight measurements.

According to our testing, the data from MultitouchSupport is already calibrated in grams!

## Requirements

- macOS 13.0 or later
- MacBook with Force Touch trackpad (2015 or newer MacBook Pro, 2016 or newer MacBook)
- App Sandbox disabled (required for low-level trackpad access via MultitouchSupport)
- Swift 5.9 or later
- Xcode 16.0+ and Swift 6.0+ (for development)

## Installation

### Building from Source

```bash
git clone https://github.com/ambicuity/trackpad-weight.git
cd trackpad-weight
swift build -c release
```

### Running the Application

```bash
swift run
```

Or build and run the executable:

```bash
swift build -c release
./.build/release/TrackpadWeight
```

## Usage

1. **Launch the App**: Run the application - it will appear in your menu bar with a scale icon (⚖️)
2. **View Weight**: Click the menu bar icon to see the current weight reading
3. **Open Main Window**: Select "Show Weight Scale" from the menu for a larger display
4. **Calibrate**: Use the "Calibrate" option to set a zero point for accurate measurements
5. **Weigh Items**: Place items gently on your trackpad to see their weight

## Technical Details

### Enhanced Architecture

The application is built using:

- **Open Multi-Touch Support Library**: Custom integration for direct multitouch data access
- **SwiftUI/Cocoa**: Native user interface components
- **Combine**: Reactive data flow for real-time updates
- **Private MultitouchSupport Framework**: Low-level access to trackpad pressure sensors

### Pressure Detection System

- **Primary Method**: MultitouchSupport framework for precise multitouch data
- **Fallback Method**: NSEvent Force Touch monitoring for compatibility
- **Pressure Aggregation**: Combines pressure from multiple touch points
- **Real-time Processing**: Continuous monitoring with live weight readings

### Calibration Process

The weight calculations have been validated by:

1. Placing the MacBook trackpad directly on top of a conventional digital scale
2. Applying various known weights while maintaining finger contact with the trackpad
3. Comparing and calibrating the pressure readings against the reference scale measurements
4. Ensuring consistent accuracy across different weight ranges

It turns out that the data we get from MultitouchSupport is already in grams!

## Limitations

- **Finger contact required**: The trackpad only provides pressure readings when it detects capacitance (finger touch), so you cannot weigh objects directly without maintaining contact
- **Surface contact**: Objects being weighed must be placed in a way that doesn't interfere with the required finger contact
- **Metal objects**: Metal objects may be detected as a finger touch, so you may need to place a piece of paper or a cloth between the object and the trackpad to get an accurate reading
- **Best suited for lightweight items**: Optimal for items under 500g
- **Requires careful placement**: Avoid interference from palm rejection

## Development

### Project Structure

```
Sources/
├── TrackpadWeight/
│   ├── main.swift                 # Application entry point
│   ├── MultitouchSupport.swift    # Open Multi-Touch Support integration
│   ├── TrackpadMonitor.swift      # Enhanced pressure sensing logic
│   └── WeightDisplayView.swift    # UI components

Tests/
└── TrackpadWeightTests/
    └── TrackpadWeightTests.swift  # Comprehensive unit tests
```

### Building and Testing

```bash
# Build the project
swift build

# Run tests
swift test

# Build for release
swift build -c release
```

### Open Multi-Touch Support Library

This project relies heavily on the excellent work by Takuto Nakamura (@Kyome22) and the Open Multi-Touch Support library. The library provides:

- Access to global multitouch events on macOS trackpads
- Detailed touch data including position, pressure, angle, and density
- Thread-safe async/await support for touch event streams
- Touch state tracking and comprehensive sensor data

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is available under the MIT License.

## Disclaimer

This application is for demonstration and educational purposes. It should not be used for precise measurements or commercial weighing applications. Always use proper calibrated scales for important measurements.