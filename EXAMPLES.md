# TrackPad Weight Scale - Examples & Use Cases

This document provides detailed examples and real-world use cases for the TrackPad Weight Scale application.

## Table of Contents

1. [Basic Usage Examples](#basic-usage-examples)
2. [Real-World Use Cases](#real-world-use-cases)
3. [API Integration Examples](#api-integration-examples)
4. [Advanced Features](#advanced-features)
5. [Troubleshooting Common Issues](#troubleshooting-common-issues)

## Basic Usage Examples

### Example 1: Weighing Small Items

**Scenario**: Weighing coins, jewelry, or small electronic components

```bash
# 1. Start the application
swift run TrackpadWeight

# 2. Calibrate the scale (important!)
# Click menu bar icon → "Calibrate"

# 3. Place your finger on the trackpad to maintain electrical contact
# 4. Gently place the item on the trackpad next to your finger
# 5. Read the weight from the menu bar or main window
```

**Expected Results**:
- US Quarter (5.67g): Should read ~5.5-6.0g
- Paper clip (1g): Should read ~0.8-1.2g
- Small coin (2-3g): Should read ~2.0-3.5g

### Example 2: Food Portioning

**Scenario**: Measuring ingredients for cooking

```bash
# 1. Calibrate with empty trackpad
# 2. Place small bowl on trackpad (maintaining finger contact)
# 3. Note the bowl weight (e.g., 15g)
# 4. Add ingredient until desired weight is reached
# Example: For 5g of salt, add until total reads 20g
```

**Best Practice**: Use the "Tare" function between measurements

### Example 3: Mail and Package Weighing

**Scenario**: Checking if items meet shipping weight limits

```bash
# 1. Calibrate scale
# 2. Weigh envelope with documents
# 3. Check against postal weight limits:
#    - Standard letter: up to 28g
#    - Large letter: up to 100g
#    - Small packet: up to 500g
```

## Real-World Use Cases

### Jewelry and Precious Metals

**Use Case**: Estimating value of gold/silver items

```bash
# Example: Gold ring weighing
# 1. Calibrate scale
# 2. Weigh ring: 3.2g
# 3. Calculate value (assuming 14k gold @ $40/g):
#    3.2g × $40 = $128 estimated value
```

**Accuracy Note**: ±0.1-0.3g typical variance for items under 10g

### Electronics Components

**Use Case**: Sorting resistors, capacitors, or small parts

```bash
# Example: Identifying component types by weight
# Standard 1/4W resistor: ~0.3-0.4g
# Small capacitor: ~0.1-0.2g
# LED: ~0.05-0.1g
```

### Scientific/Educational Use

**Use Case**: Chemistry lab measurements

```bash
# Example: Measuring salt crystals
# 1. Calibrate scale
# 2. Use tweezers to place individual crystals
# 3. Record measurements for analysis
# Typical NaCl crystal: 0.01-0.05g
```

**Safety Warning**: Not suitable for hazardous materials or precise chemical work.

### Crafting and Hobbies

**Use Case**: Model building, jewelry making

```bash
# Example: Balancing model airplane components
# 1. Weigh wing sections individually
# 2. Calculate center of gravity
# 3. Add/remove material to achieve balance
```

## API Integration Examples

### REST API Usage

The built-in API server provides programmatic access to weight data.

#### Starting the API Server

```bash
# Enable API server from menu bar
# Menu Bar Icon → "API Server" → Enable
# Server runs on http://localhost:8080 by default
```

#### Basic API Calls

```bash
# Get current weight
curl http://localhost:8080/api/weight

# Response:
{
  "weight": 15.3,
  "unit": "grams",
  "timestamp": "2025-01-15T10:30:00Z",
  "calibrated": true
}

# Get weight history
curl http://localhost:8080/api/history?limit=10

# Calibrate scale remotely
curl -X POST http://localhost:8080/api/calibrate

# Set tare point
curl -X POST http://localhost:8080/api/tare \
  -H "Content-Type: application/json" \
  -d '{"name": "container"}'
```

#### Webhook Integration

```bash
# Configure webhook URL
# Menu Bar → API Settings → Configure Webhook
# URL: https://your-server.com/webhook

# Example webhook payload:
{
  "event": "weight_changed",
  "weight": 25.7,
  "timestamp": "2025-01-15T10:30:00Z",
  "session_id": "abc123"
}
```

#### Python Integration Example

```python
import requests
import time

API_BASE = "http://localhost:8080/api"

def monitor_weight(duration=60):
    """Monitor weight for specified duration."""
    start_time = time.time()
    weights = []
    
    while time.time() - start_time < duration:
        try:
            response = requests.get(f"{API_BASE}/weight")
            if response.status_code == 200:
                data = response.json()
                weights.append({
                    'weight': data['weight'],
                    'timestamp': data['timestamp']
                })
            time.sleep(0.5)  # Poll every 500ms
        except Exception as e:
            print(f"Error: {e}")
    
    return weights

# Usage
print("Monitoring weight for 30 seconds...")
weight_data = monitor_weight(30)
average_weight = sum(w['weight'] for w in weight_data) / len(weight_data)
print(f"Average weight: {average_weight:.2f}g")
```

## Advanced Features

### Auto-Tare Functionality

**Feature**: Automatically zero the scale when a new measurement session begins

```bash
# Enable auto-tare
# Menu Bar → "Auto-Tare" → Enable

# Configure sensitivity
# Menu Bar → "Auto-Tare Settings"
# - Timeout: 5 seconds (default)
# - Threshold: 0.5g change (default)
```

**Example Workflow**:
1. Place container on scale: 15g displayed
2. Lift finger for 5+ seconds
3. Replace finger: Scale automatically zeros
4. Add contents: Only contents weight shown

### Comparison Mode

**Feature**: Compare weights against reference values

```bash
# Enable comparison mode
# Menu Bar → "Comparison Mode" → Enable

# Set reference weight
# Menu Bar → "Comparison Tools" → "Set Reference Weight"
# Enter: Item="Gold Ring", Weight=3.5g

# During measurement:
# Display shows: "Current: 3.2g | Ref: 3.5g | Diff: -0.3g"
```

### Compact Widget

**Feature**: Always-on-top weight display

```bash
# Show compact widget
# Menu Bar → "Show Compact Widget"

# Configure position
# Menu Bar → "Widget Options" → "Position" → "Top Right"

# Configure size
# Menu Bar → "Widget Options" → "Size" → "Large"
```

**Widget Features**:
- Transparent background
- Customizable position
- Auto-hide when not in use
- Click-through option

### Data Logging and Export

**Feature**: Automatic logging of all weight measurements

```bash
# Enable logging
# Menu Bar → "Enable Logging"

# Export data
# Menu Bar → "Export Weight Log (CSV)"
# Saves to: ~/Documents/TrackpadWeight/weights_YYYY-MM-DD.csv

# CSV Format:
timestamp,weight,session_id,tare_point,notes
2025-01-15T10:30:00Z,15.3,session_001,0.0,""
2025-01-15T10:30:15Z,18.7,session_001,0.0,""
```

#### Analyze Data with Excel/Numbers

1. Import CSV file
2. Create charts showing weight over time
3. Calculate statistics (min, max, average, std dev)
4. Identify measurement patterns

## Troubleshooting Common Issues

### Issue: Erratic Readings

**Symptoms**: Weight jumps around, unstable readings

**Solutions**:
1. **Clean trackpad surface**
   ```bash
   # Use microfiber cloth with slight dampness
   # Ensure no oils or debris on surface
   ```

2. **Recalibrate frequently**
   ```bash
   # Calibrate every 10-15 measurements
   # Or when readings seem off
   ```

3. **Check finger contact**
   ```bash
   # Ensure consistent finger pressure
   # Avoid moving finger during measurement
   ```

### Issue: No Readings

**Symptoms**: Weight always shows 0.0g

**Solutions**:
1. **Verify Force Touch capability**
   ```bash
   # System Preferences → Trackpad → Force Click
   # Ensure Force Touch is enabled
   ```

2. **Check trackpad model compatibility**
   ```bash
   # Compatible models:
   # - MacBook Pro 2015 and later
   # - MacBook 2016-2017
   # - MacBook Air 2018 and later with Force Touch
   ```

3. **Reset calibration**
   ```bash
   # Menu Bar → Calibrate (multiple times)
   # Restart application
   ```

### Issue: Weight Limits Exceeded

**Symptoms**: Readings plateau or become unreliable above certain weights

**Solutions**:
1. **Check model-specific limits** (see COMPATIBILITY.md)
2. **Use multiple measurement points**
   ```bash
   # For items >100g, measure in parts
   # Add individual measurements
   ```

### Issue: API Server Won't Start

**Symptoms**: API endpoints not accessible

**Solutions**:
1. **Check port availability**
   ```bash
   lsof -i :8080  # Check if port is in use
   ```

2. **Try different port**
   ```bash
   # Menu Bar → API Settings → Configure Port
   # Try: 8081, 8082, etc.
   ```

3. **Check firewall settings**
   ```bash
   # System Preferences → Security & Privacy → Firewall
   # Allow TrackpadWeight through firewall
   ```

### Issue: Accuracy Problems

**Symptoms**: Readings don't match known weights

**Solutions**:
1. **Verify calibration items**
   ```bash
   # Use items with known, verified weights
   # US coins are good references:
   # - Penny: 2.5g
   # - Nickel: 5.0g
   # - Dime: 2.27g
   # - Quarter: 5.67g
   ```

2. **Environment factors**
   ```bash
   # Stable surface (avoid vibrations)
   # Consistent temperature
   # Minimal air currents
   ```

3. **Measurement technique**
   ```bash
   # Place items gently
   # Avoid sudden movements
   # Take multiple readings and average
   ```

---

## Performance Benchmarks

### Typical Accuracy by Weight Range

| Weight Range | Expected Accuracy | Use Cases |
|-------------|------------------|-----------|
| 0.1-1.0g    | ±0.05-0.1g      | Electronics, small jewelry |
| 1-10g       | ±0.1-0.2g       | Coins, medium jewelry |
| 10-50g      | ±0.2-0.5g       | Food portions, documents |
| 50-200g     | ±0.5-1.0g       | Packages, containers |
| 200g+       | ±1.0-2.0g       | Large items (approaching limits) |

### Response Time

- **Initial reading**: <1 second
- **Stable reading**: 2-3 seconds
- **API response**: <100ms
- **Calibration time**: 1-2 seconds

### Battery Impact

- **Continuous monitoring**: ~2-3% battery per hour
- **Periodic use**: <1% battery per hour
- **Sleep mode**: Negligible impact

---

*For more technical details, see [TECHNICAL.md](TECHNICAL.md)*
*For compatibility information, see [COMPATIBILITY.md](COMPATIBILITY.md)*