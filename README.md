# TrackPad Weight Scale

A macOS application that turns your trackpad into a digital weighing scale using Force Touch technology.

## Features

- **Real-time Weight Measurement**: Uses Force Touch pressure sensing to measure weight
- **Menu Bar Integration**: Convenient access from the system menu bar
- **Calibration Support**: Zero-point calibration for accurate measurements
- **Native macOS UI**: Clean, native interface that fits with macOS design

## Requirements

- macOS 13.0 or later
- MacBook with Force Touch trackpad
- Swift 5.9 or later

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

## How It Works

The application uses macOS Force Touch events to detect pressure applied to the trackpad. This pressure data is converted to weight measurements through calibration and scaling algorithms.

### Technical Details

- **Pressure Detection**: Uses `NSEvent` pressure monitoring for Force Touch events
- **Calibration**: Establishes baseline and scaling factors for weight conversion
- **Real-time Updates**: Continuous monitoring provides live weight readings
- **UI Framework**: Native Cocoa/AppKit for optimal macOS integration

## Limitations

- Accuracy depends on trackpad sensitivity and calibration
- Best suited for lightweight items (under 500g)
- Requires careful placement to avoid interference from palm rejection
- Not suitable for precise measurements requiring scientific accuracy

## Calibration Tips

1. **Remove All Weight**: Ensure nothing is touching the trackpad during calibration
2. **Stable Surface**: Place your MacBook on a stable, flat surface
3. **Known Weights**: Use items of known weight to verify accuracy after calibration

## Development

### Project Structure

```
Sources/
├── TrackpadWeight/
│   ├── main.swift              # Application entry point
│   ├── TrackpadMonitor.swift   # Pressure sensing logic
│   └── WeightDisplayView.swift # UI components

Tests/
└── TrackpadWeightTests/
    └── TrackpadWeightTests.swift # Unit tests
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